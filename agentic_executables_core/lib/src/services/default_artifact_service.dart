import 'dart:io';

import 'package:crypto/crypto.dart';

import '../adapters/heuristic_extractor_registry.dart';
import '../adapters/process_runner_io.dart';
import '../models/artifact_matrix.dart';
import '../models/artifact_pack.dart';
import '../models/feature_id.dart';
import '../models/verify_report.dart';
import '../ports/process_runner.dart';
import '../ports/artifact_store.dart';
import '../ports/canonical_store.dart';
import 'artifact_service.dart';

class DefaultArtifactService implements ArtifactService {
  DefaultArtifactService({
    required this.artifactStore,
    required this.canonicalStore,
    required this.extractorRegistry,
    ProcessRunner? processRunner,
  }) : _processRunner = processRunner ?? ProcessRunnerIo();

  final ArtifactStore artifactStore;
  final CanonicalStore canonicalStore;
  final HeuristicExtractorRegistry extractorRegistry;
  final ProcessRunner _processRunner;

  @override
  Future<List<String>> list() => artifactStore.list();

  @override
  Future<ArtifactPack?> load(final String name) => artifactStore.load(name);

  @override
  Future<bool> remove(final String name) => artifactStore.remove(name);

  @override
  Future<String> ingest(final Directory sourceDir) async {
    final extractor = await extractorRegistry.findFor(sourceDir);
    final artifact = await extractor.extract(sourceDir);
    final pack = artifact.toArtifactPack();
    await artifactStore.save(pack);
    return pack.name;
  }

  @override
  Future<bool> sync(final String packName) async {
    final outcome = await syncOne(packName);
    return outcome.changed;
  }

  @override
  Future<SyncOutcome> syncOne(
    final String packName, {
    final bool prune = false,
  }) async {
    final pack = await artifactStore.load(packName);
    if (pack == null) {
      throw ArgumentError('Unknown artifact: $packName');
    }
    final basePath = pack.meta.source.path;
    if (basePath == null) {
      throw StateError('Cannot sync $packName: source.path is null');
    }
    if (prune) {
      final sourceDir = Directory(basePath);
      if (!await sourceDir.exists()) {
        await artifactStore.remove(packName);
        return const SyncOutcome(changed: false, pruned: true);
      }
    }
    final newFiles = <ArtifactSourceFile>[];
    var changed = false;
    for (final entry in pack.meta.source.files) {
      final file = File('$basePath/${entry.path}');
      if (!await file.exists()) {
        // Drop missing files; mark changed.
        changed = true;
        continue;
      }
      final bytes = await file.readAsBytes();
      final newHash = sha256.convert(bytes).toString();
      if (newHash != entry.sha256) changed = true;
      newFiles.add(ArtifactSourceFile(path: entry.path, sha256: newHash));
    }
    if (changed) {
      final updated = ArtifactPack(
        name: pack.name,
        meta: ArtifactMeta(
          kind: pack.meta.kind,
          title: pack.meta.title,
          source: ArtifactSource(
            type: pack.meta.source.type,
            path: pack.meta.source.path,
            url: pack.meta.source.url,
            files: newFiles,
          ),
          scannedAt: DateTime.now().toUtc(),
          license: pack.meta.license,
          authors: pack.meta.authors,
          referencesCanonical: pack.meta.referencesCanonical,
          extractor: pack.meta.extractor,
          distill: pack.meta.distill,
        ),
        indexContent: pack.indexContent,
        matrix: pack.matrix,
        patternsContent: pack.patternsContent,
        requires: pack.requires,
      );
      await artifactStore.save(updated);
    }
    return SyncOutcome(changed: changed, pruned: false);
  }

  @override
  Future<void> link(
    final String packName,
    final String conceptId, {
    final int? lockedVersion,
  }) async {
    final pack = await artifactStore.load(packName);
    if (pack == null) {
      throw ArgumentError('Unknown artifact: $packName');
    }
    final ref = CanonicalReference.parse(
      lockedVersion == null ? conceptId : '$conceptId@v$lockedVersion',
    );
    // De-dup by toString() — replace if same conceptId@version, else append.
    final list = List<CanonicalReference>.from(pack.meta.referencesCanonical);
    final existingIndex = list.indexWhere(
      (final r) => r.conceptId == ref.conceptId,
    );
    if (existingIndex >= 0) {
      list[existingIndex] = ref;
    } else {
      list.add(ref);
    }
    await _saveWithUpdatedMeta(pack, referencesCanonical: list);
  }

  @override
  Future<void> upgradeCanonical(
    final String packName,
    final String conceptId, {
    required final int toVersion,
  }) async {
    await link(packName, conceptId, lockedVersion: toVersion);
  }

