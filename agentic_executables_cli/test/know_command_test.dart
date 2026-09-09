import 'dart:convert';
import 'dart:io';

import 'package:agentic_executables_wire/agentic_executables_wire.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'test_utils.dart';

/// THE GATE (harness PLAN P3, `ae know` CLI + hub manifest): rows file →
/// ae know → `.ae_ln/` canonical pack + local hub manifest → --export →
/// nodes.json → --import → byte-identical canonical form back. Corrupted
/// rows are named skips + non-zero exit; unknown kinds fail loudly.
Map<String, dynamic> _rowsSource() => {
  'schema': knowledgePackSchema,
  'concept': 'harness',
  'version': 7,
  'rows': [
    {
      'kind': 'feature',
      'id': 'kv.put',
      'label': 'kv.put',
      'props': {'spec': 'Put writes a key.'},
    },
    {'kind': 'goal', 'id': 'goal.migrate', 'label': 'Migrate the store'},
    {
      'kind': 'intent',
      'id': 'intent.kv.put',
      'label': 'put',
      'chain': ['op.put.1', 'op.put.2'],
    },
    {'kind': 'op', 'id': 'op.put.1', 'label': 'load_arg', 'props': {'a': 'key'}},
    {'kind': 'op', 'id': 'op.put.2', 'label': 'eq', 'props': {'a': 'k', 'b': 'v'}},
    {'kind': 'spec', 'id': 'spec.kv.put', 'label': 'Put writes a key'},
    {'kind': 'step', 'id': 'step.1', 'label': 'Declare schema', 'goal': 'goal.migrate'},
    {'kind': 'step', 'id': 'step.2', 'label': 'Backfill rows', 'depends_on': ['step.1']},
    {
      'kind': 'section',
      'id': 'doc.kv',
      'label': 'KV',
      'parent': 'doc.root',
    },
    {'kind': 'section', 'id': 'doc.root', 'label': 'Root'},
  ],
};

