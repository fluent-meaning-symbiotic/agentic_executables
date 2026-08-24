import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:agentic_executables_cli/agentic_executables_cli.dart';
import 'package:agentic_executables_core/agentic_executables_core.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

Map<String, dynamic> _draft({
  required final String concept,
  final List<CanonicalFeature> features = const [],
  final List<ProposedConcept> proposals = const [],
  final String? schemaOverride,
}) =>
    DistillationOutput(
      conceptId: concept,
      conceptVersion: 1,
      indexMd: '# $concept (distilled)\n',
      matrix: CanonicalMatrix(
        concept: concept,
        version: 1,
        columnSchema: const [
          CanonicalColumn(id: 'spec', type: 'text'),
        ],
        features: features,
      ),
      proposedConcepts: proposals,
    ).toJson()..['schema'] = schemaOverride ?? 'ae.canonical.draft.v1';

Future<void> _writeArtifactPack(final String hubPath) async {
  final meta = ArtifactMeta(
    kind: ArtifactKind.local,
    title: 'Dart ECS',
    source: ArtifactSource(
      type: ArtifactSourceType.path,
      path: 'core_packages/ecs',
      files: const [
        ArtifactSourceFile(path: 'lib/src/world.dart', sha256: 'h1'),
      ],
    ),
    scannedAt: DateTime.utc(2026, 4, 17, 12),
    license: const ArtifactLicense(spdx: 'MIT'),
    referencesCanonical: [CanonicalReference.parse('ecs')],
    extractor: 'dart_v1',
    distill: const ArtifactDistill(engine: 'heuristic'),
  );
  final pack = ArtifactPack(
    name: 'dart_ecs',
    meta: meta,
    indexContent: '# dart_ecs\n\nSummary.\n',
    matrix: const ArtifactMatrix(columnSchema: [], features: []),
  );
  final store = FileArtifactStore(hubPath);
  await store.save(pack);
}

Future<void> _writeCanonicalSeed(final String hubPath) async {
  final store = FileCanonicalStore(hubPath);
  final svc = DefaultCanonicalService(store: store);
  await svc.scaffold('ecs', title: 'ECS');
  // Seed the matrix with the ids the agent's draft will enrich, so
  // the id-stability validator (mergeDistillationDetailed) accepts it.
  final seeded = await svc.load('ecs');
  await svc.upsert(
    'ecs',
    CanonicalPack(
      meta: seeded!.meta,
      indexContent: seeded.indexContent,
      changelogContent: seeded.changelogContent,
      matrix: CanonicalMatrix(
        concept: 'ecs',
        version: 1,
        columnSchema: const [CanonicalColumn(id: 'spec', type: 'text')],
        features: [
          CanonicalFeature(
            id: FeatureId.parse('entity.create'),
            cells: const {'spec': 'stub'},
          ),
          CanonicalFeature(
            id: FeatureId.parse('entity.destroy'),
            cells: const {'spec': 'stub'},
          ),
        ],
      ),
    ),
  );
}

class _CliRun {
  const _CliRun({required this.exitCode, required this.stdout});
  final int exitCode;
  final String stdout;

  Map<String, dynamic> get json =>
      jsonDecode(stdout) as Map<String, dynamic>;
}

Future<_CliRun> _run(
  final List<String> args,
) async {
  final outCtl = StreamController<List<int>>();
  final errCtl = StreamController<List<int>>();
  final outBuf = StringBuffer();
  final errBuf = StringBuffer();
  final outDone = Completer<void>();
  final errDone = Completer<void>();
  outCtl.stream
      .transform(utf8.decoder)
      .listen(outBuf.write, onDone: outDone.complete);
  errCtl.stream
      .transform(utf8.decoder)
      .listen(errBuf.write, onDone: errDone.complete);
  final outSink = IOSink(outCtl.sink);
  final errSink = IOSink(errCtl.sink);
  final cli = AeCli(out: outSink, err: errSink, environment: const {});
  final exit = await cli.run(args);
  await outSink.close();
  await errSink.close();
  await outDone.future;
  await errDone.future;
  return _CliRun(exitCode: exit, stdout: outBuf.toString());
}