  @override
  Future<int> materialize(final String packName) async {
    final pack = await artifactStore.load(packName);
    if (pack == null) {
      throw ArgumentError('Unknown artifact: $packName');
    }
    final existingIds =
        pack.matrix.features.map((final f) => f.id.toString()).toSet();
    final newRows = <ArtifactFeatureRow>[];
    for (final ref in pack.meta.referencesCanonical) {
      final canonicalPack = await canonicalStore.load(
        ref.conceptId,
        lockedVersion: ref.lockedVersion,
      );
      if (canonicalPack == null) continue;
      for (final feature in canonicalPack.matrix.features) {
        if (existingIds.contains(feature.id.toString())) continue;
        newRows.add(ArtifactFeatureRow(
          id: feature.id,
          canonical: ref.conceptId,
          cell: const ArtifactCell(impl: ImplStatus.missing),
        ));
        existingIds.add(feature.id.toString());
      }
    }
    if (newRows.isEmpty) return 0;
    final mergedFeatures = [
      ...pack.matrix.features,
      ...newRows,
    ];
    final updated = ArtifactPack(
      name: pack.name,
      meta: pack.meta,
      indexContent: pack.indexContent,
      matrix: ArtifactMatrix(
        columnSchema: pack.matrix.columnSchema,
        features: mergedFeatures,
      ),
      patternsContent: pack.patternsContent,
      requires: pack.requires,
    );
    await artifactStore.save(updated);
    return newRows.length;
  }

  @override
  Future<VerifyReport> verifyOne(
    final String packName, {
    final bool runTests = false,
  }) async {
    final pack = await artifactStore.load(packName);
    if (pack == null) {
      throw ArgumentError('Unknown artifact: $packName');
    }
    final entries = <VerifyEntry>[];

    final byFeatureId = <String, ArtifactFeatureRow>{
      for (final r in pack.matrix.features) r.id.toString(): r,
    };
    final referencedConcepts =
        pack.meta.referencesCanonical.map((final r) => r.conceptId).toSet();

    // Per referenced canonical: walk features.
    for (final ref in pack.meta.referencesCanonical) {
      final canonical = await canonicalStore.load(
        ref.conceptId,
        lockedVersion: ref.lockedVersion,
      );
      if (canonical == null) continue;
      for (final feature in canonical.matrix.features) {
        final row = byFeatureId[feature.id.toString()];
        final invariant = feature.cells['invariant'];
        // Tier 1: invariant declared, no row OR row.tests != yes.
        if (invariant != null && invariant.isNotEmpty) {
          final hasYes = row != null && row.cell.tests == TestStatus.yes;
          var verified = hasYes;
          String? evidenceFailure;
          if (hasYes && runTests) {
            final cmd = row!.cell.evidenceCommand;
            if (cmd == null || cmd.isEmpty) {
              // Claimed without provenance: trust the cell (legacy rows).
              verified = true;
            } else {
              final result = await _processRunner.run(
                executable: 'bash',
                arguments: ['-c', cmd],
                workingDirectory: pack.meta.source.path,
                timeout: const Duration(seconds: 120),
              );
              verified = result.exitCode == 0;
              if (!verified) {
                evidenceFailure =
                    "evidence failed: '$cmd' exited ${result.exitCode}";
              }
            }
          }
          if (!verified) {
            entries.add(VerifyEntry(
              tier: VerifyTier.invariantViolation,
              artifact: pack.name,
              canonical: ref.conceptId,
              featureId: feature.id,
              message: evidenceFailure ?? 'invariant unverified: $invariant',
            ));
            continue;
          }
        }
        // Tier 3: row exists with status partial.
        if (row != null && row.cell.impl == ImplStatus.partial) {
          entries.add(VerifyEntry(
            tier: VerifyTier.partialFeature,
            artifact: pack.name,
            canonical: ref.conceptId,
            featureId: feature.id,
            message: 'partial implementation',
          ));
        }
      }
    }

    // Tier 4: canonicals in hub but not referenced.
    final allCanonicals = await canonicalStore.list();
    for (final concept in allCanonicals) {
      if (referencedConcepts.contains(concept)) continue;
      entries.add(VerifyEntry(
        tier: VerifyTier.unreferencedCanonical,
        artifact: pack.name,
        canonical: concept,
        featureId: null,
        message: 'canonical present in hub but not referenced',
      ));
    }

    return VerifyReport(entries: entries);
  }

