// ignore_for_file: lines_longer_than_80_chars

/// Canonical → meaning-tree export (PLAN Stage G2).
///
/// Converts an AE canonical pack (`ae.canonical.v3`) or standalone matrix
/// (`ae.canonical_matrix.v1`) into the nodes/edges/props shape an ECS-world
/// agent host uses as world state. The conversion is DETERMINISTIC and
/// LLM-free: feature ids like `entity.create` already encode hierarchy, so
/// the export is pure structural derivation — the canonical pack is the
/// *meaning tree at rest*; the host world is the *meaning tree in motion*.
///
/// Node kinds:
/// - `concept` — one per id path segment (`entity` from `entity.create`).
/// - `feature` — one per canonical feature row; props carry the row's cells.
/// Edge kind: `contains` from parent concept → child.
///
/// Knowledge plane (harness Directions item 3): a second envelope,
/// `ae.knowledge_pack.v1`, carries knowledge-at-rest rows exactly as a
/// harness world holds them — intents with impl/then op chains, plan steps
/// with depends_on/goal links, goals, sections, specs, features. The
/// deconstruct/construct pair proves the round-trip: harness meaning
/// populations → canonical pack → tree nodes → back, zero loss. The wire
/// owns SYNTAX only: it fails loudly on unknown kinds and keeps corrupted
/// rows as NAMED data — semantics stay with AE, hosts realize.
library;

import 'dart:convert';

/// One exported meaning node.
class ExportNode {
  const ExportNode({
    required this.id,
    required this.kind,
    required this.label,
    this.props = const {},
  });

  final String id;
  final String kind;
  final String label;
  final Map<String, dynamic> props;

  Map<String, dynamic> toMap() => {
    'id': id,
    'kind': kind,
    'label': label,
    'props': props,
  };

  factory ExportNode.fromMap(Map<dynamic, dynamic> map) => ExportNode(
    id: map['id']?.toString() ?? '',
    kind: map['kind']?.toString() ?? 'concept',
    label: map['label']?.toString() ?? '',
    props: ((map['props'] as Map?) ?? const {}).cast<String, dynamic>(),
  );
}

/// One exported meaning edge: `from` —[relation]→ `to` (stable node ids).
class ExportEdge {
  const ExportEdge({required this.from, required this.relation, required this.to});
  final String from;
  final String relation;
  final String to;

  Map<String, dynamic> toMap() => {'from': from, 'relation': relation, 'to': to};

  factory ExportEdge.fromMap(Map<dynamic, dynamic> map) => ExportEdge(
    from: map['from']?.toString() ?? '',
    relation: map['relation']?.toString() ?? 'contains',
    to: map['to']?.toString() ?? '',
  );
}

/// The meaning-tree export of a canonical pack: nodes + edges with stable
/// ids that round-trip into any host's world state.
class MeaningTreeExport {
  const MeaningTreeExport({required this.nodes, required this.edges, this.meta = const {}});

  final List<ExportNode> nodes;
  final List<ExportEdge> edges;

  /// Concept/version provenance from the pack (informational).
  final Map<String, dynamic> meta;

  factory MeaningTreeExport.fromMap(Map<dynamic, dynamic> map) => MeaningTreeExport(
    nodes: [
      for (final n in (map['nodes'] as List? ?? const []))
        if (n is Map) ExportNode.fromMap(n),
    ],
    edges: [
      for (final e in (map['edges'] as List? ?? const []))
        if (e is Map) ExportEdge.fromMap(e),
    ],
    meta: ((map['meta'] as Map?) ?? const {}).cast<String, dynamic>(),
  );

  Map<String, dynamic> toMap() => {
    'schema': 'ae.meaning_tree_export.v1',
    'meta': meta,
    'nodes': [for (final n in nodes) n.toMap()],
    'edges': [for (final e in edges) e.toMap()],
  };
}

