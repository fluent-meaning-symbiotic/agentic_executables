import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  test('ae --help remains global help', () async {
    final result = await runCli(['--help']);

    expect(result.exitCode, 0);
    expect(result.stdout, contains('ae CLI v3'));
    expect(result.stdout, contains('Run `ae <command> --help`'));
  });

  test('ae --help lists AE 3.0 dispatchable commands', () async {
    final result = await runCli(['--help']);

    expect(result.exitCode, 0);
    expect(result.stdout, contains('ae init '));
    expect(result.stdout, contains('ae status '));
    expect(result.stdout, contains('ae sync '));
    expect(result.stdout, contains('ae canonical '));
    expect(result.stdout, contains('ae artifact '));
    expect(result.stdout, contains('ae spec export '));
  });

  test('ae registry get --help is contextual', () async {
    final result = await runCli(['registry', 'get', '--help']);

    expect(result.exitCode, 0);
    expect(result.stdout, contains('Usage: ae registry get'));
    expect(result.stdout, contains('--out'));
    expect(result.stdout, contains('--check'));
    expect(result.stdout, isNot(contains('ae CLI v3')));
  });

  test('ae skill install --help is contextual with upgrade semantics',
      () async {
    final result = await runCli(['skill', 'install', '--help']);

    expect(result.exitCode, 0);
    expect(result.stdout, contains('Usage: ae skill install'));
    expect(result.stdout, contains('--upgrade'));
    expect(result.stdout, isNot(contains('--force')));
  });

  test('ae generate --help includes safe-write options', () async {
    final result = await runCli(['generate', '--help']);

    expect(result.exitCode, 0);
    expect(result.stdout, contains('Usage: ae generate'));
    expect(result.stdout, contains('--check'));
    expect(result.stdout, contains('--diff'));
    expect(result.stdout, contains('--backup'));
    expect(result.stdout, contains('--no-overwrite'));
  });

  test('ae doctor --help is contextual', () async {
    final result = await runCli(['doctor', '--help']);

    expect(result.exitCode, 0);
    expect(result.stdout, contains('Usage: ae doctor'));
    expect(result.stdout, contains('--target'));
  });

  test('ae canonical distill --help is contextual', () async {
    final result = await runCli(['canonical', 'distill', '--help']);

    expect(result.exitCode, 0);
    expect(result.stdout, contains('ae canonical distill'));
    expect(result.stdout, contains('--pack'));
    expect(result.stdout, contains('--concept'));
    expect(result.stdout, contains('--from-output'));
    expect(result.stdout, contains('never calls a model'));
    expect(result.stdout, isNot(contains('No contextual help found')));
  });

  test('ae spec export --help is contextual', () async {
    final result = await runCli(['spec', 'export', '--help']);

    expect(result.exitCode, 0);
    expect(result.stdout, contains('Usage: ae spec export'));
    expect(result.stdout, contains('--out'));
    expect(result.stdout, isNot(contains('No contextual help found')));
  });
}
