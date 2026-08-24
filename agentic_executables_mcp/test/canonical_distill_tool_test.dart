import 'dart:io';

import 'package:agentic_executables_core/agentic_executables_core.dart';
import 'package:agentic_executables_mcp/src/adapter.dart';
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
    source: const ArtifactSource(
      type: ArtifactSourceType.path,
      path: 'core_packages/ecs',
      files: [
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

void main() {
  group('AeMcpAdapter.canonical (distill delegation)', () {
    late Directory tempProject;
    late String hubPath;

    setUp(() async {
      tempProject = await Directory.systemTemp.createTemp('mcp_distill_');
      final hub = Directory(p.join(tempProject.path, '.ae_hub'));
      await hub.create();
      await File(p.join(hub.path, 'hub.yaml')).writeAsString('version: 1\n');
      hubPath = hub.path;
      await _writeArtifactPack(hubPath);
      await _writeCanonicalSeed(hubPath);
    });

    tearDown(() async => tempProject.delete(recursive: true));

    test('emit phase returns delegation instructions, never runs a model',
        () async {
      final adapter = AeMcpAdapter(resourcesPath: '/tmp/nonexistent');
      final result = await adapter.canonical({
        'operation': 'distill',
        'pack': 'dart_ecs',
        'concept': 'ecs',
        'root': tempProject.path,
      });

      expect(result['success'], isTrue, reason: 'result: $result');
      final data = result['data'] as Map<String, dynamic>;
      expect(data['mode'], 'delegate');
      expect(data['concept'], 'ecs');
      expect(data['seed_rows'], 2);
      final instructions = data['instructions'] as String;
      expect(instructions, contains('ID STABILITY RULES'));
      expect(instructions, contains('ae.distillation.task.v1'));
      expect(data['next'], contains('distill-merge'));
    });

    test('emit fails with validation_error when pack missing', () async {
      final adapter = AeMcpAdapter(resourcesPath: '/tmp/nonexistent');
      final result = await adapter.canonical({
        'operation': 'distill',
        'concept': 'ecs',
        'root': tempProject.path,
      });
      expect(result['success'], isFalse);
      expect((result['error'] as Map)['code'], 'validation_error');
    });

    test('emit fails with artifact_not_found when pack unknown', () async {
      final adapter = AeMcpAdapter(resourcesPath: '/tmp/nonexistent');
      final result = await adapter.canonical({
        'operation': 'distill',
        'pack': 'missing_pack',
        'concept': 'ecs',
        'root': tempProject.path,
      });
      expect(result['success'], isFalse);
      expect((result['error'] as Map)['code'], 'artifact_not_found');
    });

    test('merge phase merges a returned draft into the canonical', () async {
      final adapter = AeMcpAdapter(resourcesPath: '/tmp/nonexistent');
      final result = await adapter.canonical({
        'operation': 'distill-merge',
        'concept': 'ecs',
        'root': tempProject.path,
        'output': _draft(
          concept: 'ecs',
          features: [
            CanonicalFeature(
              id: FeatureId.parse('entity.create'),
              cells: {'spec': 'enriched'},
            ),
          ],
        ),
      });

      expect(result['success'], isTrue, reason: 'result: $result');
      final data = result['data'] as Map<String, dynamic>;
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
      final adapter = AeMcpAdapter(resourcesPath: '/tmp/nonexistent');
      final result = await adapter.canonical({
        'operation': 'distill-merge',
        'concept': 'ecs',
        'root': tempProject.path,
        'output': _draft(
          concept: 'ecs',
          features: [
            CanonicalFeature(
              id: FeatureId.parse('entity.create'),
              cells: {'spec': 'enriched'},
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
      });

      expect(result['success'], isTrue, reason: 'result: $result');
      final data = result['data'] as Map<String, dynamic>;
      expect((data['proposed_concepts'] as List), hasLength(1));
      expect(
        File(p.join(hubPath, 'canonical', 'ecs', '.last_proposals.json'))
            .existsSync(),
        isTrue,
      );
    });

    test('merge rejects ids not in the seed matrix (id-stability)',
        () async {
      final adapter = AeMcpAdapter(resourcesPath: '/tmp/nonexistent');
      final result = await adapter.canonical({
        'operation': 'distill-merge',
        'concept': 'ecs',
        'root': tempProject.path,
        'output': _draft(
          concept: 'ecs',
          features: [
            CanonicalFeature(
              id: FeatureId.parse('entity.invent'),
              cells: {'spec': 'invented id'},
            ),
          ],
        ),
      });
      expect(result['success'], isFalse);
      expect((result['error'] as Map)['code'], 'id_not_in_matrix');
    });

    test('merge rejects wrong schema', () async {
      final adapter = AeMcpAdapter(resourcesPath: '/tmp/nonexistent');
      final result = await adapter.canonical({
        'operation': 'distill-merge',
        'concept': 'ecs',
        'root': tempProject.path,
        'output': _draft(concept: 'ecs', schemaOverride: 'some.other.schema'),
      });
      expect(result['success'], isFalse);
      expect((result['error'] as Map)['code'], 'draft_schema_mismatch');
    });

    test('merge rejects concept mismatch', () async {
      final adapter = AeMcpAdapter(resourcesPath: '/tmp/nonexistent');
      final result = await adapter.canonical({
        'operation': 'distill-merge',
        'concept': 'ecs',
        'root': tempProject.path,
        'output': _draft(concept: 'other_concept'),
      });
      expect(result['success'], isFalse);
      expect((result['error'] as Map)['code'], 'draft_concept_mismatch');
    });
  });
}