/// Converts a canonical pack / canonical-matrix JSON [map] into a
/// [MeaningTreeExport].
///
/// Deterministic derivation:
/// - concept nodes per id path segment (first-seen order);
/// - feature node per row, id = feature id, kind = `feature`, label = id,
///   props = row cells;
/// - `contains` edges parent → child along each id path.
MeaningTreeExport canonicalToMeaningTree(Map<dynamic, dynamic> map) {
  final matrix = map['matrix'] is Map ? map['matrix'] as Map : map;
  final concept = (matrix['concept'] ?? map['meta']?['concept'])?.toString() ?? '';
  final version = matrix['version'];

  final nodes = <ExportNode>[];
  final edges = <ExportEdge>[];
  final seenConcepts = <String>{};

  void conceptPath(String featureId) {
    final segments = featureId.split('.');
    var path = '';
    for (var i = 0; i < segments.length - 1; i++) {
      path = path.isEmpty ? segments[i] : '$path.${segments[i]}';
      if (seenConcepts.add(path)) {
        nodes.add(
          ExportNode(
            id: path,
            kind: 'concept',
            label: segments[i],
            props: i == 0 && concept.isNotEmpty
                ? {'concept': concept, if (version != null) 'version': version}
                : const {},
          ),
        );
      }
      final parent = path.contains('.') ? path.substring(0, path.lastIndexOf('.')) : '';
      if (parent.isNotEmpty) {
        edges.add(ExportEdge(from: parent, relation: 'contains', to: path));
      }
    }
  }

  final features = <Map<dynamic, dynamic>>[
    for (final f in (matrix['features'] as List? ?? const []))
      if (f is Map) f,
  ]..sort((a, b) => (a['id']?.toString() ?? '').compareTo(b['id']?.toString() ?? ''));

  for (final feature in features) {
    final id = feature['id']?.toString() ?? '';
    if (id.isEmpty) continue;
    conceptPath(id);
    final props = <String, dynamic>{
      for (final entry in feature.entries)
        if (entry.key.toString() != 'id') entry.key.toString(): entry.value,
    };
    nodes.add(ExportNode(id: id, kind: 'feature', label: id, props: props));
    final parent = id.contains('.') ? id.substring(0, id.lastIndexOf('.')) : '';
    if (parent.isNotEmpty) {
      edges.add(ExportEdge(from: parent, relation: 'contains', to: id));
    }
  }

  return MeaningTreeExport(
    nodes: nodes,
    edges: edges,
    meta: {
      if (concept.isNotEmpty) 'concept': concept,
      if (version != null) 'version': version,
      'features': features.length,
    },
  );
}

/// Envelope schema for the knowledge-at-rest pack (harness Directions item 3).
const knowledgePackSchema = 'ae.knowledge_pack.v1';

/// Row kinds a harness world carries for knowledge at rest. Any other kind
/// is an unknown shape: the wire fails loudly (AE rule), never guesses.
const knownKnowledgeKinds = <String>{
  'intent', // op-chain program: impl → first op, then → chain
  'op', // spec row: label + props a/b; jump targets '#row' (a prop)
  'step', // plan projection node (ADR 0009)
  'goal', // goal a step links to (GoalLink)
  'section', // md/spec section node (span anchor)
  'spec', // materializer/behavior spec node
  'feature', // canonical feature row (same kind as ae.canonical.v3)
};

/// Row keys folded into node fields/edges (never duplicated into props).
/// Extra cells live under `props` (canonical shape); flat extras (legacy
/// ae.canonical.v3 feature shape) are accepted — but never both.
const _reservedRowKeys = <String>{
  'id', 'kind', 'label', 'props', 'chain', 'depends_on', 'goal', 'parent',
};

/// Extracts a row's props: the `props` map, or flat extras — mixing both
/// is an ambiguous shape and throws (callers decide: loud or named skip).
Map<String, dynamic> _rowProps(Map<dynamic, dynamic> raw) {
  final propsMap = raw['props'];
  final flat = <String, dynamic>{
    for (final e in raw.entries)
      if (!_reservedRowKeys.contains(e.key.toString()))
        e.key.toString(): e.value,
  };
  if (propsMap != null && flat.isNotEmpty) {
    throw StateError(
      'ae wire: row "${raw['id']}" mixes a props map and flat cells '
      '— ambiguous shape, never guessed',
    );
  }
  if (propsMap == null) return flat;
  return {
    for (final e in (propsMap as Map).entries) e.key.toString(): e.value,
  };
}

/// One canonical knowledge-at-rest row.
class KnowledgeRow {
  const KnowledgeRow({
    required this.kind,
    required this.id,
    this.label = '',
    this.props = const {},
    this.chain = const [],
    this.dependsOn = const [],
    this.goal,
    this.parent,
  });

  final String kind;
  final String id;
  final String label;
  final Map<String, dynamic> props;

