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
library;

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
