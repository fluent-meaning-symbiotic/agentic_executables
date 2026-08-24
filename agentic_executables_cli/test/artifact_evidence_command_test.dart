import 'dart:io';

import 'package:agentic_executables_core/agentic_executables_core.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'test_utils.dart';

late String _rootPath;

Future<CliRunResult> _run(final List<String> args) =>
    runCli([...args, '--root', _rootPath]);

Future<void> _seed(final Directory root) async {
  final hub = Directory(p.join(root.path, '.ae_hub'));
  await hub.create(recursive: true);
  await File(p.join(hub.path, 'hub.yaml')).writeAsString('version: 1\n');
  final canStore = FileCanonicalStore(hub.path);
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
            cells: const {'spec': 's', 'invariant': 'creates exactly one'},
          ),
          CanonicalFeature(
            id: FeatureId.parse('entity.destroy'),
            cells: const {'spec': 's', 'invariant': 'idempotent delete'},
          ),
        ],
      ),
    ),
  );
  final artStore = FileArtifactStore(hub.path);
  await artStore.save(
    ArtifactPack(
      name: 'dart_ecs',
      meta: ArtifactMeta(
        kind: ArtifactKind.local,
        title: 'Dart ECS',
        source: ArtifactSource(
          type: ArtifactSourceType.path,
          path: '.',
          files: const [ArtifactSourceFile(path: 'lib/x.dart', sha256: 'h')],
        ),
        scannedAt: DateTime.utc(2026, 8, 24),
        license: const ArtifactLicense(spdx: 'MIT'),
        referencesCanonical: [CanonicalReference.parse('ecs')],
        extractor: 'dart_v1',
        distill: const ArtifactDistill(engine: 'heuristic'),
      ),
      indexContent: '# dart_ecs\n\n## Public API\n\n- entity.create\n- entity.destroy\n',
      matrix: ArtifactMatrix(
        columnSchema: const [],
        features: [
          ArtifactFeatureRow(
            id: FeatureId.parse('entity.create'),
            canonical: 'ecs',
            cell: const ArtifactCell(impl: ImplStatus.missing),
          ),
          ArtifactFeatureRow(
            id: FeatureId.parse('entity.destroy'),
            canonical: 'ecs',
            cell: const ArtifactCell(impl: ImplStatus.missing),
          ),
        ],
      ),
    ),
  );
}

void main() {
  late Directory temp;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('ae_mark_ev_');
    _rootPath = temp.path;
    await _seed(temp);
  });

  tearDown(() => temp.delete(recursive: true));

  test('mark-evidence records provenance; verify --run-tests executes it',
      () async {
    // Mark with a command that passes (true is POSIX-guaranteed).
    final mark = await _run([
      'artifact', 'mark-evidence',
      '--pack', 'dart_ecs',
      '--feature', 'entity.create',
      '--test-command', 'true',
      '--location', 'test/entity_test.dart',
    ]);
    expect(mark.exitCode, 0, reason: mark.stdout);
    final cell = (mark.json['data']['cell'] as Map)['evidence_command'];
    expect(cell, 'true');

    // Before marking the second feature: Tier 1 fires for it.
    final before = await _run(['artifact', 'verify', '--pack', 'dart_ecs']);
    expect(before.exitCode, 0);
    final tiersBefore =
        (before.json['data']['tier_counts'] as Map)['invariant_violation'];
    expect(tiersBefore, 1);

    // --run-tests on a green command: no Tier 1 for that feature.
    final after = await _run(
      ['artifact', 'verify', '--pack', 'dart_ecs', '--run-tests'],
    );
    expect(after.exitCode, 0);
    // Only entity.destroy remains unverified (no evidence recorded).
    expect((after.json['data']['tier_counts'] as Map)['invariant_violation'], 1);

    // Now lie about the second feature and watch --run-tests catch it.
    final lie = await _run([
      'artifact', 'mark-evidence',
      '--pack', 'dart_ecs',
      '--feature', 'entity.destroy',
      '--test-command', 'test -f /nonexistent/ae_proof_file',
    ]);
    expect(lie.exitCode, 0, reason: lie.stdout);

    final caught = await _run(
      ['artifact', 'verify', '--pack', 'dart_ecs', '--run-tests'],
    );
    expect(caught.exitCode, 0);
    final entries = (caught.json['data']['entries'] as List)
        .cast<Map>()
        .where((e) => e['tier'] == 1)
        .toList();
    expect(entries, hasLength(1));
    expect((entries.single)['message'], contains('evidence failed'));

    // And --strict fails the envelope because blocking tiers exist.
    final strict = await _run(
      ['artifact', 'verify', '--pack', 'dart_ecs', '--run-tests', '--strict'],
    );
    expect(strict.exitCode, isNot(0));
    expect(strict.json['success'], isFalse);
  });

  test('mark-evidence fails with feature_not_found for unknown id', () async {
    final r = await _run([
      'artifact', 'mark-evidence',
      '--pack', 'dart_ecs',
      '--feature', 'entity.nope',
      '--test-command', 'true',
    ]);
    expect(r.exitCode, 1);
    expect(r.json['error']['code'], 'feature_not_found');
  });
}
