import 'dart:convert';

import 'package:agentic_executables_wire/agentic_executables_wire.dart';
import 'package:test/test.dart';

/// THE GATE (harness PLAN Directions item 3, first gate): prove the
/// round-trip harness meaning populations → AE canonical pack → back
/// with ZERO loss, for every knowledge-at-rest kind the wire supports.
///
/// The fixture rows are in canonical order (kind, id) so the byte-identity
/// assertions below also prove pack fidelity, not just tree fidelity.

Map<String, dynamic> _fixturePack() => {
  'schema': knowledgePackSchema,
  'concept': 'harness',
  'version': 7,
  'rows': [
    // feature (canonical row kind, shared with ae.canonical.v3)
    {
      'kind': 'feature',
      'id': 'kv.put',
      'label': 'kv.put',
      'props': {'spec': 'Put writes a key.'},
    },
    // goal (GoalLink target)
    {'kind': 'goal', 'id': 'goal.migrate', 'label': 'Migrate the store'},
    // intent with a 3-op impl/then chain (op rows carry a/b + '#row' jump)
    {
      'kind': 'intent',
      'id': 'intent.kv.put',
      'label': 'put',
      'chain': ['op.put.1', 'op.put.2', 'op.put.3'],
    },
    {'kind': 'op', 'id': 'op.put.1', 'label': 'load_arg', 'props': {'a': 'key'}},
    {'kind': 'op', 'id': 'op.put.2', 'label': 'eq', 'props': {'a': 'k', 'b': 'v'}},
    {
      'kind': 'op',
      'id': 'op.put.3',
      'label': 'jump_if_false',
      'props': {'a': 'r0', 'jump': '#op.put.2'},
    },
    // sections (parented hierarchy)
    {'kind': 'section', 'id': 'doc.kv', 'label': 'KV', 'props': {'depth': 1}},
    {
      'kind': 'section',
      'id': 'doc.kv/install',
      'label': 'Install',
      'parent': 'doc.kv',
      'props': {'depth': 2},
    },
    // spec node
    {
      'kind': 'spec',
      'id': 'spec.kv.put',
      'label': 'Put writes a key',
      'props': {'oracle': 'exit0'},
    },
    // 3-step plan with dependency edges + a goal link
    {'kind': 'step', 'id': 'step.migrate.1', 'label': 'Declare schema', 'goal': 'goal.migrate'},
    {'kind': 'step', 'id': 'step.migrate.2', 'label': 'Backfill rows', 'depends_on': ['step.migrate.1']},
    {
      'kind': 'step',
      'id': 'step.migrate.3',
      'label': 'Flip reads',
      'depends_on': ['step.migrate.1', 'step.migrate.2'],
    },
  ],
};

/// Order-independent structural digest: sorted node maps + sorted edge maps.
Map<String, dynamic> _digest(MeaningTreeExport t) => {
  'nodes': [
    for (final n in t.nodes) n.toMap(),
  ]..sort((a, b) => (a['id'] as String).compareTo(b['id'] as String)),
  'edges': [
    for (final e in t.edges) e.toMap(),
  ]..sort((a, b) => jsonEncode(a).compareTo(jsonEncode(b))),
  'meta': t.meta,
};

