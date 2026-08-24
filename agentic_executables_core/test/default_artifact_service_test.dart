import 'dart:io';

import 'package:agentic_executables_core/agentic_executables_core.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

ArtifactPack _samplePack({
  final String name = 'dart_ecs',
  final List<CanonicalReference> references = const [],
}) {
  final meta = ArtifactMeta(
    kind: ArtifactKind.local,
    title: name,
    source: ArtifactSource(
      type: ArtifactSourceType.path,
      path: 'src/$name',
      files: const [
        ArtifactSourceFile(path: 'lib/x.dart', sha256: 'old_hash'),
      ],
    ),
    scannedAt: DateTime.utc(2026, 4, 17),
    license: const ArtifactLicense(spdx: 'MIT', detectedFrom: 'license_file'),
    authors: const [],
    referencesCanonical: references,
    extractor: 'dart_v1',
    distill: const ArtifactDistill(engine: 'heuristic'),
  );
  return ArtifactPack(
    name: name,
    meta: meta,
    indexContent: '# $name',
    matrix: const ArtifactMatrix(columnSchema: [], features: []),
  );
}

CanonicalPack _canonicalWithFeatures(
  final String concept,
  final List<String> featureIds,
) {
  return CanonicalPack(
    meta: CanonicalMeta(
      concept: concept,
      version: 1,
      title: concept,
      license: const CanonicalLicense(spdx: 'CC-BY-4.0', url: 'https://c.org'),
      authors: const [],
      sources: const [
        CanonicalSource(
          kind: CanonicalSourceKind.code,
          title: 'src',
          url: 'https://x',
        ),
      ],
      provenance: CanonicalProvenance(
        authored: CanonicalAuthored.hand,
        authoredAt: DateTime.utc(2026, 4, 17),
      ),
    ),
    indexContent: '# $concept',
    matrix: CanonicalMatrix(
      concept: concept,
      version: 1,
      columnSchema: const [
        CanonicalColumn(id: 'spec', type: 'text'),
        CanonicalColumn(id: 'invariant', type: 'text'),
      ],
      features: [
        for (final id in featureIds)
          CanonicalFeature(
            id: FeatureId.parse(id),
            cells: const {'spec': 'spec', 'invariant': 'inv'},
          ),
      ],
    ),
  );
}

