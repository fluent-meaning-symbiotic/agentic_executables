import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import '../config/ae_core_config.dart';
import '../models/canonical_matrix.dart';
import '../models/canonical_pack.dart';
import '../models/distillation_task.dart';
import '../models/feature_id.dart';
import '../ports/artifact_store.dart';
import '../ports/canonical_store.dart';
import 'canonical_service.dart';

class DefaultCanonicalService implements CanonicalService {
  const DefaultCanonicalService({required this.store});

  final CanonicalStore store;

  @override
  Future<List<String>> list() => store.list();

  @override
  Future<CanonicalPack?> load(
    final String conceptId, {
    final int? lockedVersion,
  }) =>
      store.load(conceptId, lockedVersion: lockedVersion);

  @override
  Future<CanonicalPack> scaffold(
    final String conceptId, {
    required final String title,
    final String indexContent = '',
  }) async {
    final pack = CanonicalPack(
      meta: CanonicalMeta(
        concept: conceptId,
        version: 1,
        title: title,
        license: const CanonicalLicense(
          spdx: 'CC-BY-4.0',
          url: 'https://creativecommons.org/licenses/by/4.0/',
        ),
        authors: const [],
        sources: const [],
        provenance: CanonicalProvenance(
          authored: CanonicalAuthored.hand,
          authoredAt: DateTime.now().toUtc(),
        ),
      ),
      indexContent: indexContent.isEmpty
          ? '# $title\n\nDescribe the concept here.\n'
          : indexContent,
      matrix: CanonicalMatrix(
        concept: conceptId,
        version: 1,
        columnSchema: const [
          CanonicalColumn(id: 'spec', type: 'text'),
          CanonicalColumn(id: 'invariant', type: 'text'),
        ],
        features: const [],
      ),
    );
    await store.save(conceptId, pack);
    return pack;
  }

  @override
  Future<CanonicalPack> scaffoldFromArtifact(
    final String conceptId, {
    required final String title,
    required final List<String> artifactNames,
    required final ArtifactStore artifactStore,
    final bool overwrite = false,
  }) async {
    if (!overwrite) {
      final existing = await store.load(conceptId);
      if (existing != null) {
        throw StateError(
          'canonical_exists: $conceptId already exists; pass overwrite=true '
          'to replace.',
        );
      }
    }

    // Collect candidates across artifacts. Dedup by feature id (first wins).
    final byId = <String, CanonicalFeature>{};
    final missingArtifacts = <String>[];
    for (final name in artifactNames) {
      final art = await artifactStore.load(name);
      if (art == null) {
        missingArtifacts.add(name);
        continue;
      }
      for (final sym in _parsePublicApi(art.indexContent)) {
        final id = _featureIdFor(name, sym.symbol);
        if (id == null) continue;
        if (byId.containsKey(id)) continue;
        byId[id] = CanonicalFeature(
          id: FeatureId.parse(id),
          cells: {
            'spec': '${sym.symbol} (${sym.kind}) — fill in the spec here.',
            'invariant': '',
          },
        );
      }
    }
    if (missingArtifacts.isNotEmpty) {
      throw ArgumentError(
        'artifact_not_found: ${missingArtifacts.join(', ')}',
      );
    }

    final features = byId.values.toList(growable: false);
    final pack = CanonicalPack(
      meta: CanonicalMeta(
        concept: conceptId,
        version: 1,
        title: title,
        license: const CanonicalLicense(
          spdx: 'CC-BY-4.0',
          url: 'https://creativecommons.org/licenses/by/4.0/',
        ),
        authors: const [],
        sources: const [],
        provenance: CanonicalProvenance(
          authored: CanonicalAuthored.scaffolded,
          authoredAt: DateTime.now().toUtc(),
        ),
      ),
      indexContent: '# $title\n\n'
          'Heuristic scaffold seeded from: ${artifactNames.join(', ')}.\n\n'
          'Edit specs and invariants by hand, or run `ae canonical distill`\n'
          'against an artifact for an LLM-assisted enrichment pass.\n',
      matrix: CanonicalMatrix(
        concept: conceptId,
        version: 1,
        columnSchema: const [
          CanonicalColumn(id: 'spec', type: 'text'),
          CanonicalColumn(id: 'invariant', type: 'text'),
        ],
        features: features,
      ),
    );
    await store.save(conceptId, pack);
    return pack;
  }