  /// intent only: op-chain ids; deconstruct wires `impl` (→ chain.first)
  /// and `then` (chain[i] → chain[i+1]) edges.
  final List<String> chain;

  /// step only: DependsOnStep target ids.
  final List<String> dependsOn;

  /// step only: GoalLink target id.
  final String? goal;

  /// section only: parent section id (`contains` edge parent → this).
  final String? parent;

  factory KnowledgeRow.fromMap(Map<dynamic, dynamic> map) => KnowledgeRow(
    kind: map['kind']?.toString() ?? '',
    id: map['id']?.toString() ?? '',
    label: map['label']?.toString() ?? '',
    props: _rowProps(map),
    chain: [for (final c in (map['chain'] as List? ?? const [])) c.toString()],
    dependsOn: [
      for (final d in (map['depends_on'] as List? ?? const [])) d.toString(),
    ],
    goal: map['goal']?.toString(),
    parent: map['parent']?.toString(),
  );

  /// Canonical row form: `props` is a DEDICATED row field — structural
  /// keys (kind/id/label + the relation fields below) never collide with
  /// data cells. Legacy flat extras are accepted on read (_rowProps) but
  /// never emitted. The canonical byte form sorts keys (see
  /// canonicalKnowledgeForm).
  Map<String, dynamic> toMap() => {
    'kind': kind,
    'id': id,
    'label': label,
    if (props.isNotEmpty) 'props': props,
    if (chain.isNotEmpty) 'chain': chain,
    if (dependsOn.isNotEmpty) 'depends_on': dependsOn,
    if (goal != null) 'goal': goal,
    if (parent != null) 'parent': parent,
  };
}

/// Result of deconstructing a knowledge pack into tree nodes.
class KnowledgeDeconstruction {
  const KnowledgeDeconstruction({required this.tree, required this.skipped});

  final MeaningTreeExport tree;

  /// Rows/edges that could not be converted, kept as NAMED data (never
  /// guessed): each entry names the offending row/index and a reason.
  final List<Map<String, dynamic>> skipped;
}

/// Result of constructing a canonical knowledge pack from tree nodes.
class KnowledgeConstruction {
  const KnowledgeConstruction({required this.pack, required this.skipped});

  final Map<String, dynamic> pack;

  /// Nodes/edges that could not be converted, kept as NAMED data.
  final List<Map<String, dynamic>> skipped;
}