void main() {
  group('ae canonical distill (delegation)', () {
    late Directory tempProject;
    late String hubPath;

    setUp(() async {
      tempProject = await Directory.systemTemp.createTemp('ae_distill_cli_');
      final hub = Directory(p.join(tempProject.path, '.ae_hub'));
      await hub.create();
      await File(p.join(hub.path, 'hub.yaml')).writeAsString('version: 1\n');
      hubPath = hub.path;
      await _writeArtifactPack(hubPath);
      await _writeCanonicalSeed(hubPath);
    });

    tearDown(() async {
      await tempProject.delete(recursive: true);
    });

    test('emit phase returns delegation instructions, never runs a model',
        () async {
      final result = await _run([
        'canonical',
        'distill',
        '--pack',
        'dart_ecs',
        '--concept',
        'ecs',
        '--root',
        tempProject.path,
      ]);

      expect(result.exitCode, 0);
      final envelope = result.json;
      expect(envelope['success'], isTrue, reason: 'envelope: ${result.stdout}');
      final data = envelope['data'] as Map<String, dynamic>;
      expect(data['mode'], 'delegate');
      expect(data['concept'], 'ecs');
      expect(data['seed_rows'], 2);
      final instructions = data['instructions'] as String;
      expect(instructions, contains('ID STABILITY RULES'));
      expect(instructions, contains('ae.distillation.task.v1'));
      expect(data['next'], contains('--from-output'));

      // Canonical untouched by the emit phase.
      final loaded = await FileCanonicalStore(hubPath).load('ecs');
      expect(loaded!.matrix.features.length, 2);
    });

    test('emit fails with artifact_not_found when pack unknown', () async {
      final result = await _run([
        'canonical',
        'distill',
        '--pack',
        'nonexistent_pack',
        '--concept',
        'ecs',
        '--root',
        tempProject.path,
      ]);
      expect(result.exitCode, 1);
      final envelope = result.json;
      expect(envelope['success'], isFalse);
      expect((envelope['error'] as Map)['code'], 'artifact_not_found');
    });

    test('merge phase merges a returned draft via --from-output file',
        () async {
      final draftFile =
          File(p.join(tempProject.path, 'agent_draft.json'));
      await draftFile.writeAsString(
        jsonEncode(
          _draft(
            concept: 'ecs',
            features: [
              CanonicalFeature(
                id: FeatureId.parse('entity.create'),
                cells: const {'spec': 'enriched'},
              ),
            ],
          ),
        ),
      );

      final result = await _run([
        'canonical',
        'distill',
        '--concept',
        'ecs',
        '--from-output',
        draftFile.path,
        '--root',
        tempProject.path,
      ]);

      expect(result.exitCode, 0, reason: 'stdout: ${result.stdout}');
      final data = result.json['data'] as Map<String, dynamic>;
      expect(data['merged'], isTrue);
      expect(data['executor_used'], 'host_agent');
      expect(data['feature_count_after_merge'], 2);

      final loaded = await FileCanonicalStore(hubPath).load('ecs');
      final row = loaded!.matrix.features
          .firstWhere((final f) => f.id.toString() == 'entity.create');
      expect(row.cells['spec'], 'enriched');
    });

    test('merge passes through proposed_concepts and persists them',
        () async {
      final draftFile =
          File(p.join(tempProject.path, 'agent_draft.json'));
      await draftFile.writeAsString(
        jsonEncode(
          _draft(
            concept: 'ecs',
            features: [
              CanonicalFeature(
                id: FeatureId.parse('entity.create'),
                cells: const {'spec': 'enriched'},
              ),
            ],
            proposals: const [
              ProposedConcept(
                name: 'envelope-shape',
                spec: 'every command writes JSON',
                invariant: 'success is bool',
                rationale: 'cross-cutting',
              ),
            ],
          ),
        ),
      );
      final result = await _run([
        'canonical',
        'distill',
        '--concept',
        'ecs',
        '--from-output',
        draftFile.path,
        '--root',
        tempProject.path,
      ]);
      expect(result.exitCode, 0);
      final data = result.json['data'] as Map<String, dynamic>;
      expect((data['proposed_concepts'] as List), hasLength(1));
      expect(
        File(p.join(hubPath, 'canonical', 'ecs', '.last_proposals.json'))
            .existsSync(),
        isTrue,
      );
    });

    test('merge rejects ids not in the seed matrix (id-stability)',
        () async {
      final draftFile =
          File(p.join(tempProject.path, 'agent_draft.json'));
      await draftFile.writeAsString(
        jsonEncode(
          _draft(
            concept: 'ecs',
            features: [
              CanonicalFeature(
                id: FeatureId.parse('entity.invented'),
                cells: const {'spec': 'unauthorized'},
              ),
            ],
          ),
        ),
      );
      final result = await _run([
        'canonical',
        'distill',
        '--concept',
        'ecs',
        '--from-output',
        draftFile.path,
        '--root',
        tempProject.path,
      ]);
      expect(result.exitCode, isNot(0));
      final error = result.json['error'] as Map<String, dynamic>;
      expect(error['code'], 'id_not_in_matrix');
    });

    test('merge rejects wrong schema', () async {
      final draftFile =
          File(p.join(tempProject.path, 'agent_draft.json'));
      await draftFile.writeAsString(
        jsonEncode(_draft(concept: 'ecs', schemaOverride: 'nope.v0')),
      );
      final result = await _run([
        'canonical',
        'distill',
        '--concept',
        'ecs',
        '--from-output',
        draftFile.path,
        '--root',
        tempProject.path,
      ]);
      expect(result.exitCode, isNot(0));
      final error = result.json['error'] as Map<String, dynamic>;
      expect(error['code'], 'draft_schema_mismatch');
    });
  });
}
