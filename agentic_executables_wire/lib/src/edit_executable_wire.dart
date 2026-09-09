// ignore_for_file: lines_longer_than_80_chars

/// Edit executable wire — the fourth cross-repo contract (ADR 0023 §3).
///
/// Edit executables are PROJECT/PACK-DECLARED, parameterized edit moves:
/// know packs (standards/docs → AE ETL) and project repair packs (the ADR
/// 0021 capture loop) supply them as data. The model picks an executable
/// id and fills bounded slots; it NEVER authors patches. The host
/// materializes span-anchored patches from the meaning tree (file+line per
/// symbol) and verifies mechanically with auto-revert (ADR 0021 tier).
///
/// The `authored_body` kind is the TRUSTED-AUTHOR tier: the body text is
/// authored by a trusted source (a human, or a verified host session),
/// CONSENTED at pack-write via the unified-diff review gate — never by the
/// model. The model applies it via `apply_executable` at zero authored
/// tokens; the host still runs the same fences (coverage + integration),
/// the free oracles, and auto-revert. The consent IS the expressiveness
/// fence for this kind: a human decision, not model composition, vouches
/// for the body leaving the closed op vocabulary.
///
/// Layering rule: this wire is SYNTAX-ONLY and zero-dep. AE owns the
/// semantics (where executables come from); hosts own realizations (the
/// span editor, the R6 op-chain compiler). The materializer spec names its
/// toolchain as data (ADR 0023 §2):
///
/// | field    | Dart value                                | generic? |
/// |----------|-------------------------------------------|----------|
/// | span     | `source_span` (FileSpan, byte offsets)    | yes      |
/// | map      | `source_maps` (range → meaning-node id)   | yes      |
/// | emitter  | `code_builder` + dart_style               | NO       |
/// | oracle   | `dart analyze` + workspace convention     | NO       |
library;

/// One parameterized edit executable, as declared by a know pack or a
/// project repair pack. The model picks [id] and fills the bounded slots
/// of [params]; the host does everything else.
class EditExecutableWire {
  const EditExecutableWire({
    required this.id,
    required this.kind,
    required this.params,
    required this.verification,
    this.scope = 'lexical',
    this.description = '',
  });

  factory EditExecutableWire.fromJson(Map<String, Object?> json) {
    final kind = EditExecutableKind.tryParse(json['kind'] as String? ?? '');
    if (kind == null) {
      throw ArgumentError(
        'edit_executable wire: unknown kind "${json['kind']}" '
        '(fail loudly on unknown shapes — AE wire rule)',
      );
    }
    return EditExecutableWire(
      id: json['id'] as String? ?? '',
      kind: kind,
      params: (json['params'] as List<Object?>? ?? [])
          .whereType<String>()
          .toList(growable: false),
      verification: (json['verification'] as List<Object?>? ?? [])
          .whereType<String>()
          .map(EditVerification.tryParse)
          .whereType<EditVerification>()
          .toList(growable: false),
      scope: json['scope'] as String? ?? 'lexical',
      description: json['description'] as String? ?? '',
    );
  }

  /// Stable executable id — the model-facing handle. Convention:
  /// `<domain>/<verb>` e.g. `dart/fix_loop_bound`, `project/rename_field`.
  final String id;

  /// What shape of move this executable expands into.
  final EditExecutableKind kind;

  /// Bounded parameter slots the model may fill, by name. Values are
  /// supplied per move (`apply_executable` params); the HOST validates
  /// them — the model never authors a patch.
  final List<String> params;

  /// The mechanical verify tier that MUST run after expansion (free
  /// oracles; auto-revert on failure).
  final List<EditVerification> verification;

  /// `lexical` (refs-frontier identifier expansion — v1 rename) or
  /// `analyzer` (Element-precise, P4/J3). Never implicit: a pack that
  /// needs analyzer grade says so, and the host bounces if it cannot
  /// realize that grade.
  final String scope;

  final String description;

  /// Whether this wire declares a named-parameter rename (API-breaking).
  /// Hosts must refuse to apply those silently.
  bool get isApiBreaking => kind == EditExecutableKind.renameNamedParam;

  Map<String, Object?> toJson() => {
    'id': id,
    'kind': kind.wire,
    'params': params,
    'verification': [
      for (final v in verification) v.wire,
    ],
    'scope': scope,
    if (description.isNotEmpty) 'description': description,
    if (isApiBreaking) 'api_breaking': true,
  };
}

enum EditExecutableKind {
  renameSymbol('rename_symbol'),
  renameNamedParam('rename_named_param'),
  insertMember('insert_member'),
  replaceMemberBody('replace_member_body'),
  deleteMember('delete_member'),
  moveMember('move_member'),

  /// Trusted-author tier: a fixed, consented-at-pack-write body text the
  /// host splices into a covered member. The body travels with the PACK
  /// (data, like the op-chain of `replace_member_body`), never on the wire
  /// and never from the model.
  authoredBody('authored_body'),

  /// Structural class-shape pack kinds (trusted-author tier): the pack
  /// declares the SPEC as data — for `add_constructor_param`: the class
  /// symbol id, the param name/type, whether it is optional and its
  /// default, and which constructor (named or the unnamed one); for
  /// `add_enum_case`: the enum symbol id, the case name and optional
  /// const args. The HOST splices the constructor signature, the backing
  /// field and (when required) the initializer — or the enum case —
  /// byte-precisely, fence-resolved, analyzer-oracle verified with
  /// auto-revert. Consent is SEPARATE from the pack: registration is
  /// free, application refuses without a wired consent approver
  /// (deny-by-default).
  addConstructorParam('add_constructor_param'),
  addEnumCase('add_enum_case');

  const EditExecutableKind(this.wire);
  final String wire;

  static EditExecutableKind? tryParse(String wire) {
    for (final k in values) {
      if (k.wire == wire) return k;
    }
    return null;
  }
}

enum EditVerification {
  analyze('analyze'),
  test('test');

  const EditVerification(this.wire);
  final String wire;

  static EditVerification? tryParse(String raw) {
    for (final v in values) {
      if (v.wire == raw) return v;
    }
    return null;
  }
}