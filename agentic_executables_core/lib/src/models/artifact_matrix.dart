import 'dart:convert';

import 'feature_id.dart';

const String artifactMatrixSchema = 'ae.artifact_matrix.v1';

enum ImplStatus {
  done('done'),
  partial('partial'),
  missing('missing'),
  planned('planned'),
  nA('n_a'),
  deviates('deviates');

  const ImplStatus(this.value);
  final String value;

  static ImplStatus fromString(final String value) => switch (value) {
        'done' => ImplStatus.done,
        'partial' => ImplStatus.partial,
        'missing' => ImplStatus.missing,
        'planned' => ImplStatus.planned,
        'n_a' => ImplStatus.nA,
        'deviates' => ImplStatus.deviates,
        _ => throw ArgumentError('Invalid impl status: $value'),
      };
}

enum TestStatus {
  yes('yes'),
  no('no'),
  partial('partial');

  const TestStatus(this.value);
  final String value;

  static TestStatus fromString(final String value) => switch (value) {
        'yes' => TestStatus.yes,
        'no' => TestStatus.no,
        'partial' => TestStatus.partial,
        _ => throw ArgumentError('Invalid test status: $value'),
      };
}

class ArtifactColumn {
  const ArtifactColumn({
    required this.id,
    required this.type,
    this.values,
  });

  final String id;
  final String type;
  final List<String>? values;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        if (values != null) 'values': values,
      };

  factory ArtifactColumn.fromMap(final Map<dynamic, dynamic> map) {
    final valsRaw = map['values'];
    final vals = valsRaw is List
        ? valsRaw.map((final v) => v.toString()).toList(growable: false)
        : null;
    return ArtifactColumn(
      id: map['id']?.toString() ?? '',
      type: map['type']?.toString() ?? 'text',
      values: vals,
    );
  }
}

class ArtifactCell {
  const ArtifactCell({
    required this.impl,
    this.algorithm,
    this.location,
    this.tests,
    this.notes,
    this.evidenceCommand,
  });

  final ImplStatus impl;
  final String? algorithm;
  final String? location;
  final TestStatus? tests;
  final String? notes;

  /// Command that, when run, produces the recorded test evidence. Written by
  /// `ae artifact mark-evidence`; executed (not trusted) by
  /// `ae artifact verify --run-tests`. Empty on legacy rows.
  final String? evidenceCommand;

  Map<String, dynamic> toJson() => {
        'impl': impl.value,
        if (algorithm != null) 'algorithm': algorithm,
        if (location != null) 'location': location,
        if (tests != null) 'tests': tests!.value,
        if (notes != null) 'notes': notes,
        if (evidenceCommand != null) 'evidence_command': evidenceCommand,
      };

  factory ArtifactCell.fromMap(final Map<dynamic, dynamic> map) => ArtifactCell(
        impl: ImplStatus.fromString(map['impl']?.toString() ?? 'missing'),
        algorithm: map['algorithm']?.toString(),
        location: map['location']?.toString(),
        tests: map['tests'] != null
            ? TestStatus.fromString(map['tests'].toString())
            : null,
        notes: map['notes']?.toString(),
        evidenceCommand: map['evidence_command']?.toString(),
      );
}

class ArtifactFeatureRow {
  const ArtifactFeatureRow({
    required this.id,
    required this.canonical,
    required this.cell,
  });

  final FeatureId id;
  final String canonical;
  final ArtifactCell cell;

  Map<String, dynamic> toJson() => {
        'id': id.toString(),
        'canonical': canonical,
        ...cell.toJson(),
      };

  factory ArtifactFeatureRow.fromMap(final Map<dynamic, dynamic> map) {
    final id = FeatureId.parse(map['id']?.toString() ?? '');
    final canonical = map['canonical']?.toString() ?? '';
    return ArtifactFeatureRow(
      id: id,
      canonical: canonical,
      cell: ArtifactCell.fromMap(map),
    );
  }
}