/// Deconstructs a `ae.knowledge_pack.v1` [pack] into a [MeaningTreeExport]:
/// pack in → tree nodes out.
///
/// Deterministic and LLM-free:
/// - one node per row; row kind → node kind verbatim (no concept-path
///   derivation — knowledge rows carry their own explicit kinds);
/// - intent rows → `impl` + `then` edges along the op chain;
/// - step rows → `depends_on` edges + a `goal` edge (GoalLink);
/// - section rows → `contains` edge from the declared parent;
/// - everything else on a row travels as node props verbatim.
///
/// Unknown kinds THROW (fail loudly on unknown shapes). Corrupted rows
/// (missing kind/id, non-object rows, contract-only intents, dangling edge
/// targets) are skipped and returned as named data in `skipped`.
KnowledgeDeconstruction deconstructKnowledgePack(Map<dynamic, dynamic> pack) {
  final concept = pack['concept']?.toString() ?? '';
  final version = pack['version'];
  final rawRows = pack['rows'] as List? ?? const [];

  final knownIds = <String>{
    for (final raw in rawRows)
      if (raw is Map && (raw['id']?.toString() ?? '').isNotEmpty)
        raw['id'].toString(),
  };

  final nodes = <ExportNode>[];
  final edges = <ExportEdge>[];
  final edgeKeys = <String>{};
  final skipped = <Map<String, dynamic>>[];

  void emitEdge(String from, String relation, String to, String rowId) {
    if (!knownIds.contains(to)) {
      skipped.add({
        'row': rowId,
        'relation': relation,
        'target': to,
        'reason': 'dangling target: no such row id',
      });
      return;
    }
    if (edgeKeys.add('$from|$relation|$to')) {
      edges.add(ExportEdge(from: from, relation: relation, to: to));
    }
  }

  for (var i = 0; i < rawRows.length; i++) {
    final raw = rawRows[i];
    if (raw is! Map) {
      skipped.add({'index': i, 'reason': 'row is not an object'});
      continue;
    }
    final kind = raw['kind']?.toString() ?? '';
    final id = raw['id']?.toString() ?? '';
    if (kind.isEmpty || id.isEmpty) {
      skipped.add({
        'index': i,
        'kind': kind,
        'id': id,
        'reason': 'row missing kind or id',
      });
      continue;
    }
    if (!knownKnowledgeKinds.contains(kind)) {
      throw StateError(
        'ae wire: unknown knowledge row kind "$kind" (row "$id") '
        '— fail loudly on unknown shapes',
      );
    }
    final chain = [
      for (final c in (raw['chain'] as List? ?? const [])) c.toString(),
    ];
    if (kind == 'intent' && chain.isEmpty) {
      skipped.add({
        'index': i,
        'kind': kind,
        'id': id,
        'reason':
            'intent without op chain '
            '(contract-only intents are deleted, never guessed)',
      });
      continue;
    }
    final Map<String, dynamic> rowProps;
    try {
      rowProps = _rowProps(raw);
    } on StateError catch (e) {
      skipped.add({'index': i, 'kind': kind, 'id': id, 'reason': e.message});
      continue;
    }
    if (kind == 'intent') {
      emitEdge(id, 'impl', chain.first, id);
      for (var j = 0; j + 1 < chain.length; j++) {
        emitEdge(chain[j], 'then', chain[j + 1], id);
      }
    }
    if (kind == 'section') {
      final parent = raw['parent']?.toString() ?? '';
      if (parent.isNotEmpty) emitEdge(parent, 'contains', id, id);
    }
    if (kind == 'step') {
      for (final d in (raw['depends_on'] as List? ?? const [])) {
        emitEdge(id, 'depends_on', d.toString(), id);
      }
      final goal = raw['goal']?.toString() ?? '';
      if (goal.isNotEmpty) emitEdge(id, 'goal', goal, id);
    }
    nodes.add(
      ExportNode(
        id: id,
        kind: kind,
        label: raw['label']?.toString() ?? '',
        props: rowProps,
      ),
    );
  }

  return KnowledgeDeconstruction(
    tree: MeaningTreeExport(
      nodes: nodes,
      edges: edges,
      meta: {
        if (concept.isNotEmpty) 'concept': concept,
        if (version != null) 'version': version,
        'rows': nodes.length,
        'skipped': skipped.length,
      },
    ),
    skipped: skipped,
  );
}

