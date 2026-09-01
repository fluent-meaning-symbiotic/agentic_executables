import 'dart:convert';
import 'dart:io';

import 'package:agentic_executables_wire/agentic_executables_wire.dart';
import 'package:test/test.dart';

void main() {
  test('canonical pack → meaning tree export (deterministic, LLM-free)', () {
    final pack =
        jsonDecode(File('test/fixtures/canonical_ecs.json').readAsStringSync())
            as Map;
    final export = canonicalToMeaningTree(pack);

    // concept nodes from id paths + one feature node per row
    final ids = export.nodes.map((n) => n.id).toSet();
    expect(ids, containsAll(['entity', 'system', 'query']));
    expect(ids, containsAll(['entity.create', 'system.tick', 'query.iterate']));
    expect(export.nodes.where((n) => n.kind == 'feature').length, 3);
    expect(export.nodes.where((n) => n.kind == 'concept').length, 3);

    // contains edges: parent → child along each id path
    final edgeKeys = export.edges.map((e) => '${e.from}→${e.to}').toSet();
    expect(edgeKeys, containsAll(['entity→entity.create', 'system→system.tick', 'query→query.iterate']));

    // feature props carry the row cells verbatim
    final create = export.nodes.firstWhere((n) => n.id == 'entity.create');
    expect(
      (create.props['spec'] as String).contains('unique opaque handle'),
      isTrue,
    );
    expect(create.props.containsKey('invariant'), isTrue);

    // meta provenance travels
    expect(export.meta['concept'], 'ecs');
    expect(export.meta['features'], 3);
  });

  test('export JSON round-trips through toMap/fromMap', () {
    final pack =
        jsonDecode(File('test/fixtures/canonical_ecs.json').readAsStringSync())
            as Map;
    final export = canonicalToMeaningTree(pack);
    final restored = MeaningTreeExport.fromMap(export.toMap());
    expect(restored.nodes.map((n) => n.id), export.nodes.map((n) => n.id));
    expect(restored.edges.map((e) => e.toMap()), export.edges.map((e) => e.toMap()));
    expect(restored.toMap()['schema'], 'ae.meaning_tree_export.v1');
  });

  test('standalone canonical matrix (no pack envelope) also converts', () {
    final export = canonicalToMeaningTree({
      'schema': 'ae.canonical_matrix.v1',
      'concept': 'kv',
      'version': 2,
      'features': [
        {'id': 'kv.put', 'spec': 'Put writes a key.'},
        {'id': 'kv.get', 'spec': 'Get reads a key back.'},
      ],
    });
    expect(export.nodes.map((n) => n.id), containsAll(['kv', 'kv.put', 'kv.get']));
    expect(export.meta['concept'], 'kv');
  });

  test('is deterministic: same input → byte-identical export', () {
    final pack =
        jsonDecode(File('test/fixtures/canonical_ecs.json').readAsStringSync())
            as Map;
    final a = canonicalToMeaningTree(pack).toMap();
    final b = canonicalToMeaningTree(pack).toMap();
    expect(jsonEncode(a), jsonEncode(b));
  });
}