  @override
  Future<MarkEvidenceResult> markEvidence(
    final String packName,
    final String featureId, {
    required final String testCommand,
    final String? location,
    final String? notes,
    final TestStatus tests = TestStatus.yes,
    final ImplStatus impl = ImplStatus.done,
  }) async {
    final pack = await artifactStore.load(packName);
    if (pack == null) {
      throw ArgumentError('Unknown artifact: $packName');
    }
    FeatureId.parse(featureId); // validate shape early
    final index = pack.matrix.features
        .indexWhere((final r) => r.id.toString() == featureId);
    if (index == -1) {
      throw ArgumentError('Feature $featureId not found in pack $packName. '
          'Link a canonical containing it first (ae artifact link).');
    }

    final old = pack.matrix.features[index].cell;
    final updated = ArtifactCell(
      impl: old.impl == ImplStatus.missing ? impl : old.impl,
      algorithm: old.algorithm,
      location: location ?? old.location,
      tests: tests,
      notes: notes ?? old.notes,
      evidenceCommand: testCommand,
    );
    final rows = List<ArtifactFeatureRow>.from(pack.matrix.features)
      ..[index] = ArtifactFeatureRow(
        id: pack.matrix.features[index].id,
        canonical: pack.matrix.features[index].canonical,
        cell: updated,
      );
    await artifactStore.save(
      ArtifactPack(
        name: pack.name,
        meta: pack.meta,
        indexContent: pack.indexContent,
        matrix: ArtifactMatrix(
          columnSchema: pack.matrix.columnSchema,
          features: rows,
        ),
        patternsContent: pack.patternsContent,
        requires: pack.requires,
      ),
    );
    return MarkEvidenceResult(
      pack: packName,
      featureId: featureId,
      cell: updated,
    );
  }

  @override
  Future<VerifyReport> verifyProject() async {
    final names = await artifactStore.list();
    final entries = <VerifyEntry>[];

    // Build downstream-demand map: (upstream_artifact, feature_id) -> count.
    final demand = <String, int>{};
    final demandFeatureCanonical = <String, String>{};
    for (final downstream in names) {
      final pack = await artifactStore.load(downstream);
      if (pack?.requires == null) continue;
      for (final entry in pack!.requires!.entries) {
        final ids = entry.featuresAll
            ? <String>[]
            : entry.features.map((final f) => f.toString()).toList();
        for (final id in ids) {
          final key = '${entry.artifact}::$id';
          demand[key] = (demand[key] ?? 0) + 1;
          demandFeatureCanonical[key] = entry.canonical;
        }
      }
    }

    // For each upstream artifact, emit Tier 2 entries for missing/partial
    // features that downstream demands.
    for (final upstream in names) {
      final pack = await artifactStore.load(upstream);
      if (pack == null) continue;
      final byId = {
        for (final r in pack.matrix.features) r.id.toString(): r,
      };
      for (final demandEntry in demand.entries) {
        final parts = demandEntry.key.split('::');
        final upstreamName = parts[0];
        final featureIdStr = parts[1];
        if (upstreamName != upstream) continue;
        final row = byId[featureIdStr];
        final blocking = row == null ||
            row.cell.impl == ImplStatus.missing ||
            row.cell.impl == ImplStatus.partial;
        if (blocking) {
          entries.add(VerifyEntry(
            tier: VerifyTier.upstreamBlocker,
            artifact: upstreamName,
            canonical: demandFeatureCanonical[demandEntry.key] ?? '',
            featureId: FeatureId.parse(featureIdStr),
            message: row == null
                ? 'feature absent from upstream'
                : 'upstream impl is ${row.cell.impl.value}',
            downstreamCount: demandEntry.value,
          ));
        }
      }
    }

    // Sort Tier 2 entries by downstream count descending.
    entries.sort((final a, final b) {
      if (a.tier != b.tier) return a.tier.tier.compareTo(b.tier.tier);
      final ad = a.downstreamCount ?? 0;
      final bd = b.downstreamCount ?? 0;
      return bd.compareTo(ad);
    });

    return VerifyReport(entries: entries);
  }

  Future<void> _saveWithUpdatedMeta(
    final ArtifactPack pack, {
    final List<CanonicalReference>? referencesCanonical,
  }) async {
    final updated = ArtifactPack(
      name: pack.name,
      meta: ArtifactMeta(
        kind: pack.meta.kind,
        title: pack.meta.title,
        source: pack.meta.source,
        scannedAt: pack.meta.scannedAt,
        license: pack.meta.license,
        authors: pack.meta.authors,
        referencesCanonical:
            referencesCanonical ?? pack.meta.referencesCanonical,
        extractor: pack.meta.extractor,
        distill: pack.meta.distill,
      ),
      indexContent: pack.indexContent,
      matrix: pack.matrix,
      patternsContent: pack.patternsContent,
      requires: pack.requires,
    );
    await artifactStore.save(updated);
  }
}
