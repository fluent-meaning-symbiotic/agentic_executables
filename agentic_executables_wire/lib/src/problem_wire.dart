// ignore_for_file: lines_longer_than_80_chars

/// Problem wire — the third cross-repo contract (ADR 0021).
///
/// Analyzer/linter diagnostics are an AE-ETL raw source: heuristic
/// extractors (one per tool output format) canonicalize them into
/// [ProblemRowWire] rows; the project's repair pack maps class ids to
/// [RepairExecutableWire] entries. AE owns the semantics (canonical matrix,
/// tiered verification); hosts (harness, CLI, MCP) consume the shapes
/// without embedding AE.
///
/// Layering rule (ADR 0021 §2): format adapters are generic and syntax-only
/// — they know nothing about repairs. Repair packs are PROJECT-GUIDED: the
/// same diagnostic code can warrant different repairs in different
/// projects, and custom linters emit custom class ids that only the
/// project's pack can map. The model never chooses the executable.
library;

/// One canonical problem row — the ETL output over raw diagnostics.
class ProblemRowWire {
  const ProblemRowWire({
    required this.classId,
    required this.severity,
    required this.filePath,
    required this.line,
    required this.column,
    required this.message,
    required this.source,
    this.endLine,
    this.endColumn,
  });

  factory ProblemRowWire.fromJson(Map<String, Object?> json) =>
      ProblemRowWire(
        classId: json['classId'] as String? ?? '',
        severity: json['severity'] as String? ?? 'info',
        filePath: json['filePath'] as String? ?? '',
        line: json['line'] as int? ?? 0,
        column: json['column'] as int? ?? 0,
        message: json['message'] as String? ?? '',
        source: json['source'] as String? ?? '',
        endLine: json['endLine'] as int?,
        endColumn: json['endColumn'] as int?,
      );

  /// Canonical class id — the join key to repair packs. Convention:
  /// `<language-or-tool>/<class>`, e.g. `dart/unused_import`,
  /// `mycustomlint/dead_code`. Custom linters emit custom ids; only the
  /// project's pack can map them.
  final String classId;

  /// Raw severity as the source reported it (`error|warning|info`). Gating
  /// (which severities become work) is host policy, not wire semantics.
  final String severity;

  /// Project-relative file path.
  final String filePath;
  final int line;
  final int column;

  /// Raw evidence — the source's own message. Never a repair instruction.
  final String message;

  /// The raw producer (`dart_analyzer`, `kotlin_lint`, ...).
  final String source;

  /// Optional span end when the source reports one.
  final int? endLine;
  final int? endColumn;

  Map<String, Object?> toJson() => {
    'classId': classId,
    'severity': severity,
    'filePath': filePath,
    'line': line,
    'column': column,
    'message': message,
    'source': source,
    if (endLine != null) 'endLine': endLine,
    if (endColumn != null) 'endColumn': endColumn,
  };
}

/// A project-guided repair executable: what the project says should happen
/// for a canonical problem class. Deterministic only — argv commands without
/// a shell, or span transforms. The ORACLE (source analyzer re-run) decides
/// whether the repair actually closed the problem; failure reverts.
class RepairExecutableWire {
  const RepairExecutableWire({
    required this.executableId,
    required this.classId,
    required this.kind,
    this.replacement,
    this.command,
  });

  factory RepairExecutableWire.fromJson(Map<String, Object?> json) =>
      RepairExecutableWire(
        executableId: json['executableId'] as String? ?? '',
        classId: json['classId'] as String? ?? '',
        kind: json['kind'] as String? ?? '',
        replacement: json['replacement'] as String?,
        command: (json['command'] as List<Object?>?)
            ?.whereType<String>()
            .toList(),
      );

  /// Pack-qualified id (for audit trails).
  final String executableId;

  /// Canonical class id this executable repairs (exact match).
  final String classId;

  /// `delete_line` | `delete_span` | `replace_span` | `command`.
  final String kind;

  /// `replace_span` replacement text.
  final String? replacement;

  /// `command` argv — project-defined, executed WITHOUT a shell. The
  /// project is the trust boundary; the model never supplies or alters it.
  final List<String>? command;

  Map<String, Object?> toJson() => {
    'executableId': executableId,
    'classId': classId,
    'kind': kind,
    if (replacement != null) 'replacement': replacement,
    if (command != null) 'command': command,
  };
}

/// A project's repair pack: the durable "resolvable once" record. When a
/// novel problem class is resolved (meaningful tier or operator), the
/// resolution is captured here and the class is automated forever.
class RepairPackWire {
  const RepairPackWire({required this.packId, required this.executables});

  factory RepairPackWire.fromJson(Map<String, Object?> json) =>
      RepairPackWire(
        packId: json['packId'] as String? ?? '',
        executables: (json['executables'] as List<Object?>? ?? [])
            .whereType<Map<String, Object?>>()
            .map(RepairExecutableWire.fromJson)
            .toList(),
      );

  final String packId;
  final List<RepairExecutableWire> executables;

  /// Exact-match lookup by canonical class id. v1 is exact; family/prefix
  /// matching is a later, pack-owned extension.
  RepairExecutableWire? forClass(String classId) {
    for (final e in executables) {
      if (e.classId == classId) return e;
    }
    return null;
  }

  Map<String, Object?> toJson() => {
    'packId': packId,
    'executables': [for (final e in executables) e.toJson()],
  };
}