void main() {
  test('GATE: every supported kind round-trips with ZERO loss', () {
    final pack = _fixturePack();
    final first = deconstructKnowledgePack(pack);
    expect(first.skipped, isEmpty, reason: 'fixture must be clean data');

    // kinds present in the tree, one node per row
    final kinds = first.tree.nodes.map((n) => n.kind).toSet();
    expect(
      kinds,
      containsAll(['intent', 'op', 'step', 'goal', 'section', 'spec', 'feature']),
    );
    expect(first.tree.nodes.length, 12);

    // op-chain edges: impl → first op, then → chain successors
    final edgeKeys = first.tree.edges.map((e) => '${e.from}→${e.to}').toSet();
    expect(edgeKeys, containsAll(['intent.kv.put→op.put.1', 'op.put.1→op.put.2', 'op.put.2→op.put.3']));
    // dependency edge + goal link on the plan
    expect(edgeKeys, containsAll(['step.migrate.3→step.migrate.2', 'step.migrate.1→goal.migrate']));
    // section hierarchy edge
    expect(edgeKeys, contains('doc.kv→doc.kv/install'));

    // pack → tree → pack: rows rebuild byte-identically
    final rebuilt = constructKnowledgePack(first.tree);
    expect(rebuilt.skipped, isEmpty);
    expect(canonicalKnowledgeForm(rebuilt.pack), canonicalKnowledgeForm(pack));

    // pack → tree → pack → tree: node/edge/prop equality, zero loss
    final second = deconstructKnowledgePack(rebuilt.pack);
    expect(_digest(second.tree), _digest(first.tree));

    // fixed point: the canonical form reproduces itself
    final again = constructKnowledgePack(second.tree);
    expect(canonicalKnowledgeForm(again.pack), canonicalKnowledgeForm(rebuilt.pack));
  });

  test('props survive verbatim through the round-trip (nested data)', () {
    final result = deconstructKnowledgePack({
      'rows': [
        {
          'kind': 'op',
          'id': 'op.x.1',
          'label': 'eq',
          'props': {'a': {'nested': [1, 2, 3]}, 'b': null},
        },
      ],
    });
    expect(result.skipped, isEmpty);
    final row = constructKnowledgePack(result.tree).pack['rows'].first as Map;
    expect(row['props'], {
      'a': {'nested': [1, 2, 3]},
      'b': null,
    });
  });

  test('flat extra cells (legacy feature shape) round-trip into props', () {
    final result = deconstructKnowledgePack({
      'rows': [
        {
          'kind': 'feature',
          'id': 'kv.put',
          'spec': 'Put writes a key.',
          'invariant': 'unique',
        },
      ],
    });
    expect(result.skipped, isEmpty);
    expect(result.tree.nodes.single.props, {
      'spec': 'Put writes a key.',
      'invariant': 'unique',
    });
    final row = constructKnowledgePack(result.tree).pack['rows'].first as Map;
    expect(row['props'], {'spec': 'Put writes a key.', 'invariant': 'unique'});
  });

  test('row mixing props map and flat cells is skipped as NAMED data', () {
    final result = deconstructKnowledgePack({
      'rows': [
        {
          'kind': 'op',
          'id': 'op.mixed',
          'label': 'eq',
          'props': {'a': 'x'},
          'b': 'y',
        },
      ],
    });
    expect(result.tree.nodes, isEmpty);
    expect(result.skipped.single['id'], 'op.mixed');
    expect(result.skipped.single['reason'], contains('ambiguous shape'));
  });

  test('deconstruct is deterministic: same pack → byte-identical tree', () {
    final a = deconstructKnowledgePack(_fixturePack()).tree.toMap();
    final b = deconstructKnowledgePack(_fixturePack()).tree.toMap();
    expect(jsonEncode(a), jsonEncode(b));
  });

  test('construct is deterministic: same tree → byte-identical pack', () {
    final tree = deconstructKnowledgePack(_fixturePack()).tree;
    final a = canonicalKnowledgeForm(constructKnowledgePack(tree).pack);
    final b = canonicalKnowledgeForm(constructKnowledgePack(tree).pack);
    expect(a, b);
  });

  test('canonicalKnowledgeForm is key-order independent', () {
    expect(
      canonicalKnowledgeForm({'b': 1, 'a': {'z': 2, 'y': 3}}),
      canonicalKnowledgeForm({'a': {'y': 3, 'z': 2}, 'b': 1}),
    );
  });

  test('UNKNOWN kind fails LOUDLY on deconstruct (AE wire rule)', () {
    expect(
      () => deconstructKnowledgePack({
        'rows': [
          {'kind': 'alien', 'id': 'x.1', 'label': 'mystery'},
        ],
      }),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          allOf(contains('alien'), contains('x.1'), contains('fail loudly')),
        ),
      ),
    );
  });

  test('UNKNOWN kind fails LOUDLY on construct (AE wire rule)', () {
    expect(
      () => constructKnowledgePack(
        MeaningTreeExport(nodes: const [
          ExportNode(id: 'x.1', kind: 'alien', label: 'mystery'),
        ], edges: const []),
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('corrupted rows are skipped as NAMED data, never guessed', () {
    final result = deconstructKnowledgePack({
      'rows': [
        {'kind': 'op'}, // missing id
        'not-an-object', // not a row at all
        {'kind': 'intent', 'id': 'i.broken', 'label': 'no chain'}, // contract-only
        {'kind': 'op', 'id': 'ok.1', 'label': 'eq', 'a': 'r'}, // survives
      ],
    });
    expect(result.tree.nodes.map((n) => n.id), ['ok.1']);
    expect(result.tree.meta['rows'], 1);
    expect(result.tree.meta['skipped'], 3);
    expect(result.skipped.length, 3);
    // every skip is NAMED: a reason, plus index/id when applicable
    for (final s in result.skipped) {
      expect((s['reason'] as String).isNotEmpty, isTrue);
    }
    expect(result.skipped[0]['reason'], 'row missing kind or id');
    expect(result.skipped[1]['reason'], 'row is not an object');
    expect(result.skipped[2]['id'], 'i.broken');
    expect(result.skipped[2]['reason'], contains('contract-only'));
  });

  test('dangling edge targets are skipped as named data, node survives', () {
    final result = deconstructKnowledgePack({
      'rows': [
        {'kind': 'intent', 'id': 'i.1', 'label': 'put', 'chain': ['op.missing', 'op.2']},
        {'kind': 'op', 'id': 'op.2', 'label': 'return'},
      ],
    });
    expect(result.tree.nodes.map((n) => n.id), containsAll(['i.1', 'op.2']));
    expect(result.skipped, [
      {
        'row': 'i.1',
        'relation': 'impl',
        'target': 'op.missing',
        'reason': 'dangling target: no such row id',
      },
    ]);
  });

  test('ambiguous shapes fail loudly on construct', () {
    // two impl edges from one intent
    expect(
      () => constructKnowledgePack(
        MeaningTreeExport(
          nodes: const [
            ExportNode(id: 'i.1', kind: 'intent', label: 'i'),
            ExportNode(id: 'op.1', kind: 'op', label: 'a'),
            ExportNode(id: 'op.2', kind: 'op', label: 'b'),
          ],
          edges: const [
            ExportEdge(from: 'i.1', relation: 'impl', to: 'op.1'),
            ExportEdge(from: 'i.1', relation: 'impl', to: 'op.2'),
          ],
        ),
      ),
      throwsA(isA<StateError>()),
    );
    // then-chain fan-out
    expect(
      () => constructKnowledgePack(
        MeaningTreeExport(
          nodes: const [
            ExportNode(id: 'i.1', kind: 'intent', label: 'i'),
            ExportNode(id: 'op.1', kind: 'op', label: 'a'),
            ExportNode(id: 'op.2', kind: 'op', label: 'b'),
            ExportNode(id: 'op.3', kind: 'op', label: 'c'),
          ],
          edges: const [
            ExportEdge(from: 'i.1', relation: 'impl', to: 'op.1'),
            ExportEdge(from: 'op.1', relation: 'then', to: 'op.2'),
            ExportEdge(from: 'op.1', relation: 'then', to: 'op.3'),
          ],
        ),
      ),
      throwsA(isA<StateError>()),
    );
    // section with two parents
    expect(
      () => constructKnowledgePack(
        MeaningTreeExport(
          nodes: const [
            ExportNode(id: 's.root', kind: 'section', label: 'r'),
            ExportNode(id: 's.root2', kind: 'section', label: 'r2'),
            ExportNode(id: 's.leaf', kind: 'section', label: 'l'),
          ],
          edges: const [
            ExportEdge(from: 's.root', relation: 'contains', to: 's.leaf'),
            ExportEdge(from: 's.root2', relation: 'contains', to: 's.leaf'),
          ],
        ),
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('export JSON round-trips through toMap/fromMap (knowledge path)', () {
    final export = deconstructKnowledgePack(_fixturePack()).tree;
    final restored = MeaningTreeExport.fromMap(export.toMap());
    expect(_digest(restored), _digest(export));
    expect(restored.toMap()['schema'], 'ae.meaning_tree_export.v1');
  });
}
