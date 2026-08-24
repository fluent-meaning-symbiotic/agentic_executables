import 'dart:io';

import 'package:agentic_executables_core/agentic_executables_core.dart';
import 'package:agentic_executables_mcp/src/adapter.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

ArtifactPack _samplePack(final String name) => ArtifactPack(
      name: name,
      meta: ArtifactMeta(
        kind: ArtifactKind.local,
        title: name,
        source: const ArtifactSource(
          type: ArtifactSourceType.path,
          path: '/tmp/x',
        ),
        scannedAt: DateTime.utc(2026, 4, 17),
        referencesCanonical: const [],
        extractor: 'dart_v1',
        distill: const ArtifactDistill(engine: 'heuristic'),
      ),
      indexContent: '# $name',
      matrix: const ArtifactMatrix(columnSchema: [], features: []),
    );

void main() {
  group('AeMcpAdapter.artifact', () {
    late Directory tempProject;
    late AeMcpAdapter adapter;

    setUp(() async {
      tempProject = await Directory.systemTemp.createTemp('mcp_art_');
      final hub = Directory(p.join(tempProject.path, '.ae_hub'));
      await hub.create();
      await File(p.join(hub.path, 'hub.yaml')).writeAsString('version: 1\n');
      adapter = AeMcpAdapter(resourcesPath: '/tmp/nonexistent');
    });

    tearDown(() async {
      await tempProject.delete(recursive: true);
    });

    test('list returns names', () async {
      final store = FileArtifactStore(p.join(tempProject.path, '.ae_hub'));
      await store.save(_samplePack('p1'));
      final result = await adapter.artifact({
        'operation': 'list',
        'root': tempProject.path,
      });
      expect(result['success'], isTrue);
      expect((result['data'] as Map)['artifacts'], contains('p1'));
    });

    test('link adds canonical reference', () async {
      final store = FileArtifactStore(p.join(tempProject.path, '.ae_hub'));
      await store.save(_samplePack('p1'));
      final result = await adapter.artifact({
        'operation': 'link',
        'pack': 'p1',
        'canonical': 'ecs',
        'root': tempProject.path,
      });
      expect(result['success'], isTrue);
      final loaded = await store.load('p1');
      expect(loaded!.meta.referencesCanonical, hasLength(1));
      expect(loaded.meta.referencesCanonical.first.conceptId, 'ecs');
    });

    test('verify returns tier_counts', () async {
      final store = FileArtifactStore(p.join(tempProject.path, '.ae_hub'));
      await store.save(_samplePack('p1'));
      final result = await adapter.artifact({
        'operation': 'verify',
        'pack': 'p1',
        'root': tempProject.path,
      });
      expect(result['success'], isTrue);
      expect((result['data'] as Map)['tier_counts'], isA<Map>());
    });

    test('mark-evidence records provenance; unknown id errors', () async {
      // Seed a canonical + linked row so the feature exists.
      final hub = p.join(tempProject.path, '.ae_hub');
      final canStore = FileCanonicalStore(hub);
      final canSvc = DefaultCanonicalService(store: canStore);
      await canSvc.scaffold('ecs', title: 'ECS');
      final seeded = await canSvc.load('ecs');
      await canSvc.upsert(
        'ecs',
        CanonicalPack(
          meta: seeded!.meta,
          indexContent: seeded.indexContent,
          changelogContent: seeded.changelogContent,
          matrix: CanonicalMatrix(
            concept: 'ecs',
            version: 1,
            columnSchema: const [
              CanonicalColumn(id: 'spec', type: 'text'),
              CanonicalColumn(id: 'invariant', type: 'text'),
            ],
            features: [
              CanonicalFeature(
                id: FeatureId.parse('entity.create'),
                cells: const {'spec': 's', 'invariant': 'i'},
              ),
            ],
          ),
        ),
      );
      final store = FileArtifactStore(hub);
      final pack = _samplePack('p1');
      await store.save(
        ArtifactPack(
          name: pack.name,
          meta: ArtifactMeta(
            kind: pack.meta.kind,
            title: pack.meta.title,
            source: pack.meta.source,
            scannedAt: pack.meta.scannedAt,
            license: pack.meta.license,
            authors: pack.meta.authors,
            referencesCanonical: [CanonicalReference.parse('ecs')],
            extractor: pack.meta.extractor,
            distill: pack.meta.distill,
          ),
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
        ),
      );

      final ok = await adapter.artifact({
        'operation': 'mark-evidence',
        'pack': 'p1',
        'feature_id': 'entity.create',
        'test_command': 'true',
        'root': tempProject.path,
      });
      expect(ok['success'], isTrue, reason: '$ok');
      expect(
        ((ok['data'] as Map)['cell'] as Map)['evidence_command'],
        'true',
      );

      final miss = await adapter.artifact({
        'operation': 'mark-evidence',
        'pack': 'p1',
        'feature_id': 'entity.nope',
        'test_command': 'true',
        'root': tempProject.path,
      });
      expect(miss['success'], isFalse);
      expect((miss['error'] as Map)['code'], 'feature_not_found');
    });

    test('returns validation_error when operation missing', () async {
      final result = await adapter.artifact({});
      expect(result['success'], isFalse);
      expect((result['error'] as Map)['code'], 'validation_error');
    });
  });
}