  /// Parses `## Public API` bullets emitted by the heuristic extractors.
  /// Each line looks like `- ``name`` (kind) — headline [file]` (or, when
  /// no headline, the headline + dash are omitted). Tolerates trailing
  /// whitespace and missing `[file]` markers.
  static final RegExp _publicApiHeader = RegExp(
    r'^##\s+Public\s+API\s*$',
    multiLine: true,
  );
  static final RegExp _bullet = RegExp(
    r'^-\s+`([^`]+)`\s*\(([^)]+)\)',
  );

  List<_ScaffoldSymbol> _parsePublicApi(final String indexMd) {
    final start = _publicApiHeader.firstMatch(indexMd);
    if (start == null) return const [];
    final tail = indexMd.substring(start.end);
    final out = <_ScaffoldSymbol>[];
    for (final line in tail.split('\n')) {
      final trimmed = line.trimRight();
      if (trimmed.isEmpty) continue;
      // Stop at the next heading.
      if (trimmed.startsWith('## ')) break;
      final m = _bullet.firstMatch(trimmed);
      if (m == null) continue;
      out.add(_ScaffoldSymbol(symbol: m.group(1)!, kind: m.group(2)!.trim()));
    }
    return out;
  }

  String? _featureIdFor(final String artifactName, final String symbol) {
    final left = _sanitizeSegment(artifactName);
    final right = _sanitizeSegment(symbol);
    if (left.isEmpty || right.isEmpty) return null;
    return '$left.$right';
  }