void main() {
  _evidenceGroup();
  group('DefaultArtifactService', () {
    late Directory tempHub;
    late FileArtifactStore artStore;
    late FileCanonicalStore canStore;
    late HeuristicExtractorRegistry registry;
    late DefaultArtifactService svc;

    setUp(() async {
      tempHub = await Directory.systemTemp.createTemp('ae_asvc_');
      artStore = FileArtifactStore(tempHub.path);
      canStore = FileCanonicalStore(tempHub.path);
      registry = HeuristicExtractorRegistry(const [
        DartHeuristicExtractor(),
        RustHeuristicExtractor(),
        KotlinSwiftHeuristicExtractor(),
      ]);
      svc = DefaultArtifactService(
        artifactStore: artStore,
        canonicalStore: canStore,
        extractorRegistry: registry,
      );
    });

    tearDown(() async {
      await tempHub.delete(recursive: true);
    });

    test('ingest extracts dart fixture and persists artifact', () async {
      final fixture = Directory(
        p.join(Directory.current.path, 'test', 'fixtures', 'dart_pkg_min'),
      );
      final name = await svc.ingest(fixture);
      expect(name, 'ecsly');
      expect(await artStore.exists('ecsly'), isTrue);
      final loaded = await artStore.load('ecsly');
      expect(loaded?.meta.kind, ArtifactKind.local);
    });

    test('list reflects ingested artifacts', () async {
      final fixture = Directory(
        p.join(Directory.current.path, 'test', 'fixtures', 'dart_pkg_min'),
      );
      await svc.ingest(fixture);
      expect(await svc.list(), contains('ecsly'));
    });

    test('ingest of non-handled directory uses the generic extractor',
        () async {
      final tmp = await Directory.systemTemp.createTemp('not_handled_');
      try {
        File('${tmp.path}/README.md')
            .writeAsStringSync('# Unknown Lang Project\n');
        final packName = await svc.ingest(tmp);
        final pack = await artStore.load(packName);
        expect(pack, isNotNull);
        expect(pack!.meta.extractor, 'generic_v1');
      } finally {
        await tmp.delete(recursive: true);
      }
    });

    test('link adds canonical reference (live)', () async {
      await artStore.save(_samplePack());
      await svc.link('dart_ecs', 'ecs');
      final loaded = await artStore.load('dart_ecs');
      expect(loaded!.meta.referencesCanonical.length, 1);
      expect(loaded.meta.referencesCanonical.first.conceptId, 'ecs');
      expect(loaded.meta.referencesCanonical.first.isLive, isTrue);
    });

    test('link with lockedVersion adds @vN reference', () async {
      await artStore.save(_samplePack());
      await svc.link('dart_ecs', 'gltf/core', lockedVersion: 2);
      final loaded = await artStore.load('dart_ecs');
      expect(loaded!.meta.referencesCanonical.first.lockedVersion, 2);
    });

    test('materialize adds rows for every referenced canonical feature',
        () async {
      // Stage canonical with two features.
      await canStore.save(
          'ecs', _canonicalWithFeatures('ecs', ['e.create', 's.tick']));
      await artStore.save(
        _samplePack(references: [CanonicalReference.parse('ecs')]),
      );

      final added = await svc.materialize('dart_ecs');
      expect(added, 2);
      final loaded = await artStore.load('dart_ecs');
      final ids =
          loaded!.matrix.features.map((final f) => f.id.toString()).toSet();
      expect(ids, containsAll(['e.create', 's.tick']));
      // All default to 'missing'.
      for (final row in loaded.matrix.features) {
        expect(row.cell.impl, ImplStatus.missing);
        expect(row.canonical, 'ecs');
      }
    });

    test('materialize is idempotent (no duplicate rows)', () async {
      await canStore.save('ecs', _canonicalWithFeatures('ecs', ['e.create']));
      await artStore.save(
        _samplePack(references: [CanonicalReference.parse('ecs')]),
      );
      await svc.materialize('dart_ecs');
      final addedSecond = await svc.materialize('dart_ecs');
      expect(addedSecond, 0);
    });

    test('upgradeCanonical updates the locked version of a reference',
        () async {
      await canStore.save('ecs', _canonicalWithFeatures('ecs', ['e.create']));
      await artStore.save(
        _samplePack(references: [CanonicalReference.parse('ecs')]),
      );
      await svc.upgradeCanonical('dart_ecs', 'ecs', toVersion: 3);
      final loaded = await artStore.load('dart_ecs');
      expect(loaded!.meta.referencesCanonical.first.lockedVersion, 3);
    });

    test('sync recomputes file hashes against meta', () async {
      // Use the dart_pkg_min fixture as source.
      final fixture = Directory(
        p.join(Directory.current.path, 'test', 'fixtures', 'dart_pkg_min'),
      );
      final name = await svc.ingest(fixture);
      // Tamper meta to wrong hash, sync should restore.
      final original = await artStore.load(name);
      final tampered = ArtifactPack(
        name: original!.name,
        meta: ArtifactMeta(
          kind: original.meta.kind,
          title: original.meta.title,
          source: ArtifactSource(
            type: original.meta.source.type,
            path: original.meta.source.path,
            files: const [
              ArtifactSourceFile(path: 'lib/ecsly.dart', sha256: 'wrong_hash'),
            ],
          ),
          scannedAt: original.meta.scannedAt,
          license: original.meta.license,
          authors: original.meta.authors,
          referencesCanonical: original.meta.referencesCanonical,
          extractor: original.meta.extractor,
          distill: original.meta.distill,
        ),
        indexContent: original.indexContent,
        matrix: original.matrix,
      );
      await artStore.save(tampered);
      final changed = await svc.sync(name);
      expect(changed, isTrue);
      final after = await artStore.load(name);
      final ecslyEntry = after!.meta.source.files
          .firstWhere((final f) => f.path == 'lib/ecsly.dart');
      expect(ecslyEntry.sha256, isNot('wrong_hash'));
      expect(ecslyEntry.sha256.length, 64);
    });

    test('remove deletes pack', () async {
      await artStore.save(_samplePack());
      expect(await svc.remove('dart_ecs'), isTrue);
      expect(await artStore.exists('dart_ecs'), isFalse);
    });

    test('syncOne without prune leaves pack with missing source intact',
        () async {
      // Stage a pack whose source path does not exist on disk.
      await artStore.save(ArtifactPack(
        name: 'orphan',
        meta: ArtifactMeta(
          kind: ArtifactKind.local,
          title: 'orphan',
          source: const ArtifactSource(
            type: ArtifactSourceType.path,
            path: '/nonexistent/path/abc',
            files: [],
          ),
          scannedAt: DateTime.utc(2026, 4, 17),
          referencesCanonical: const [],
          extractor: 'dart_v1',
          distill: const ArtifactDistill(engine: 'heuristic'),
        ),
        indexContent: '# orphan',
        matrix: const ArtifactMatrix(columnSchema: [], features: []),
      ));
      final outcome = await svc.syncOne('orphan');
      expect(outcome.pruned, isFalse);
      expect(await artStore.exists('orphan'), isTrue);
    });

    test('syncOne with prune removes pack whose source dir is gone', () async {
      // Stage a real source dir, then delete it before sync.
      final realSrc = await Directory.systemTemp.createTemp('ae_src_');
      await artStore.save(ArtifactPack(
        name: 'survivor',
        meta: ArtifactMeta(
          kind: ArtifactKind.local,
          title: 'survivor',
          source: ArtifactSource(
            type: ArtifactSourceType.path,
            path: realSrc.path,
            files: const [],
          ),
          scannedAt: DateTime.utc(2026, 4, 17),
          referencesCanonical: const [],
          extractor: 'dart_v1',
          distill: const ArtifactDistill(engine: 'heuristic'),
        ),
        indexContent: '# survivor',
        matrix: const ArtifactMatrix(columnSchema: [], features: []),
      ));
      await artStore.save(ArtifactPack(
        name: 'orphan',
        meta: ArtifactMeta(
          kind: ArtifactKind.local,
          title: 'orphan',
          source: const ArtifactSource(
            type: ArtifactSourceType.path,
            path: '/definitely/not/here',
            files: [],
          ),
          scannedAt: DateTime.utc(2026, 4, 17),
          referencesCanonical: const [],
          extractor: 'dart_v1',
          distill: const ArtifactDistill(engine: 'heuristic'),
        ),
        indexContent: '# orphan',
        matrix: const ArtifactMatrix(columnSchema: [], features: []),
      ));
      try {
        final survivorOutcome = await svc.syncOne('survivor', prune: true);
        expect(survivorOutcome.pruned, isFalse);
        expect(await artStore.exists('survivor'), isTrue);

        final orphanOutcome = await svc.syncOne('orphan', prune: true);
        expect(orphanOutcome.pruned, isTrue);
        expect(await artStore.exists('orphan'), isFalse);
      } finally {
        if (await realSrc.exists()) await realSrc.delete(recursive: true);
      }
    });
  });
}