/// Constructs a canonical `ae.knowledge_pack.v1` from tree nodes: tree
/// nodes → canonical rows.
///
/// Deterministic canonical form: rows sorted by (kind, id), prop keys
/// sorted, relation edges (impl/then, depends_on/goal, contains) folded
/// back into row fields. Ambiguous shapes (multiple impl/goal/parent
/// edges, then-chain fan-out or cycles) THROW; unknown node kinds THROW;
/// corrupted nodes and foreign relations are skipped as named data.
KnowledgeConstruction constructKnowledgePack(MeaningTreeExport tree) {
  final skipped = <Map<String, dynamic>>[];

  final implFrom = <String, List<String>>{};
  final thenFrom = <String, List<String>>{};
  final dependsFrom = <String, List<String>>{};
  final goalFrom = <String, List<String>>{};
  final containsTo = <String, List<String>>{};

  for (final e in tree.edges) {
    switch (e.relation) {
      case 'impl':
        implFrom.putIfAbsent(e.from, () => []).add(e.to);
      case 'then':
        thenFrom.putIfAbsent(e.from, () => []).add(e.to);
      case 'depends_on':
        dependsFrom.putIfAbsent(e.from, () => []).add(e.to);
      case 'goal':
        goalFrom.putIfAbsent(e.from, () => []).add(e.to);
      case 'contains':
        containsTo.putIfAbsent(e.to, () => []).add(e.from);
      default:
        skipped.add({
          'edge': '${e.from}→${e.to}',
          'relation': e.relation,
          'reason': 'relation not part of the knowledge canonical form',
        });
    }
  }

  List<String> sorted(List<String> source) => List.of(source)..sort();

  final rows = <Map<String, dynamic>>[];
  for (var i = 0; i < tree.nodes.length; i++) {
    final node = tree.nodes[i];
    if (node.kind == 'concept') continue; // derived, never a row
    if (!knownKnowledgeKinds.contains(node.kind)) {
      throw StateError(
        'ae wire: unknown knowledge node kind "${node.kind}" '
        '(node "${node.id}") — fail loudly on unknown shapes',
      );
    }
    if (node.id.isEmpty) {
      skipped.add({'index': i, 'reason': 'node missing id'});
      continue;
    }
    final props = <String, dynamic>{
      for (final k in node.props.keys.toList()..sort()) k: node.props[k],
    };
    switch (node.kind) {
      case 'intent':
        final impls = sorted(implFrom[node.id] ?? const []);
        if (impls.length > 1) {
          throw StateError(
            'ae wire: ambiguous impl edge for intent "${node.id}"',
          );
        }
        if (impls.isEmpty) {
          skipped.add({
            'id': node.id,
            'kind': 'intent',
            'reason': 'intent without impl edge',
          });
          continue;
        }
        final chain = <String>[impls.first];
        final visited = <String>{impls.first};
        var cursor = impls.first;
        while ((thenFrom[cursor] ?? const []).isNotEmpty) {
          final nexts = sorted(thenFrom[cursor] ?? const []);
          if (nexts.length > 1) {
            throw StateError(
              'ae wire: ambiguous then-chain at op "$cursor" '
              '(intent "${node.id}")',
            );
          }
          cursor = nexts.first;
          if (!visited.add(cursor)) {
            throw StateError(
              'ae wire: cycle in then-chain at op "$cursor" '
              '(intent "${node.id}")',
            );
          }
          chain.add(cursor);
        }
        rows.add(
          KnowledgeRow(
            kind: 'intent',
            id: node.id,
            label: node.label,
            props: props,
            chain: chain,
          ).toMap(),
        );
      case 'step':
        final goals = sorted(goalFrom[node.id] ?? const []);
        if (goals.length > 1) {
          throw StateError(
            'ae wire: ambiguous goal link for step "${node.id}"',
          );
        }
        rows.add(
          KnowledgeRow(
            kind: 'step',
            id: node.id,
            label: node.label,
            props: props,
            dependsOn: sorted(dependsFrom[node.id] ?? const []),
            goal: goals.isEmpty ? null : goals.first,
          ).toMap(),
        );
      case 'section':
        final parents = sorted(containsTo[node.id] ?? const []);
        if (parents.length > 1) {
          throw StateError(
            'ae wire: section "${node.id}" has ${parents.length} parents '
            '— ambiguous hierarchy',
          );
        }
        rows.add(
          KnowledgeRow(
            kind: 'section',
            id: node.id,
            label: node.label,
            props: props,
            parent: parents.isEmpty ? null : parents.first,
          ).toMap(),
        );
      default:
        rows.add(
          KnowledgeRow(
            kind: node.kind,
            id: node.id,
            label: node.label,
            props: props,
          ).toMap(),
        );
    }
  }

  rows.sort((a, b) {
    final byKind = (a['kind'] as String).compareTo(b['kind'] as String);
    if (byKind != 0) return byKind;
    return (a['id'] as String).compareTo(b['id'] as String);
  });

  return KnowledgeConstruction(
    pack: {
      'schema': knowledgePackSchema,
      if (tree.meta['concept'] != null) 'concept': tree.meta['concept'],
      if (tree.meta['version'] != null) 'version': tree.meta['version'],
      'rows': rows,
    },
    skipped: skipped,
  );
}

/// Deterministic canonical form of any JSON tree: recursively key-sorted
/// JSON. Same input → byte-identical output, always. The knowledge pack
/// ([canonicalKnowledgeForm]) and the hub manifest
/// ([canonicalHubManifestForm]) are the two canonical forms built on this.
String canonicalJsonForm(Map<dynamic, dynamic> value) =>
    jsonEncode(_canonicalValue(value));

/// Deterministic canonical form of a knowledge pack: recursively key-sorted
/// JSON. Same input → byte-identical output, always.
String canonicalKnowledgeForm(Map<dynamic, dynamic> pack) =>
    canonicalJsonForm(pack);

dynamic _canonicalValue(dynamic value) {
  if (value is Map) {
    final keys = value.keys.map((k) => k.toString()).toList()..sort();
    return {for (final k in keys) k: _canonicalValue(value[k])};
  }
  if (value is List) return [for (final v in value) _canonicalValue(v)];
  return value;
}