  /// Sanitize a raw symbol/pack name to a single FeatureId segment.
  /// Pipeline:
  ///   1. Insert an underscore at every camelCase boundary
  ///      (`AeCli` → `Ae_Cli`, `runCli` → `run_Cli`, `kAeVersion`
  ///      → `k_Ae_Version`).
  ///   2. Lower-case the result.
  ///   3. Replace any run of non-`[a-z0-9_]` characters with a single `_`.
  ///   4. Strip leading digits/underscores (FeatureId requires an alpha
  ///      first character).
  ///   5. Collapse repeated underscores; trim trailing underscores.
  String _sanitizeSegment(final String raw) {
    if (raw.isEmpty) return '';
    final withSplits = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      final c = raw[i];
      final cu = c.codeUnitAt(0);
      final isUpper = cu >= 0x41 && cu <= 0x5a;
      if (isUpper && i > 0) {
        final prevCu = raw.codeUnitAt(i - 1);
        final prevIsLower = prevCu >= 0x61 && prevCu <= 0x7a;
        final prevIsDigit = prevCu >= 0x30 && prevCu <= 0x39;
        final prevIsUpper = prevCu >= 0x41 && prevCu <= 0x5a;
        final nextCu = i + 1 < raw.length ? raw.codeUnitAt(i + 1) : 0;
        final nextIsLower = nextCu >= 0x61 && nextCu <= 0x7a;
        // Boundaries: lower→Upper, digit→Upper, Upper→Upper-then-lower
        // (so HTTPServer → HTTP_Server, not H_T_T_P_Server).
        if (prevIsLower || prevIsDigit || (prevIsUpper && nextIsLower)) {
          withSplits.write('_');
        }
      }
      withSplits.write(c);
    }
    final lower = withSplits.toString().toLowerCase();
    final buf = StringBuffer();
    var lastUnderscore = false;
    for (final cu in lower.codeUnits) {
      final isAlpha = (cu >= 0x61 && cu <= 0x7a);
      final isDigit = (cu >= 0x30 && cu <= 0x39);
      final isUnderscore = cu == 0x5f;
      if (isAlpha || isDigit || isUnderscore) {
        if (buf.isEmpty && (isDigit || isUnderscore)) {
          continue;
        }
        if (isUnderscore) {
          if (lastUnderscore) continue;
          lastUnderscore = true;
        } else {
          lastUnderscore = false;
        }
        buf.writeCharCode(cu);
      } else {
        if (buf.isEmpty || lastUnderscore) continue;
        buf.write('_');
        lastUnderscore = true;
      }
    }
    var result = buf.toString();
    while (result.endsWith('_')) {
      result = result.substring(0, result.length - 1);
    }
    return result;
  }

  @override
  Future<void> upsert(final String conceptId, final CanonicalPack pack) =>
      store.save(conceptId, pack).then((final _) {});

  @override
  Future<ScaffoldUpdateReport> scaffoldUpdate(
    final String conceptId, {
    required final List<String> artifactNames,
    required final ArtifactStore artifactStore,
    final List<List<String>> renames = const [],
  }) async {
    final existing = await store.load(conceptId);
    if (existing == null) {
      throw StateError(
        'canonical_not_found: $conceptId — run `ae canonical scaffold` '
        'or `ae canonical init` first',
      );
    }

    // Collect current source symbols, keyed by their canonical feature id.
    // Keep the symbol/kind so new rows can reuse scaffoldFromArtifact's seed
    // text format (`<symbol> (<kind>) — fill in the spec here.`).
    final sourceSyms = <String, _ScaffoldSymbol>{};
    final missingArtifacts = <String>[];
    for (final name in artifactNames) {
      final art = await artifactStore.load(name);
      if (art == null) {
        missingArtifacts.add(name);
        continue;
      }
      for (final sym in _parsePublicApi(art.indexContent)) {
        final id = _featureIdFor(name, sym.symbol);
        if (id == null) continue;
        sourceSyms.putIfAbsent(id, () => sym);
      }
    }
    if (missingArtifacts.isNotEmpty) {
      throw ArgumentError(
        'artifact_not_found: ${missingArtifacts.join(', ')}',
      );
    }
    final sourceIds = sourceSyms.keys.toSet();

    // Index the existing matrix.
    final byId = <String, CanonicalFeature>{
      for (final f in existing.matrix.features) f.id.toString(): f,
    };

    // Rename handling. Strict-by-default: each pair is operator-confirmed.
    // Validates old exists / new doesn't, then migrates the row's text and
    // leaves a `removed: true` tombstone at old with `renamed_to: <new>`.
    final renamedReport = <List<String>>[];
    for (final pair in renames) {
      if (pair.length != 2) {
        throw ArgumentError(
          'rename_malformed: expected [old, new], got $pair',
        );
      }
      final oldId = pair[0];
      final newId = pair[1];
      final oldFeature = byId[oldId];
      if (oldFeature == null) {
        throw ArgumentError(
          'rename_missing: $oldId is not in the matrix for $conceptId',
        );
      }
      if (byId.containsKey(newId)) {
        throw ArgumentError(
          'rename_collision: $newId already exists in the matrix for '
          '$conceptId',
        );
      }
      // Migrate text under the new id. Always activates the new row
      // (`removed: false`) — even if the operator is renaming a row
      // that was previously tombstoned, the rename's purpose is to
      // give the live concept a new id under the matrix.
      byId[newId] = CanonicalFeature(
        id: FeatureId.parse(newId),
        cells: Map<String, String>.from(oldFeature.cells),
        removed: false,
      );
      // Tombstone at the old id with renamed_to pointer.
      byId[oldId] = CanonicalFeature(
        id: oldFeature.id,
        cells: {
          ...oldFeature.cells,
          'renamed_to': newId,
        },
        removed: true,
      );
      renamedReport.add([oldId, newId]);
    }

    // Build a quick lookup of newly-renamed target ids so the removed loop
    // doesn't tombstone them when the source artifact hasn't yet been
    // updated to expose the new name (e.g. operator renames first, then
    // updates source). Without this, --rename old=new where source still
    // has `old` would migrate text to `new` and immediately tombstone it.
    final renamedTargets = {for (final pair in renamedReport) pair[1]};

    final added = <String>[];
    for (final id in sourceIds) {
      if (byId.containsKey(id)) continue;
      // Mirror scaffoldFromArtifact's seed text so an operator can't tell
      // a row came from --update vs. from initial scaffold.
      final sym = sourceSyms[id]!;
      final feature = CanonicalFeature(
        id: FeatureId.parse(id),
        cells: {
          'spec': '${sym.symbol} (${sym.kind}) — fill in the spec here.',
          'invariant': '',
        },
      );
      byId[id] = feature;
      added.add(id);
    }

    final removed = <String>[];
    for (final entry in byId.entries.toList()) {
      final id = entry.key;
      final feature = entry.value;
      if (sourceIds.contains(id)) continue;
      if (feature.removed) continue; // already marked, idempotent
      // Accepted-concept rows are deliberately not symbol-derived; never
      // tombstone them via --update. Operator removes them manually if
      // they want to retire one. (Bug caught in plan-review: without this,
      // every --update would mark accept-concept rows removed:true.)
      if (feature.cells['provenance'] == acceptedConceptProvenance) continue;
      // Don't tombstone a freshly-migrated rename target — `--rename`
      // followed by an artifact that doesn't yet expose <new> would
      // erase the migration in the same pass.
      if (renamedTargets.contains(id)) continue;
      // Mark as removed; preserve text.
      byId[id] = CanonicalFeature(
        id: feature.id,
        cells: feature.cells,
        removed: true,
      );
      removed.add(id);
    }

    final unchanged =
        byId.length - added.length - removed.length - renamedReport.length * 2;

    final mergedFeatures = byId.values.toList(growable: false);
    final mergedMatrix = CanonicalMatrix(
      concept: existing.matrix.concept,
      version: existing.matrix.version,
      columnSchema: existing.matrix.columnSchema,
      features: mergedFeatures,
    );
    final updated = CanonicalPack(
      meta: existing.meta,
      indexContent: existing.indexContent,
      matrix: mergedMatrix,
      changelogContent: existing.changelogContent,
    );
    await store.save(conceptId, updated);

    added.sort();
    removed.sort();
    return ScaffoldUpdateReport(
      added: added,
      removed: removed,
      renamed: renamedReport,
      unchanged: unchanged,
    );
  }

  @override
  Future<CanonicalPack> mergeDistillation(
    final String conceptId,
    final DistillationOutput output,
  ) async {
    final result = await mergeDistillationDetailed(conceptId, output);
    return result.pack;
  }

  @override
  Future<CanonicalMergeResult> mergeDistillationDetailed(
    final String conceptId,
    final DistillationOutput output,
  ) async {
    // Detect duplicate ids in the raw distillation output. We track the order
    // of first appearance so warnings are stable across runs. last-write-wins
    // applies regardless — this just makes the collapse visible.
    final outputIdCounts = <String, int>{};
    for (final f in output.matrix.features) {
      final id = f.id.toString();
      outputIdCounts[id] = (outputIdCounts[id] ?? 0) + 1;
    }
    final duplicateIds = <String>[
      for (final entry in outputIdCounts.entries)
        if (entry.value > 1) entry.key,
    ];

    final existing = await store.load(conceptId);

    // Id-stability guard: every feature row in the distill output must have
    // an id that is already present in the pre-distill matrix. New cross-
    // cutting features arrive via output.proposedConcepts instead. Runs
    // unconditionally — when no canonical exists yet, knownIds is empty and
    // any non-empty output.matrix.features is rejected (forces scaffold-or-
    // init first). See specs/2026-04-27-canonical-id-stability-design.md Q7
    // and Q12 for the empty-matrix-bypass closure (M2).
    final knownIds = <String>{
      if (existing != null)
        for (final f in existing.matrix.features) f.id.toString(),
    };
    final unknownIds = <String>[
      for (final f in output.matrix.features)
        if (!knownIds.contains(f.id.toString())) f.id.toString(),
    ];
    if (unknownIds.isNotEmpty) {
      throw IdNotInMatrixException(
        conceptId: conceptId,
        unknownIds: unknownIds,
        knownIdCount: knownIds.length,
      );
    }

    if (existing == null) {
      // Create new pack from distilled output. Even on the first write we
      // dedup the matrix so disk reflects what `byId` would have produced.
      final byId = <String, CanonicalFeature>{
        for (final f in output.matrix.features) f.id.toString(): f,
      };
      final dedupedFeatures = byId.values.toList(growable: false);
      final dedupedMatrix = CanonicalMatrix(
        concept: output.matrix.concept,
        version: output.matrix.version,
        columnSchema:
            _widenColumnSchema(output.matrix.columnSchema, dedupedFeatures),
        features: dedupedFeatures,
      );
      final pack = CanonicalPack(
        meta: CanonicalMeta(
          concept: conceptId,
          version: output.conceptVersion,
          title: conceptId,
          license: const CanonicalLicense(
            spdx: 'CC-BY-4.0',
            url: 'https://creativecommons.org/licenses/by/4.0/',
          ),
          authors: const [],
          sources: const [],
          provenance: CanonicalProvenance(
            authored: CanonicalAuthored.distilledFromArtifact,
            authoredAt: DateTime.now().toUtc(),
          ),
        ),
        indexContent: output.indexMd,
        matrix: dedupedMatrix,
      );
      await store.save(conceptId, pack);
      return CanonicalMergeResult(
        pack: pack,
        featureCountReceived: output.matrix.features.length,
        featureCountAfterMerge: dedupedMatrix.features.length,
        duplicateIds: duplicateIds,
        proposedConcepts: output.proposedConcepts,
      );
    }

    // Merge: union by feature id; new wins on conflict.
    final byId = <String, CanonicalFeature>{
      for (final f in existing.matrix.features) f.id.toString(): f,
    };
    for (final f in output.matrix.features) {
      byId[f.id.toString()] = f;
    }
    final mergedFeatures = byId.values.toList(growable: false);
    final baseSchema = existing.matrix.columnSchema.isNotEmpty
        ? existing.matrix.columnSchema
        : output.matrix.columnSchema;
    final mergedSchema = _widenColumnSchema(baseSchema, mergedFeatures);
    final mergedMatrix = CanonicalMatrix(
      concept: conceptId,
      version: existing.meta.version,
      columnSchema: mergedSchema,
      features: mergedFeatures,
    );
    final merged = CanonicalPack(
      meta: existing.meta,
      indexContent:
          output.indexMd.isNotEmpty ? output.indexMd : existing.indexContent,
      matrix: mergedMatrix,
      changelogContent: existing.changelogContent,
    );
    await store.save(conceptId, merged);
    return CanonicalMergeResult(
      pack: merged,
      featureCountReceived: output.matrix.features.length,
      featureCountAfterMerge: mergedMatrix.features.length,
      duplicateIds: duplicateIds,
      proposedConcepts: output.proposedConcepts,
    );
  }

  @override
  Future<String> snapshot(final String conceptId) => store.snapshot(conceptId);

  @override
  Future<CanonicalDiff> diff(
    final String conceptId, {
    required final int? fromVersion,
    required final int? toVersion,
  }) async {
    final from = await store.load(conceptId, lockedVersion: fromVersion);
    final to = await store.load(conceptId, lockedVersion: toVersion);
    final fromIds = from == null
        ? <String>{}
        : from.matrix.features.map((final f) => f.id.toString()).toSet();
    final toIds = to == null
        ? <String>{}
        : to.matrix.features.map((final f) => f.id.toString()).toSet();
    final added = toIds.difference(fromIds).toList()..sort();
    final removed = fromIds.difference(toIds).toList()..sort();
    final common = fromIds.intersection(toIds);
    final changed = <String>[];
    if (from != null && to != null) {
      final fromMap = {
        for (final f in from.matrix.features) f.id.toString(): f.cells,
      };
      final toMap = {
        for (final f in to.matrix.features) f.id.toString(): f.cells,
      };
      for (final id in common) {
        if (!_mapsEqual(fromMap[id]!, toMap[id]!)) changed.add(id);
      }
      changed.sort();
    }
    return CanonicalDiff(
      addedFeatures: added,
      removedFeatures: removed,
      changedFeatures: changed,
    );
  }

  /// Widens [base] with any column ids observed in [features] but not yet
  /// declared. Newly observed columns are appended in stable, deterministic
  /// order (first-seen across features) with type `text`. Preserves the
  /// existing column order and types.
  ///
  /// Resolves Iter 0 bug 5: scaffolds wrote `column_schema=[spec, invariant]`
  /// while distill output carried features with extra columns (e.g.
  /// `invocation`, `notes`). The merge silently kept the narrow schema,
  /// leaving matrix.yaml out-of-spec against itself.
  List<CanonicalColumn> _widenColumnSchema(
    final List<CanonicalColumn> base,
    final List<CanonicalFeature> features,
  ) {
    final declaredIds = {for (final c in base) c.id};
    final extras = <String>[];
    final seen = <String>{};
    for (final f in features) {
      for (final key in f.cells.keys) {
        if (declaredIds.contains(key)) continue;
        if (seen.add(key)) extras.add(key);
      }
    }
    if (extras.isEmpty) return base;
    return [
      ...base,
      for (final id in extras) CanonicalColumn(id: id, type: 'text'),
    ];
  }

  bool _mapsEqual(
    final Map<String, String> a,
    final Map<String, String> b,
  ) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (a[key] != b[key]) return false;
    }
    return true;
  }

  @override
  Future<void> writeProposalsFile(
    final String conceptId, {
    required final List<ProposedConcept> proposals,
    required final String executorUsed,
    final DateTime? producedAt,
  }) async {
    // Resolve the concept dir via the store's canonical layout. We delegate
    // path computation to the store rather than reconstructing it here so a
    // future store impl that uses a different layout still works.
    final dirPath = await store.conceptDirectoryPath(conceptId);
    final file = File(p.join(dirPath, '.last_proposals.json'));
    if (proposals.isEmpty) {
      if (await file.exists()) await file.delete();
      return;
    }
    // [producedAt] is optional so callers that re-write the file after a
    // partial accept (B4) can preserve the timestamp of the original distill
    // run. Defaults to now() for the distill-end caller.
    final timestamp = (producedAt ?? DateTime.now().toUtc()).toIso8601String();
    final payload = {
      'schema': 'ae.proposed_concepts.v1',
      'concept': conceptId,
      'produced_at': timestamp,
      'executor_used': executorUsed,
      'proposals': [for (final pc in proposals) pc.toJson()],
    };
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
    );
  }

  @override
  Future<AcceptConceptResult> acceptConcept(
    final String conceptId, {
    required final String newId,
    required final String fromProposal,
  }) async {
    final existing = await store.load(conceptId);
    if (existing == null) {
      throw StateError(
        'canonical_not_found: $conceptId — run `ae canonical scaffold` or '
        '`ae canonical init` first',
      );
    }

    final byId = {
      for (final f in existing.matrix.features) f.id.toString(): f,
    };
    final colliding = byId[newId];
    if (colliding != null) {
      throw IdCollisionException(
        conceptId: conceptId,
        collidingId: newId,
        isTombstone: colliding.removed,
      );
    }

    // Validate id shape before touching proposals so malformed ids fail
    // with a clean validation error, not a confusing proposal_not_found.
    FeatureId.parse(newId);

    final dirPath = await store.conceptDirectoryPath(conceptId);
    final file = File(p.join(dirPath, '.last_proposals.json'));
    if (!await file.exists()) {
      throw ProposalNotFoundException(
        conceptId: conceptId,
        proposalName: fromProposal,
        reason: 'no .last_proposals.json — run `ae canonical distill` first',
      );
    }
    final payload =
        jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    final proposalsRaw = (payload['proposals'] as List?) ?? const [];
    final proposalMap = <String, ProposedConcept>{};
    for (final raw in proposalsRaw) {
      if (raw is Map) {
        final pc = ProposedConcept.fromMap(raw);
        proposalMap[pc.name] = pc;
      }
    }
    final proposal = proposalMap[fromProposal];
    if (proposal == null) {
      throw ProposalNotFoundException(
        conceptId: conceptId,
        proposalName: fromProposal,
        reason: 'name not in .last_proposals.json '
            '(available: ${proposalMap.keys.join(", ")})',
      );
    }

    // Append the new row.
    final newFeature = CanonicalFeature(
      id: FeatureId.parse(newId),
      cells: {
        'spec': proposal.spec,
        'invariant': proposal.invariant,
        'provenance': acceptedConceptProvenance,
      },
    );
    final mergedFeatures = [
      ...existing.matrix.features,
      newFeature,
    ];
    final mergedMatrix = CanonicalMatrix(
      concept: existing.matrix.concept,
      version: existing.matrix.version,
      columnSchema: _widenColumnSchema(
        existing.matrix.columnSchema,
        mergedFeatures,
      ),
      features: mergedFeatures,
    );
    final updated = CanonicalPack(
      meta: existing.meta,
      indexContent: existing.indexContent,
      matrix: mergedMatrix,
      changelogContent: existing.changelogContent,
    );
    await store.save(conceptId, updated);

    // Hygiene: drop the accepted proposal from the file. (Don't delete the
    // whole file — other proposals may still be pending.) Preserve the
    // original `produced_at` so the file keeps reflecting when distill
    // actually ran, not when the most recent accept happened.
    proposalMap.remove(fromProposal);
    final originalProducedAt = DateTime.tryParse(
      payload['produced_at']?.toString() ?? '',
    );
    await writeProposalsFile(
      conceptId,
      proposals: proposalMap.values.toList(growable: false),
      executorUsed: payload['executor_used']?.toString() ?? 'unknown',
      producedAt: originalProducedAt,
    );

    return AcceptConceptResult(
      acceptedId: newId,
      proposalName: fromProposal,
    );
  }

  @override
  Future<CanonicalPack> import(
    final String externalConceptDir, {
    required final String asConceptId,
  }) async {
    final dir = Directory(externalConceptDir);
    if (!await dir.exists()) {
      throw ArgumentError(
          'External canonical dir does not exist: $externalConceptDir');
    }
    final metaFile = File(p.join(dir.path, AeCoreConfig.canonicalMetaFile));
    final indexFile = File(p.join(dir.path, AeCoreConfig.canonicalIndexFile));
    final matrixFile = File(p.join(dir.path, AeCoreConfig.canonicalMatrixFile));
    if (!await metaFile.exists()) {
      throw ArgumentError(
          'External canonical missing meta.yaml: $externalConceptDir');
    }
    final metaYaml = loadYaml(await metaFile.readAsString());
    if (metaYaml is! Map) {
      throw ArgumentError('External meta.yaml is not a map');
    }
    final meta = CanonicalMeta.fromMap(metaYaml);
    final indexContent =
        await indexFile.exists() ? await indexFile.readAsString() : '';
    CanonicalMatrix matrix;
    if (await matrixFile.exists()) {
      final raw = loadYaml(await matrixFile.readAsString());
      matrix = raw is Map
          ? CanonicalMatrix.fromMap(raw)
          : CanonicalMatrix(
              concept: meta.concept,
              version: meta.version,
              columnSchema: const [],
              features: const [],
            );
    } else {
      matrix = CanonicalMatrix(
        concept: meta.concept,
        version: meta.version,
        columnSchema: const [],
        features: const [],
      );
    }
    final pack = CanonicalPack(
      meta: meta,
      indexContent: indexContent,
      matrix: matrix,
    );
    await store.save(asConceptId, pack);
    return pack;
  }
}

class _ScaffoldSymbol {
  const _ScaffoldSymbol({required this.symbol, required this.kind});
  final String symbol;
  final String kind;
}