// ---- Evidence enforcement (mark-evidence / verify --run-tests) ----

class RecordingRunner implements ProcessRunner {
  final executedCommands = <String>[];

  @override
  Future<ProcessRunResult> run({
    required final String executable,
    required final List<String> arguments,
    final String? stdinInput,
    final Map<String, String>? environment,
    final String? workingDirectory,
    final Duration? timeout,
  }) async {
    executedCommands.add(arguments.last);
    return const ProcessRunResult(exitCode: 0, stdout: '', stderr: '');
  }
}

class _FakeRunner implements ProcessRunner {
  final Map<String, int> exitCodes;
  _FakeRunner(this.exitCodes);

  @override
  Future<ProcessRunResult> run({
    required final String executable,
    required final List<String> arguments,
    final String? stdinInput,
    final Map<String, String>? environment,
    final String? workingDirectory,
    final Duration? timeout,
  }) async {
    final cmd = arguments.last;
    return ProcessRunResult(
      exitCode: exitCodes[cmd] ?? 0,
      stdout: '',
      stderr: '',
    );
  }
}

void _evidenceGroup() {
  group('DefaultArtifactService evidence', () {
    late Directory tempHub;
    late FileArtifactStore artStore;
    late FileCanonicalStore canStore;

    setUp(() async {
      tempHub = await Directory.systemTemp.createTemp('ae_evidence_');
      artStore = FileArtifactStore(tempHub.path);
      canStore = FileCanonicalStore(tempHub.path);
    });

    tearDown(() => tempHub.delete(recursive: true));

    Future<DefaultArtifactService> makeSvc({ProcessRunner? runner}) async {
      await canStore.save(
        'ecs',
        _canonicalWithFeatures('ecs', ['entity.create']),
      );
      final pack = _samplePack(references: [CanonicalReference.parse('ecs')]);
      // Materialized row for entity.create with the linked canonical.
      final withRow = ArtifactPack(
        name: pack.name,
        meta: pack.meta,
        indexContent: pack.indexContent,
        matrix: ArtifactMatrix(
          columnSchema: const [],
          features: [
            ArtifactFeatureRow(
              id: FeatureId.parse('entity.create'),
              canonical: 'ecs',
              cell: const ArtifactCell(impl: ImplStatus.missing),
            ),
          ],
        ),
      );
      await artStore.save(withRow);
      return DefaultArtifactService(
        artifactStore: artStore,
        canonicalStore: canStore,
        extractorRegistry: HeuristicExtractorRegistry(const []),
        processRunner: runner,
      );
    }

    test('markEvidence records provenance and promotes missing impl', () async {
      final svc = await makeSvc();
      final result = await svc.markEvidence(
        'dart_ecs',
        'entity.create',
        testCommand: 'dart test test/entity_test.dart',
        location: 'test/entity_test.dart',
      );
      expect(result.cell.tests, TestStatus.yes);
      expect(result.cell.evidenceCommand, 'dart test test/entity_test.dart');
      expect(result.cell.impl, ImplStatus.done);
      expect(result.cell.location, 'test/entity_test.dart');

      final loaded = await artStore.load('dart_ecs');
      expect(
        loaded!.matrix.features.single.cell.evidenceCommand,
        'dart test test/entity_test.dart',
      );
    });

    test('verify trusts recorded cells without --run-tests', () async {
      final runner = RecordingRunner();
      final svc = await makeSvc(runner: runner);
      await svc.markEvidence(
        'dart_ecs',
        'entity.create',
        testCommand: 'exit 1', // would fail if executed
      );
      final report = await svc.verifyOne('dart_ecs');
      expect(
          report.entries.where((e) => e.tier == VerifyTier.invariantViolation),
          isEmpty);
      expect(runner.executedCommands, isEmpty);
    });

    test('--run-tests passes a green command (no Tier 1)', () async {
      final svc = await makeSvc(runner: _FakeRunner({'exit 0': 0}));
      await svc.markEvidence('dart_ecs', 'entity.create',
          testCommand: 'exit 0');
      final report = await svc.verifyOne('dart_ecs', runTests: true);
      expect(
          report.entries.where((e) => e.tier == VerifyTier.invariantViolation),
          isEmpty);
    });

    test('--run-tests catches a lying cell as Tier 1', () async {
      final svc = await makeSvc(runner: _FakeRunner({'exit 3': 3}));
      await svc.markEvidence('dart_ecs', 'entity.create',
          testCommand: 'exit 3');
      final report = await svc.verifyOne('dart_ecs', runTests: true);
      final tier1 = report.entries
          .where((e) => e.tier == VerifyTier.invariantViolation)
          .toList();
      expect(tier1, hasLength(1));
      expect(
          tier1.single.message, contains("evidence failed: 'exit 3' exited 3"));
    });
  });
}
