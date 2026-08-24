import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  test('error-code playbook covers emitted codes', () async {
    final repoRoot = _findRepoRoot();
    final playbook =
        File(p.join(repoRoot.path, 'docs', 'error_code_playbook.md'));
    expect(playbook.existsSync(), isTrue,
        reason: 'Missing docs/error_code_playbook.md');

    final playbookContent = await playbook.readAsString();
    final documentedCodes =
        RegExp(r'^\|\s*`([a-z0-9_]+)`\s*\|', multiLine: true)
            .allMatches(playbookContent)
            .map((final match) => match.group(1)!)
            .toSet();

    final emittedCodes = <String>{};
    final sourceRoots = [
      Directory(p.join(repoRoot.path, 'agentic_executables_cli', 'lib')),
      Directory(p.join(repoRoot.path, 'agentic_executables_core', 'lib')),
      Directory(p.join(repoRoot.path, 'agentic_executables_mcp', 'lib')),
    ];

    for (final root in sourceRoots) {
      await for (final entity in root.list(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) {
          continue;
        }
        final source = await entity.readAsString();
        for (final match
            in RegExp(r"code:\s*'([a-z0-9_]+)'").allMatches(source)) {
          emittedCodes.add(match.group(1)!);
        }
        for (final match
            in RegExp(r"\?\?\s*'([a-z0-9_]+)'").allMatches(source)) {
          emittedCodes.add(match.group(1)!);
        }
      }
    }

    emittedCodes.removeAll({
      'auto', 'codex', 'unknown',
      'linux', 'json',
      'main', 'github', 'url', 'passthrough',
      'origin',
      // False positives from `?? 'literal'` patterns in Dart sources
      'reuse', '1', 'markdown', 'from', 'to',
      // AE 3.0 enum-default fallbacks in canonical/artifact models
      'text', 'modified', 'path', 'heuristic', 'local',
      'missing', 'contributor', 'website', 'hand',
      // Default locale for `ae spec export`
      'en',
      // Default for `ae canonical distill --mode`
      'upsert',
      // Default impl status for `ae artifact mark-evidence` (not an error code)
      'done',
    });
    emittedCodes.add('doctor_checks_failed');

    final missing = emittedCodes.difference(documentedCodes);
    expect(
      missing,
      isEmpty,
      reason:
          'Missing error codes in docs/error_code_playbook.md: ${missing.join(', ')}',
    );
  });

  test('CLI docs stay aligned with parser surface', () async {
    final repoRoot = _findRepoRoot();
    final rootReadme =
        await File(p.join(repoRoot.path, 'README.md')).readAsString();
    final cliReadme = await File(
      p.join(repoRoot.path, 'agentic_executables_cli', 'README.md'),
    ).readAsString();

    expect(rootReadme, contains('ae doctor'));
    expect(rootReadme, contains('ae registry get --library-id'));
    expect(rootReadme, isNot(contains('--force')));
    expect(rootReadme, contains('--upgrade'));

    expect(cliReadme, contains('ae doctor'));
    expect(cliReadme, contains('--check'));
    expect(cliReadme, contains('--diff'));
    expect(cliReadme, contains('--backup'));
    expect(cliReadme, contains('--no-overwrite'));
    expect(cliReadme, contains('--out <path>'));
    expect(cliReadme, contains('--upgrade'));

    final commandSection = cliReadme
        .split('## Command Surface')
        .last
        .split('Use contextual help')
        .first;
    expect(commandSection, contains('ae skill install'));
    expect(commandSection, isNot(contains('--force')));
  });
}

Directory _findRepoRoot() {
  return findRepoRootDirectory(
    matches: (final rootPath) =>
        Directory(p.join(rootPath, 'prompts_framework')).existsSync() &&
        Directory(p.join(rootPath, 'agentic_executables_cli')).existsSync(),
  );
}
