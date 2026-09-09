// ignore_for_file: lines_longer_than_80_chars

/// EditExecutableWire round-trip + loud-failure rules (ADR 0023 §3).
import 'package:test/test.dart';
import 'package:agentic_executables_wire/agentic_executables_wire.dart';

void main() {
  test('round-trip: fromJson → toJson → fromJson preserves the shape', () {
    const wire = EditExecutableWire(
      id: 'dart/fix_loop_bound',
      kind: EditExecutableKind.replaceMemberBody,
      params: ['symbolId'],
      verification: [EditVerification.analyze, EditVerification.test],
      scope: 'lexical',
      description: 'off-by-one inclusive bound fix',
    );
    final back = EditExecutableWire.fromJson(wire.toJson());
    expect(back.id, wire.id);
    expect(back.kind, wire.kind);
    expect(back.params, wire.params);
    expect(
      back.verification.map((v) => v.wire),
      wire.verification.map((v) => v.wire),
    );
    expect(back.scope, 'lexical');
  });

  test('unknown kind fails LOUDLY (never a silent empty export)', () {
    expect(
      () => EditExecutableWire.fromJson({
        'id': 'x/y',
        'kind': 'transmogrify',
        'params': <String>[],
        'verification': <String>[],
      }),
      throwsArgumentError,
    );
  });

  test('api-breaking kinds are flagged, never silent', () {
    const wire = EditExecutableWire(
      id: 'dart/rename_named_param',
      kind: EditExecutableKind.renameNamedParam,
      params: ['symbolId', 'oldName', 'newName'],
      verification: [EditVerification.analyze, EditVerification.test],
      scope: 'analyzer',
    );
    expect(wire.isApiBreaking, isTrue);
    expect(wire.toJson()['api_breaking'], isTrue);
  });

  test('structural class-shape kinds round-trip (add_constructor_param)', () {
    const wire = EditExecutableWire(
      id: 'dart/add_constructor_param',
      kind: EditExecutableKind.addConstructorParam,
      params: [
        'symbolId',
        'paramName',
        'paramType',
        'required',
        'defaultValue',
        'constructor',
        'field',
        'initializer',
      ],
      verification: [EditVerification.analyze, EditVerification.test],
      scope: 'lexical',
      description:
          'splice a constructor param + backing field (+ initializer when '
          'required) — host-realized, consent-gated at apply',
    );
    final back = EditExecutableWire.fromJson(wire.toJson());
    expect(back.kind, EditExecutableKind.addConstructorParam);
    expect(back.kind.wire, 'add_constructor_param');
    expect(back.params, wire.params);
    expect(back.isApiBreaking, isFalse);
  });

  test('structural class-shape kinds round-trip (add_enum_case)', () {
    const wire = EditExecutableWire(
      id: 'dart/add_enum_case',
      kind: EditExecutableKind.addEnumCase,
      params: ['symbolId', 'caseName', 'args'],
      verification: [EditVerification.analyze],
      scope: 'lexical',
    );
    final json = wire.toJson();
    expect(json['kind'], 'add_enum_case');
    final back = EditExecutableWire.fromJson(json);
    expect(back.kind, EditExecutableKind.addEnumCase);
    expect(back.params, ['symbolId', 'caseName', 'args']);
  });
}