class ArtifactMatrix {
  const ArtifactMatrix({
    required this.columnSchema,
    required this.features,
  });

  final List<ArtifactColumn> columnSchema;
  final List<ArtifactFeatureRow> features;

  Map<String, dynamic> toJson() => {
        'schema': artifactMatrixSchema,
        'column_schema':
            columnSchema.map((final c) => c.toJson()).toList(growable: false),
        'features':
            features.map((final f) => f.toJson()).toList(growable: false),
      };

  String toYamlString() {
    final buffer = StringBuffer()..writeln('schema: $artifactMatrixSchema');
    buffer.writeln('column_schema:');
    for (final c in columnSchema) {
      final vals = c.values;
      if (vals == null) {
        buffer.writeln('  - { id: ${c.id}, type: ${c.type} }');
      } else {
        buffer.writeln(
          '  - { id: ${c.id}, type: ${c.type}, values: [${vals.join(", ")}] }',
        );
      }
    }
    buffer.writeln('features:');
    for (final f in features) {
      buffer
        ..writeln('  - id: ${f.id}')
        ..writeln('    canonical: ${f.canonical}')
        ..writeln('    impl: ${f.cell.impl.value}');
      if (f.cell.algorithm != null) {
        buffer.writeln('    algorithm: ${_y(f.cell.algorithm!)}');
      }
      if (f.cell.location != null) {
        buffer.writeln('    location: ${_y(f.cell.location!)}');
      }
      if (f.cell.tests != null) {
        buffer.writeln('    tests: ${f.cell.tests!.value}');
      }
      if (f.cell.notes != null) {
        buffer.writeln('    notes: ${_y(f.cell.notes!)}');
      }
      if (f.cell.evidenceCommand != null) {
        buffer.writeln('    evidence_command: ${_y(f.cell.evidenceCommand!)}');
      }
    }
    return buffer.toString();
  }

  factory ArtifactMatrix.fromMap(final Map<dynamic, dynamic> map) {
    final schema = map['schema']?.toString();
    if (schema != artifactMatrixSchema) {
      throw ArgumentError(
        'Expected schema $artifactMatrixSchema, got $schema',
      );
    }
    final colsRaw = map['column_schema'];
    final cols = colsRaw is List
        ? colsRaw
            .whereType<Map>()
            .map(ArtifactColumn.fromMap)
            .toList(growable: false)
        : <ArtifactColumn>[];
    final featsRaw = map['features'];
    final feats = featsRaw is List
        ? featsRaw
            .whereType<Map>()
            .map(ArtifactFeatureRow.fromMap)
            .toList(growable: false)
        : <ArtifactFeatureRow>[];
    return ArtifactMatrix(columnSchema: cols, features: feats);
  }
}

String _y(final String s) {
  // Always quote empty strings.
  if (s.isEmpty) return '""';
  // Plain scalars: safe identifier-like strings the YAML loader will parse
  // back as a string (not a bool/null/number/timestamp keyword).
  final plainPattern = RegExp(r'^[A-Za-z_][A-Za-z0-9_./@:-]*$');
  const reservedWords = {
    'true',
    'false',
    'null',
    'yes',
    'no',
    'on',
    'off',
    '~',
    'True',
    'False',
    'Null',
    'Yes',
    'No',
    'On',
    'Off',
    'TRUE',
    'FALSE',
    'NULL',
    'YES',
    'NO',
    'ON',
    'OFF',
  };
  if (plainPattern.hasMatch(s) &&
      !reservedWords.contains(s) &&
      // Avoid plain scalars that look like numbers / timestamps.
      double.tryParse(s) == null &&
      DateTime.tryParse(s) == null &&
      // Avoid `:` inside the value, which could be parsed as a flow key.
      !s.contains(':')) {
    return s;
  }
  // Otherwise emit a JSON-encoded double-quoted YAML scalar.
  return jsonEncode(s);
}
