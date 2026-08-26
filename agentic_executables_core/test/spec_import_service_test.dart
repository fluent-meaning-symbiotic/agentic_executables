import 'dart:io';

import 'package:agentic_executables_core/agentic_executables_core.dart';
import 'package:test/test.dart';

const _speckitSample = '''
# Feature: Login

## Requirements

FR-1: The system SHALL authenticate users by email.
- Passwords MUST be hashed with bcrypt.
- Rate limit after 5 failures.

FR-2: Sessions expire after 24 hours.
''';

const _headingsSample = '''
# My ADR

## Context

We need offline-first sync.

## Decision

Use CRDTs. Clients must resolve conflicts locally.

## Consequences

Eventual consistency is accepted.
''';

void main() {
  group('SpecImportParser', () {
    test('detects and parses speckit requirement lines', () {
      final parsed = SpecImportParser.parse(_speckitSample);
      expect(parsed.format, 'speckit');
      expect(parsed.features, hasLength(2));
      expect(parsed.features[0].suggestedId, 'fr1');
      expect(parsed.features[0].spec, contains('authenticate'));
      expect(parsed.features[0].invariant, contains('bcrypt'));
      expect(parsed.features[1].suggestedId, 'fr2');
    });

    test('parses generic headings / ADR shape', () {
      final parsed = SpecImportParser.parse(_headingsSample);
      expect(parsed.format, 'headings');
      expect(parsed.features.map((f) => f.suggestedId),
          ['context', 'decision', 'consequences']);
      final decision = parsed.features[1];
      expect(decision.spec, contains('CRDTs'));
      expect(decision.invariant, contains('must resolve conflicts'));
    });

    test('parses any document without requiring a specification format', () {
      const markdown = '''
# 2026–2028 Vision

## One number

The app must show one daily number. Planning stays long-term.

## Commitments

- Subscriptions are commitments.
- A commitment must update the number.
''';
      final parsed = SpecImportParser.parseDocument(markdown);
      expect(parsed.format, 'headings');
      expect(
        parsed.features.map((feature) => feature.suggestedId),
        ['one_number', 'commitments'],
      );
      expect(parsed.features[0].spec, contains('Planning stays long-term.'));
      expect(parsed.features[0].invariant, contains('one daily number'));
      expect(parsed.features[1].spec, contains('Subscriptions are'));
    });

    test('slugify strips leading digits and caps length', () {
      expect(SpecImportParser.slugify('2026 Roadmap!'),
          startsWith('sec_'));
      expect(SpecImportParser.slugify('User Story: Big Feature'),
          'user_story_big_feature');
    });
  });

  group('DefaultSpecImportService', () {
    late Directory temp;
    late DefaultCanonicalService canonicalService;

    setUp(() async {
      temp = await Directory.systemTemp.createTemp('ae_spec_import_');
      canonicalService = DefaultCanonicalService(
        store: FileCanonicalStore(temp.path),
      );
    });

    tearDown(() => temp.delete(recursive: true));

    test('creates a new canonical from a speckit document', () async {
      final svc = DefaultSpecImportService(canonicalService: canonicalService);
      final result = await svc.importSpec(
        'auth',
        markdown: _speckitSample,
        title: 'Authentication',
      );
      expect(result.created, isTrue);
      expect(result.format, 'speckit');
      expect(result.ids, ['spec.fr1', 'spec.fr2']);
      expect(result.skippedIds, isEmpty);

      final pack = await canonicalService.load('auth');
      expect(pack, isNotNull);
      expect(pack!.matrix.features, hasLength(2));
      expect(
        pack.matrix.features[0].cells['spec'],
        contains('authenticate'),
      );
    });

    test('creates canonical matrix rows from any document', () async {
      final svc = DefaultSpecImportService(canonicalService: canonicalService);
      const markdown = '# Vision\n\n## Household\n\nTwo people must share one budget.\n';
      final result = await svc.importSpec(
        'vision',
        markdown: markdown,
        title: 'Vision',
        format: 'document',
      );
      expect(result.format, 'headings');
      expect(result.ids, ['spec.household']);
      final pack = await canonicalService.load('vision');
      expect(pack!.matrix.columnSchema.map((column) => column.id),
          containsAll(['spec', 'invariant']));
      expect(pack.matrix.features.single.cells['invariant'],
          'Two people must share one budget.');
    });

    test('merge semantics never clobber existing rows', () async {
      final svc = DefaultSpecImportService(canonicalService: canonicalService);
      await svc.importSpec('auth', markdown: _speckitSample);

      final result = await svc.importSpec(
        'auth',
        markdown: '# Extra\n\n## New Section\n\nFresh content.\n',
      );
      expect(result.created, isFalse);
      // spec.fr1/spec.fr2 preserved; only the new heading row added.
      expect(result.ids, containsAll(['spec.fr1', 'spec.fr2', 'spec.new_section']));
      final pack = await canonicalService.load('auth');
      expect(pack!.matrix.features, hasLength(3));
    });
  });
}