void main() {
  late Directory tempProject;

  setUp(() async {
    tempProject = await Directory.systemTemp.createTemp('ae_know_');
  });

  tearDown(() async {
    await tempProject.delete(recursive: true);
  });

  Future<CliRunResult> runKnow(
    final List<String> args, {
    final Map<String, dynamic>? source,
    final String? sourceName = 'rows.json',
  }) async {
    if (source != null && sourceName != null) {
      await File(
        p.join(tempProject.path, sourceName),
      ).writeAsString(jsonEncode(source));
    }
    return runCli([
      'know',
      ...args,
      '--root',
      tempProject.path,
      if (sourceName != null) p.join(tempProject.path, sourceName),
    ]);
  }

  group('ae know end-to-end (P3 gate)', () {
    test('rows file → pack + local hub manifest → export → import → '
        'byte-identical canonical form', () async {
      final result = await runKnow(
        ['--name', 'harness', '--concept', 'harness'],
        source: _rowsSource(),
      );
      expect(result.exitCode, 0, reason: result.stdout);
      final envelope = result.json;
      expect(envelope['success'], isTrue);

      final packFile = File(
        p.join(tempProject.path, '.ae_ln', 'harness.knowledge_pack.json'),
      );
      expect(packFile.existsSync(), isTrue);
      final canonicalBytes = packFile.readAsBytesSync();

      // canonical form is byte-identical to the wire canonical form of the
      // source rows (construct side: rows sorted by kind, id)
      final sourcePack = jsonDecode(jsonEncode(_rowsSource())) as Map;
      final expected = canonicalJsonForm(
        constructKnowledgePack(deconstructKnowledgePack(sourcePack).tree).pack,
      );
      expect(utf8.decode(canonicalBytes), expected);
      // pack bytes hash matches the manifest entry
      final manifestFile = File(
        p.join(tempProject.path, '.ae_ln', 'hub_manifest.json'),
      );
      expect(manifestFile.existsSync(), isTrue);
      final manifest =
          validateHubManifest(jsonDecode(manifestFile.readAsStringSync()) as Map);
      expect(manifest.isValid, isTrue);
      final entry = manifest.manifest.byPack['harness']!;
      expect(entry.file, 'harness.knowledge_pack.json');
      expect(entry.sha256, (envelope['data'] as Map)['sha256']);
      expect(entry.version, 7);

      // export → nodes.json
      final exportResult = await runCli([
        'know',
        '--export',
        p.join(tempProject.path, 'nodes.json'),
        '--name',
        'harness',
        '--root',
        tempProject.path,
      ]);
      expect(exportResult.exitCode, 0, reason: exportResult.stdout);
      final nodesFile = File(p.join(tempProject.path, 'nodes.json'));
      expect(nodesFile.existsSync(), isTrue);
      final tree =
          MeaningTreeExport.fromMap(jsonDecode(nodesFile.readAsStringSync()) as Map);
      final kinds = tree.nodes.map((n) => n.kind).toSet();
      expect(
        kinds,
        containsAll(['intent', 'op', 'step', 'goal', 'section', 'spec', 'feature']),
      );
      final edgeKeys = tree.edges.map((e) => '${e.from}→${e.to}').toSet();
      expect(edgeKeys, contains('intent.kv.put→op.put.1'));
      expect(edgeKeys, contains('step.1→goal.migrate'));
      expect(edgeKeys, contains('doc.root→doc.kv'));

      // import → byte-identical canonical form back (into another pack id)
      final importResult = await runCli([
        'know',
        '--import',
        p.join(tempProject.path, 'nodes.json'),
        '--name',
        'harness2',
        '--root',
        tempProject.path,
      ]);
      expect(importResult.exitCode, 0, reason: importResult.stdout);
      final rebuilt = File(
        p.join(tempProject.path, '.ae_ln', 'harness2.knowledge_pack.json'),
      ).readAsStringSync();
      expect(rebuilt, utf8.decode(canonicalBytes));

      // manifest now holds both packs, each with a real sha256 + version
      final manifest2 = validateHubManifest(
        jsonDecode(manifestFile.readAsStringSync()) as Map,
      );
      expect(manifest2.manifest.entries.map((e) => e.pack),
          containsAll(['harness', 'harness2']));
      expect(manifest2.manifest.byPack['harness2']!.sha256, entry.sha256);
    });

    test('corrupted row → named skip on stderr + non-zero exit, '
        'no pack written', () async {
      final source = _rowsSource();
      (source['rows'] as List).insert(1, {
        'kind': 'op',
        'props': {'a': 'x'},
        'b': 'y',
        'id': 'op.mixed',
        'label': 'eq',
      });
      final result = await runKnow(['--name', 'broken'], source: source);
      expect(result.exitCode, isNot(0));
      expect(result.stderr, contains('ae know: skip'));
      expect(result.stderr, contains('op.mixed'));
      expect(result.stderr, contains('ambiguous shape'));
      expect(
        File(p.join(tempProject.path, '.ae_ln', 'broken.knowledge_pack.json'))
            .existsSync(),
        isFalse,
        reason: 'validation failed — no pack written',
      );
    });

    test('unknown row kind fails LOUDLY with the kind named', () async {
      final source = _rowsSource();
      (source['rows'] as List).add({
        'kind': 'alien',
        'id': 'x.1',
        'label': 'mystery',
      });
      final result = await runKnow(['--name', 'alienpack'], source: source);
      expect(result.exitCode, isNot(0));
      final error = (result.json['error'] as Map?) ?? const {};
      expect(error['code'], 'know_unknown_kind');
      expect(error['message'], contains('alien'));
      expect(error['message'], contains('x.1'));
      expect(error['message'], contains('fail loudly'));
    });

    test('export of a missing pack is a named failure', () async {
      final result = await runCli([
        'know',
        '--export',
        p.join(tempProject.path, 'nodes.json'),
        '--name',
        'ghost',
        '--root',
        tempProject.path,
      ]);
      expect(result.exitCode, isNot(0));
      expect((result.json['error'] as Map)['code'], 'know_pack_not_found');
    });

    test('broken existing hub manifest is a loud failure, not rebuilt', () async {
      final ln = Directory(p.join(tempProject.path, '.ae_ln'));
      await ln.create(recursive: true);
      await File(
        p.join(ln.path, 'hub_manifest.json'),
      ).writeAsString('{"schema": "ae.hub_manifest.v9", "entries": []}');
      final result = await runKnow(['--name', 'harness'], source: _rowsSource());
      expect(result.exitCode, isNot(0));
      expect((result.json['error'] as Map)['code'], 'know_manifest_invalid');
    });
  });
}
