import 'dart:convert';

import 'package:agentic_executables_wire/agentic_executables_wire.dart';
import 'package:test/test.dart';

/// Wire gate for the hub manifest (`ae.hub_manifest.v1`): the distribution
/// seam of the knowledge plane. Local hub today; remote hub is NAMED, NOT
/// BUILT — these tests pin the seam remote verbs will land on.
Map<String, dynamic> _fixtureManifest() => {
  'schema': hubManifestSchema,
  'entries': [
    {
      'pack': 'harness',
      'file': 'harness.knowledge_pack.json',
      'sha256':
          'a3f1b2c4d5e6f7089a1b2c3d4e5f60718293a4b5c6d7e8f90a1b2c3d4e5f6071',
      'version': 7,
    },
    {
      'pack': 'ae_docs',
      'file': 'ae_docs.knowledge_pack.json',
      'sha256': 'ff' * 32,
      'version': '2.1.0',
    },
  ],
};

void main() {
  test('valid manifest parses with entries verbatim', () {
    final result = validateHubManifest(_fixtureManifest());
    expect(result.isValid, isTrue);
    expect(result.errors, isEmpty);
    expect(result.manifest.entries.length, 2);
    expect(result.manifest.byPack['harness']!.file,
        'harness.knowledge_pack.json');
    expect(result.manifest.byPack['ae_docs']!.version, '2.1.0');
    expect(result.manifest.toMap()['schema'], 'ae.hub_manifest.v1');
  });

  test('UNKNOWN schema fails LOUDLY (wire rule)', () {
    expect(
      () => validateHubManifest({
        'schema': 'ae.hub_manifest.v9',
        'entries': <Object>[],
      }),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          allOf(contains('ae.hub_manifest.v9'), contains('fail loudly')),
        ),
      ),
    );
  });

  test('non-list entries fail LOUDLY (wire rule)', () {
    expect(
      () => validateHubManifest({'schema': hubManifestSchema, 'entries': 'no'}),
      throwsA(isA<StateError>()),
    );
  });

  test('corrupted entries are named data, valid entries survive', () {
    final result = validateHubManifest({
      'schema': hubManifestSchema,
      'entries': [
        'not-an-object', // not an entry
        {
          'pack': 'half',
          'file': 'half.json',
          'sha256': 'ff' * 32,
          // missing version
        },
        {
          'pack': 'badhash',
          'file': 'x.json',
          'sha256': 'zz',
          'version': 1,
        },
        {
          'pack': 'alien',
          'file': 'x.json',
          'sha256': 'ff' * 32,
          'version': 1,
          'extra': true, // unknown key
        },
        {
          'pack': 'harness',
          'file': 'harness.knowledge_pack.json',
          'sha256': 'aa' * 32,
          'version': 1,
        },
      ],
    });
    expect(result.manifest.entries.map((e) => e.pack), ['harness']);
    expect(result.errors.length, 4);
    expect(result.errors[0]['reason'], 'entry is not an object');
    expect(result.errors[1]['reason'], contains('missing'));
    expect(result.errors[2]['reason'], contains('64 hex'));
    expect(result.errors[3]['reason'], contains('unknown entry keys'));
    for (final e in result.errors) {
      expect((e['reason'] as String).isNotEmpty, isTrue);
    }
  });

  test('duplicate pack ids are named errors (manifest is a map, not a log)', () {
    final fixture = _fixtureManifest();
    fixture['entries'] = [
      ...fixture['entries'] as List,
      {
        'pack': 'harness',
        'file': 'other.json',
        'sha256': 'bb' * 32,
        'version': 2,
      },
    ];
    final result = validateHubManifest(fixture);
    expect(result.manifest.entries.length, 2);
    expect(
      result.errors.where((e) => e['reason'] == 'duplicate pack id').length,
      1,
    );
  });

  test('canonical form is byte-identical and key-order independent', () {
    final a = canonicalHubManifestForm(_fixtureManifest());
    // object keys reorder freely; list order is data and is preserved
    final reordered = {
      'entries': [
        {
          'version': 7,
          'sha256':
              'a3f1b2c4d5e6f7089a1b2c3d4e5f60718293a4b5c6d7e8f90a1b2c3d4e5f6071',
          'file': 'harness.knowledge_pack.json',
          'pack': 'harness',
        },
        {
          'version': '2.1.0',
          'sha256': 'ff' * 32,
          'file': 'ae_docs.knowledge_pack.json',
          'pack': 'ae_docs',
        },
      ],
      'schema': hubManifestSchema,
    };
    expect(canonicalHubManifestForm(reordered), a);
    // decodes back to the same data
    final reparsed = validateHubManifest(jsonDecode(a) as Map);
    expect(reparsed.isValid, isTrue);
    expect(reparsed.manifest.entries.length, 2);
  });

  test('manifest entries survive toMap/fromMap round trip', () {
    final result = validateHubManifest(_fixtureManifest());
    final restored = HubManifest.fromMap(result.manifest.toMap());
    expect(restored.entries.length, 2);
    expect(restored.byPack['harness']!.sha256,
        'a3f1b2c4d5e6f7089a1b2c3d4e5f60718293a4b5c6d7e8f90a1b2c3d4e5f6071');
  });
}
