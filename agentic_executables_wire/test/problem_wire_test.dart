import 'dart:convert';

import 'package:agentic_executables_wire/agentic_executables_wire.dart';
import 'package:test/test.dart';

void main() {
  test('problem row round-trips and carries the canonical class id', () {
    final row = ProblemRowWire(
      classId: 'dart/unused_import',
      severity: 'warning',
      filePath: 'lib/a.dart',
      line: 32,
      column: 8,
      message: "Unused import: 'x.dart'.",
      source: 'dart_analyzer',
    );
    final back = ProblemRowWire.fromJson(
      jsonDecode(jsonEncode(row.toJson())) as Map<String, Object?>,
    );
    expect(back.classId, 'dart/unused_import');
    expect(back.line, 32);
  });

  test('repair pack: exact-match lookup, miss returns null', () {
    final pack = RepairPackWire.fromJson({
      'packId': 'harness',
      'executables': [
        {
          'executableId': 'harness/delete-line/1',
          'classId': 'dart/unused_import',
          'kind': 'delete_line',
        },
      ],
    });
    expect(pack.forClass('dart/unused_import')?.kind, 'delete_line');
    expect(pack.forClass('dart/other'), isNull);
  });

  test('command executables carry project-defined argv (no shell)', () {
    final e = RepairExecutableWire.fromJson({
      'executableId': 'p/cmd/1',
      'classId': 'mylint/dead_code',
      'kind': 'command',
      'command': ['tools/fix_dead_code', '--file', '{span.file}'],
    });
    expect(e.command, ['tools/fix_dead_code', '--file', '{span.file}']);
    expect(e.toJson()['command'], isA<List<dynamic>>());
  });
}
