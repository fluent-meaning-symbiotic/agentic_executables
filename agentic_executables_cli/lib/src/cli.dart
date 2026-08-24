import 'dart:convert';
import 'dart:io';

import 'package:agentic_executables_core/agentic_executables_core.dart';
import 'package:args/args.dart';
import 'package:path/path.dart' as path;

import 'engine/codex_exec_generation_engine.dart';
import 'io/safe_file_writer.dart';
import 'resources/embedded_cli_resources.dart';
import 'resources/embedded_document_store.dart';
import 'resources/skill_template_providers.dart';
import 'spec_export_support.dart';

class AeCli {
  AeCli({
    IOSink? out,
    IOSink? err,
    this.codexBinary,
    this.environment,
    this.inferenceClient,
    this.registryProbeUrl,
    this.registryClient,
  })  : _out = out ?? stdout,
        _err = err ?? stderr;

  final IOSink _out;
  final IOSink _err;
  final String? codexBinary;
  final Map<String, String>? environment;
  final InferenceClient? inferenceClient;
  final String? registryProbeUrl;
  final RegistryClient? registryClient;

  Future<int> run(final List<String> args) async {
    final parser = _buildParser();

    late final ArgResults results;
    try {
      results = parser.parse(args);
    } on FormatException catch (error) {
      final envelope = _errorEnvelope(
        command: 'parse',
        code: 'invalid_arguments',
        message: error.message,
      );
      _out.writeln(jsonEncode(envelope));
      return 64;
    }

    if (_shouldRenderHelp(results)) {
      _out.writeln(_helpText(results, parser));
      return 0;
    }

    final human = results['human'] == true;
    final commandPath = _commandPath(results);
    final stopwatch = Stopwatch()..start();

    late final Map<String, dynamic> envelope;
    try {
      final commandResult = await _dispatch(results);
      envelope = _resultToEnvelope(commandPath, commandResult);
    } catch (error, stack) {
      envelope = _errorEnvelope(
        command: commandPath,
        code: 'internal_error',
        message: 'Unhandled command error',
        details: '$error\n$stack',
      );
    }

    stopwatch.stop();

    final meta = (envelope['meta'] as Map<String, dynamic>?) ?? {};
    envelope['meta'] = {
      ...meta,
      'timing_ms': stopwatch.elapsedMilliseconds,
      'versions': {'cli': '3.2.0', 'core': AeCoreConfig.frameworkVersion},
    };

    if (!human &&
        (commandPath == 'package resolve' ||
            commandPath == 'package validate')) {
      return _renderPackageCommand(commandPath, envelope);
    }

    if (human) {
      _printHuman(envelope);
    } else {
      _out.writeln(jsonEncode(envelope));
    }

    if (commandPath == 'doctor' && envelope['success'] == true) {
      final data = envelope['data'] as Map<String, dynamic>?;
      final overall = data?['overall_status']?.toString();
      return overall == 'fail' ? 1 : 0;
    }

    return envelope['success'] == true ? 0 : 1;
  }

  ArgParser _buildParser() {
    final parser = ArgParser()
      ..addFlag('human', negatable: false, help: 'Readable output mode')
      ..addFlag('help', abbr: 'h', negatable: false, help: 'Show help');

    parser
        .addCommand('definition')
        .addFlag('help', abbr: 'h', negatable: false, help: 'Show help');

    parser.addCommand('instructions')
      ..addFlag('help', abbr: 'h', negatable: false, help: 'Show help')
      ..addOption(
        'context',
        allowed: AeContext.validValues,
        help: 'Context type',
      )
      ..addOption('action', allowed: AeAction.validValues, help: 'Action type')
      ..addOption(
        'resources-path',
        help: 'Optional override path to prompts resources',
      );

    parser.addCommand('verify')
      ..addFlag('help', abbr: 'h', negatable: false, help: 'Show help')
      ..addOption(
        'input',
        defaultsTo: '-',
        help: 'JSON file path or - for stdin',
      );

    parser.addCommand('evaluate')
      ..addFlag('help', abbr: 'h', negatable: false, help: 'Show help')
      ..addOption(
        'input',
        defaultsTo: '-',
        help: 'JSON file path or - for stdin',
      );

    final package = parser.addCommand('package')
      ..addFlag('help', abbr: 'h', negatable: false, help: 'Show help');
    package.addCommand('resolve')
      ..addFlag('help', abbr: 'h', negatable: false, help: 'Show help')
      ..addOption('package', help: 'Package identifier')
      ..addOption(
        'package-root',
        help: 'Directory to read pubspec/package version from (default: cwd)',
      )
      ..addOption('target', defaultsTo: 'linux', help: 'Target runtime')
      ..addOption('format', defaultsTo: 'json', help: 'Output format');
    package.addCommand('validate')
      ..addFlag('help', abbr: 'h', negatable: false, help: 'Show help')
      ..addOption(
        'instructions',
        help: 'Instruction file path, inline JSON payload, or - for stdin',
      );

    parser.addCommand('doctor')
      ..addFlag('help', abbr: 'h', negatable: false, help: 'Show help')
      ..addOption(
        'target',
        help: 'Override target skill directory checked for writability',
      );

    final registry = parser.addCommand('registry')
      ..addFlag('help', abbr: 'h', negatable: false, help: 'Show help');
    registry.addCommand('get')
      ..addFlag('help', abbr: 'h', negatable: false, help: 'Show help')
      ..addOption('library-id', help: 'Library id')
      ..addOption(
        'action',
        allowed: AeAction.registryActions,
        help: 'Registry action',
      )
      ..addOption('out', help: 'Write fetched file to output path')
      ..addFlag('check', negatable: false, help: 'Detect drift without writes')
      ..addFlag('diff', negatable: false, help: 'Emit unified diff metadata')
      ..addFlag(
        'backup',
        negatable: false,
        help: 'Create timestamped backup before overwrite',
      )
      ..addFlag(
        'no-overwrite',
        negatable: false,
        help: 'Block overwriting existing files',
      );

    registry.addCommand('submit')
      ..addFlag('help', abbr: 'h', negatable: false, help: 'Show help')
      ..addOption('library-url', help: 'Library repository URL')
      ..addOption('library-id', help: 'Library id')
      ..addMultiOption(
        'ae-use-files',
        splitCommas: true,
        help: 'AE file list (CSV or repeated flag)',
      );

    registry.addCommand('bootstrap-local')
      ..addFlag('help', abbr: 'h', negatable: false, help: 'Show help')
      ..addOption('ae-use-path', help: 'Path to ae_use directory');

    parser.addCommand('generate')
      ..addFlag('help', abbr: 'h', negatable: false, help: 'Show help')
      ..addOption('library-id', help: 'Library id')
      ..addOption('library-root', help: 'Library root path')
      ..addOption('output-dir', help: 'Output directory for generated files')
      ..addOption(
        'engine',
        allowed: AeGenerationEngineMode.validValues,
        defaultsTo: AeGenerationEngineMode.auto.value,
        help: 'Generation engine mode',
      )
      ..addFlag('dry-run', negatable: false, help: 'Do not write files')
      ..addFlag('check', negatable: false, help: 'Detect drift without writes')
      ..addFlag('diff', negatable: false, help: 'Emit unified diff metadata')
      ..addFlag(
        'backup',
        negatable: false,
        help: 'Create timestamped backup before overwrite',
      )
      ..addFlag(
        'no-overwrite',
        negatable: false,
        help: 'Block overwriting existing files',
      );

    final skill = parser.addCommand('skill')
      ..addFlag('help', abbr: 'h', negatable: false, help: 'Show help');
    skill.addCommand('install')
      ..addFlag('help', abbr: 'h', negatable: false, help: 'Show help')
      ..addOption('target', help: 'Skills directory target')
      ..addOption('name', defaultsTo: 'ae-cli', help: 'Skill folder name')
      ..addFlag('upgrade', negatable: false, help: 'Upgrade existing skill')
      ..addOption(
        'template-path',
        help: 'Optional override path to SKILL.md template',
      );

    skill.addCommand('update')
      ..addFlag('help', abbr: 'h', negatable: false, help: 'Show help')
      ..addOption('target', help: 'Skills directory target')
      ..addOption('name', defaultsTo: 'ae-cli', help: 'Skill folder name')
      ..addOption(
        'template-path',
        help: 'Optional override path to SKILL.md template',
      );

    final hub = parser.addCommand('hub')
      ..addFlag('help', abbr: 'h', negatable: false, help: 'Show help');
    hub.addCommand('init')
      ..addFlag('help', abbr: 'h', negatable: false, help: 'Show help')
      ..addOption('path', help: 'Hub directory path')
      ..addFlag('project',
          negatable: false, help: 'Create hub in current project');
    hub.addCommand('status')
      ..addFlag('help', abbr: 'h', negatable: false, help: 'Show help')
      ..addOption('hub', help: 'Hub path override');
    hub.addCommand('pull')
      ..addFlag('help', abbr: 'h', negatable: false, help: 'Show help')
      ..addOption('hub', help: 'Hub path override')
      ..addOption('remote', defaultsTo: 'origin', help: 'Remote name')
      ..addOption('library-id', help: 'Specific library to pull')
      ..addOption(
        'type',
        allowed: ['know', 'use', 'packages'],
        help: 'Artifact type to pull',
      );
    hub.addCommand('push')
      ..addFlag('help', abbr: 'h', negatable: false, help: 'Show help')
      ..addOption('hub', help: 'Hub path override')
      ..addOption('remote', defaultsTo: 'origin', help: 'Remote name');

    parser.addCommand('init')
      ..addFlag('help', abbr: 'h', negatable: false, help: 'Show help')
      ..addOption(
        'root',
        help: 'Project root to scan (defaults to cwd). Hub must exist '
            'at <root>/.ae_hub.',
      )
      ..addFlag(
        'strict',
        defaultsTo: false,
        negatable: false,
        help: 'Exit non-zero if any sub-directory has no extractor.',
      );

    parser.addCommand('status')
      ..addFlag('help', abbr: 'h', negatable: false, help: 'Show help')
      ..addOption('root', help: 'Project root (defaults to cwd).')
      ..addOption(
        'pack',
        help: 'Narrow to a single artifact pack name (verifyOne).',
      )
      ..addOption('tier', help: 'Show only entries at this tier (1-4).');

    parser.addCommand('sync')
      ..addFlag('help', abbr: 'h', negatable: false, help: 'Show help')
      ..addOption('root', help: 'Project root (defaults to cwd).')
      ..addOption('pack', help: 'Sync only the named artifact pack.')
      ..addFlag(
        'prune',
        defaultsTo: false,
        negatable: false,
        help: 'Remove artifacts whose source path no longer exists '
            '(spec §6.2).',
      );

    final use = parser.addCommand('use')
      ..addFlag('help', abbr: 'h', negatable: false, help: 'Show help');
    for (final action in const ['install', 'uninstall', 'update']) {
      use.addCommand(action)
        ..addFlag('help', abbr: 'h', negatable: false, help: 'Show help')
        ..addOption('library-id', help: 'Library id (required).')
        ..addOption('root', help: 'Project root (defaults to cwd).');
    }

    final canonical = parser.addCommand('canonical')
      ..addFlag('help', abbr: 'h', negatable: false, help: 'Show help');
    canonical.addCommand('init')
      ..addFlag('help', abbr: 'h', negatable: false, help: 'Show help')
      ..addOption('concept', help: 'Concept slug (required).')
      ..addOption('title', help: 'Human title (required).')
      ..addOption('root', help: 'Project root (defaults to cwd).');
    canonical.addCommand('scaffold')
      ..addFlag('help', abbr: 'h', negatable: false, help: 'Show help')
      ..addOption('concept', help: 'Concept slug (required).')
      ..addOption('title', help: 'Human title (optional with --update).')
      ..addMultiOption('from-artifact',
          help: 'Artifact pack name (repeatable; required).')
      ..addFlag('overwrite',
          defaultsTo: false,
          negatable: false,
          help: 'Replace an existing canonical at --concept.')
      ..addFlag('update',
          defaultsTo: false,
          negatable: false,
          help: 'Reconcile existing canonical against current source symbols. '
              'Adds rows for new symbols, marks vanished symbols removed:true. '
              'Preserves text. Idempotent. Mutually exclusive with --overwrite.')
      ..addMultiOption('rename',
          help: 'Migrate an id during --update. Format: old=new. Repeatable. '
              'Strict: errors if old missing or new already exists.')
      ..addOption('root', help: 'Project root (defaults to cwd).');
    canonical.addCommand('list')
      ..addFlag('help', abbr: 'h', negatable: false, help: 'Show help')
      ..addOption('root', help: 'Project root.');
    canonical.addCommand('snapshot')
      ..addFlag('help', abbr: 'h', negatable: false, help: 'Show help')
      ..addOption('concept', help: 'Concept slug to snapshot.')
      ..addOption('root', help: 'Project root.');
    canonical.addCommand('diff')
      ..addFlag('help', abbr: 'h', negatable: false, help: 'Show help')
      ..addOption('concept', help: 'Concept slug.')
      ..addOption('from', help: 'From version (e.g. v1).')
      ..addOption('to', help: 'To version (e.g. v2 or "current").')
      ..addOption('root', help: 'Project root.');
    canonical.addCommand('import')
      ..addFlag('help', abbr: 'h', negatable: false, help: 'Show help')
      ..addOption('from', help: 'External canonical directory path.')
      ..addOption('as', help: 'Concept id under which to import.')
      ..addOption('root', help: 'Project root.');
    canonical.addCommand('import-spec')
      ..addFlag('help', abbr: 'h', negatable: false, help: 'Show help')
      ..addOption('from', help: 'Path to an external spec document (.md).')
      ..addOption('concept', help: 'Concept slug to create/merge into.')
      ..addOption('title', help: 'Canonical title (defaults to concept slug).')
      ..addOption('format',
          allowed: ['auto', 'speckit', 'headings'],
          defaultsTo: 'auto',
          help: 'Parser format (auto detects speckit vs headings).')
      ..addOption('root', help: 'Project root.');
    canonical.addCommand('distill')
      ..addFlag('help', abbr: 'h', negatable: false, help: 'Show help')
      ..addOption('pack', help: 'Artifact pack name (required in emit phase).')
      ..addOption('repo',
          help: 'Emit phase: public git URL to shallow-clone and distill via '
              'the generic extractor (code-agnostic). Mutually exclusive '
              'with --pack.')
      ..addOption('concept', help: 'Canonical concept slug (required).')
      ..addOption('from-output',
          help: 'Merge phase: path to the agent\'s ae.canonical.draft.v1 JSON '
              '(or "-" for stdin). Omit to emit delegation instructions.')
      ..addOption(
        'mode',
        help: 'upsert (new) or refine (seed from existing).',
        allowed: ['upsert', 'refine'],
        defaultsTo: 'upsert',
      )
      ..addOption('root', help: 'Project root.');
    canonical.addCommand('accept-concept')
      ..addFlag('help', abbr: 'h', negatable: false, help: 'Show help')
      ..addOption('concept', help: 'Canonical concept slug (required).')
      ..addOption('id',
          help: 'New feature id to assign (required, operator-chosen).')
      ..addOption('from-proposal',
          help: 'Proposal name from the most recent distill run (required).')
      ..addOption('root', help: 'Project root.');

    final artifact = parser.addCommand('artifact')
      ..addFlag('help', abbr: 'h', negatable: false, help: 'Show help');
    artifact.addCommand('list')
      ..addFlag('help', abbr: 'h', negatable: false, help: 'Show help')
      ..addOption('root', help: 'Project root.');
    artifact.addCommand('verify')
      ..addFlag('help', abbr: 'h', negatable: false, help: 'Show help')
      ..addOption('pack', help: 'Pack name (required).')
      ..addFlag(
        'strict',
        defaultsTo: false,
        negatable: false,
        help: 'Exit non-zero on Tier 1+2.',
      )
      ..addFlag(
        'run-tests',
        defaultsTo: false,
        negatable: false,
        help: 'Execute recorded evidence commands instead of trusting cells. '
            'A failing command becomes a Tier 1 entry.',
      )
      ..addOption('root', help: 'Project root.');
    artifact.addCommand('link')
      ..addFlag('help', abbr: 'h', negatable: false, help: 'Show help')
      ..addOption('pack', help: 'Pack name (required).')
      ..addOption(
        'canonical',
        help: 'Canonical reference (e.g. "ecs" or "gltf/core@v2").',
      )
      ..addOption('root', help: 'Project root.');
    artifact.addCommand('mark-evidence')
      ..addFlag('help', abbr: 'h', negatable: false, help: 'Show help')
      ..addOption('pack', help: 'Pack name (required).')
      ..addOption('feature', help: 'Feature id (required).')
      ..addOption('test-command',
          help: 'Command that produces the test evidence; executed (not '
              'trusted) by verify --run-tests (required).')
      ..addOption('location', help: 'Test file or directory path.')
      ..addOption('notes', help: 'Free-text provenance note.')
      ..addOption('impl',
          allowed: ['done', 'partial', 'missing', 'planned', 'n_a', 'deviates'],
          defaultsTo: 'done',
          help: 'Promotes a missing impl cell to this status.')
      ..addOption('root', help: 'Project root.');
    artifact.addCommand('upgrade-canonical')
      ..addFlag('help', abbr: 'h', negatable: false, help: 'Show help')
      ..addOption('pack', help: 'Pack name (required).')
      ..addOption('canonical', help: 'Canonical concept id.')
      ..addOption('to', help: 'Target version, e.g. "2".')
      ..addOption('root', help: 'Project root.');

    final spec = parser.addCommand('spec')
      ..addFlag('help', abbr: 'h', negatable: false, help: 'Show help');
    spec.addCommand('export')
      ..addFlag('help', abbr: 'h', negatable: false, help: 'Show help')
      ..addOption('out', help: 'Output directory (required).')
      ..addOption('hub', help: 'Hub path override (defaults to resolved hub).')
      ..addOption('root', help: 'Project root (defaults to cwd).')
      ..addOption('locale', help: 'Locale code (default: en).');

    return parser;
  }

  bool _shouldRenderHelp(final ArgResults root) {
    if (root.command == null) {
      return true;
    }

    if (root['help'] == true) {
      return true;
    }

    var current = root.command!;
    while (true) {
      if (current['help'] == true) {
        return true;
      }
      if (current.command == null) {
        return false;
      }
      current = current.command!;
    }
  }

  String _helpText(final ArgResults root, final ArgParser parser) {
    if (root.command == null || root['help'] == true && root.command == null) {
      return _globalUsage(parser);
    }

    final segments = <String>[];
    var current = root.command!;
    while (true) {
      final name = current.name;
      if (name != null) {
        segments.add(name);
      }
      if (current.command == null) {
        break;
      }
      current = current.command!;
    }

    final commandPath = segments.join(' ');
    return _contextualHelp(commandPath);
  }

  String _globalUsage(final ArgParser parser) => '''
ae CLI v3

${parser.usage}

Run `ae <command> --help` for contextual command help and examples.

Commands:
  ae definition
  ae package resolve --package <id> --target linux --format json
  ae package validate --instructions <file-or-json>
  ae instructions --context <library|project> --action <...> [--resources-path <path>]
  ae verify --input <json-file|->
  ae evaluate --input <json-file|->
  ae doctor [--target <skills-dir>]
  ae registry get --library-id <id> --action <install|uninstall|update|use> [--out <path>] [--check] [--diff] [--backup] [--no-overwrite]
  ae registry submit --library-url <url> --library-id <id> --ae-use-files <csv|repeatable>
  ae registry bootstrap-local --ae-use-path <path>
  ae generate --library-id <id> --library-root <path> [--output-dir <path>] [--engine auto|codex|template] [--dry-run] [--check] [--diff] [--backup] [--no-overwrite]
  ae skill install [--target <skills-dir>] [--name ae-cli] [--upgrade] [--template-path <path>]
  ae skill update [--target <skills-dir>] [--name ae-cli] [--template-path <path>]
  ae hub init [--path <dir>] [--project]
  ae hub status [--hub <path>]
  ae hub pull [--hub <path>] [--remote origin] [--library-id <id>] [--type <know|use|packages>]
  ae hub push [--hub <path>] [--remote origin]
  ae init [--root <dir>] [--strict]
  ae status [--pack <name>] [--tier <n>] [--root <dir>]
  ae sync [--pack <name>] [--prune] [--root <dir>]
  ae use install --library-id <id> [--root <dir>]
  ae use uninstall --library-id <id> [--root <dir>]
  ae use update --library-id <id> [--root <dir>]
  ae canonical <init|scaffold|list|distill|snapshot|diff|import> [...]
  ae artifact <list|verify|link|upgrade-canonical> [...]
  ae spec export --out <dir> [--hub <path>] [--root <dir>] [--locale <code>]
''';

  String _contextualHelp(final String commandPath) {
    switch (commandPath) {
      case 'definition':
        return '''
Usage: ae definition

Returns AE framework definition and capability matrix.

Example:
  ae definition
''';
      case 'package':
        return '''
Usage: ae package <resolve|validate> [options]

Subcommands:
  ae package resolve --help
  ae package validate --help
''';
      case 'package resolve':
        return '''
Usage: ae package resolve --package <id> --target linux --format json

Resolves Lythe-compatible package instructions from the current package repository.

Example:
  ae package resolve --package dev.xs.registry --target linux --format json
''';
      case 'package validate':
        return '''
Usage: ae package validate --instructions <file-or-json>

Examples:
  ae package validate --instructions ./instructions.json
  ae package validate --instructions '{"contract_version":"ae.v3.package.v1", ...}'
  cat ae.instructions.json | ae package validate --instructions -
''';
      case 'instructions':
        return '''
Usage: ae instructions --context <library|project> --action <bootstrap|install|uninstall|update|use> [--resources-path <path>] [--know <name>]

Options:
  --context         Required context type.
  --action          Required action type.
  --resources-path  Optional filesystem override for prompt documents.
  --know            Knowledge pack name for domain context.

Examples:
  ae instructions --context library --action bootstrap
  ae instructions --context project --action install --know flutter
''';
      case 'verify':
        return '''
Usage: ae verify --input <json-file|->

Examples:
  ae verify --input verify.json
  cat verify.json | ae verify --input -
''';
      case 'evaluate':
        return '''
Usage: ae evaluate --input <json-file|->

Examples:
  ae evaluate --input evaluate.json
  cat evaluate.json | ae evaluate --input -
''';
      case 'doctor':
        return '''
Usage: ae doctor [--target <skills-dir>]

Performs CLI preflight checks for:
- Codex availability (warning)
- Dart SDK availability (warning)
- Skill target writability (critical)
- Registry reachability (critical)

Examples:
  ae doctor
  ae doctor --target ~/.codex/skills
''';
      case 'registry':
        return '''
Usage: ae registry <get|submit|bootstrap-local> [options]

Subcommands:
  ae registry get --help
  ae registry submit --help
  ae registry bootstrap-local --help
''';
      case 'registry get':
        return '''
Usage: ae registry get --library-id <id> --action <install|uninstall|update|use> [--out <path>] [--check] [--diff] [--backup] [--no-overwrite]

Options:
  --out           Optional output destination.
  --check         Detect drift and skip writes.
  --diff          Include unified diff metadata for changes.
  --backup        Backup overwritten files to timestamped copies.
  --no-overwrite  Block overwrites of existing files.

Examples:
  ae registry get --library-id python_requests --action install
  ae registry get --library-id python_requests --action install --out ./ae_use
  ae registry get --library-id python_requests --action install --out ./ae_use --check --diff
''';
      case 'registry submit':
        return '''
Usage: ae registry submit --library-url <url> --library-id <id> --ae-use-files <csv|repeatable>

Example:
  ae registry submit --library-url https://github.com/example/lib --library-id dart_provider --ae-use-files ae_use/ae_install.md,ae_use/ae_uninstall.md,ae_use/ae_update.md,ae_use/ae_use.md
''';
      case 'registry bootstrap-local':
        return '''
Usage: ae registry bootstrap-local --ae-use-path <path>

Example:
  ae registry bootstrap-local --ae-use-path ./ae_use
''';
      case 'generate':
        return '''
Usage: ae generate --library-id <id> --library-root <path> [--output-dir <path>] [--engine auto|codex|template] [--know <name>] [--dry-run] [--check] [--diff] [--backup] [--no-overwrite]

Options:
  --know          Knowledge pack name for domain context.
  --check         Detect drift and skip writes.
  --diff          Include unified diff metadata for changes.
  --backup        Backup overwritten files to timestamped copies.
  --no-overwrite  Block overwrites of existing files.

Examples:
  ae generate --library-id dart_provider --library-root . --engine auto
  ae generate --library-id dart_provider --library-root . --engine template --know flutter
''';
      case 'skill':
        return '''
Usage: ae skill <install|update> [options]

Subcommands:
  ae skill install --help
  ae skill update --help
''';
      case 'skill install':
        return '''
Usage: ae skill install [--target <skills-dir>] [--name ae-cli] [--upgrade] [--template-path <path>]

Behavior:
- Missing skill: install.
- Same template content: success with no_op=true.
- Different installed content: fail with skill_upgrade_required unless --upgrade is provided.

Examples:
  ae skill install
  ae skill install --target ~/.codex/skills --name ae-cli
  ae skill install --upgrade
''';
      case 'skill update':
        return '''
Usage: ae skill update [--target <skills-dir>] [--name ae-cli] [--template-path <path>]

Compatibility wrapper for upgrade semantics.

Examples:
  ae skill update
  ae skill update --target ~/.codex/skills
''';
      case 'hub':
        return '''
Usage: ae hub <init|status|pull|push> [options]

Subcommands:
  ae hub init --help
  ae hub status --help
  ae hub pull --help
  ae hub push --help
''';
      case 'hub init':
        return '''
Usage: ae hub init [--path <dir>] [--project]

Initializes a new AE hub. The hub always nests under `.ae_hub/` of the
resolved parent directory:
  --path X    → X/.ae_hub/
  --project   → <cwd>/.ae_hub/
  (neither)   → ~/.ae_hub/

The scaffolded subdirs follow the v3 layout (spec §4.1):
  canonical/
  artifacts/local/
  artifacts/external/
  artifacts/use/

Examples:
  ae hub init
  ae hub init --project
  ae hub init --path /tmp/my-hub-parent
''';
      case 'hub status':
        return '''
Usage: ae hub status [--hub <path>]

Shows hub status including artifact counts and config.

Examples:
  ae hub status
  ae hub status --hub ~/.ae_hub
''';
      case 'hub pull':
        return '''
Usage: ae hub pull [--hub <path>] [--remote origin] [--library-id <id>] [--type <know|use|packages>]

Pulls artifacts from a remote registry into the local hub.
If --library-id is given, fetches that library's ae_use files.
Without --library-id, shows remote config info.

Examples:
  ae hub pull
  ae hub pull --library-id dart_provider
  ae hub pull --remote upstream --library-id python_requests
''';
      case 'hub push':
        return '''
Usage: ae hub push [--hub <path>] [--remote origin]

Generates instructions for pushing local hub artifacts to a remote registry.

Examples:
  ae hub push
  ae hub push --remote upstream
''';
      case 'init':
        return '''
Usage: ae init [--root <dir>] [--strict]

Scans the current project for known language manifests and ingests each
sub-package as a local artifact. Requires a .ae_hub directory at root.

Options:
  --root    Project root to scan (default: cwd).
  --strict  Exit non-zero if any sub-directory has no matching extractor.

Examples:
  ae init
  ae init --root . --strict
''';
      case 'status':
        return '''
Usage: ae status [--root <dir>] [--pack <name>] [--tier <1-4>]

Project-wide tier-classified gap report.

Tiers:
  1 — invariant violations (canonical asserts; no test verifies)
  2 — upstream blockers (downstream-required features missing/partial)
  3 — partial referenced features
  4 — unreferenced canonicals

Examples:
  ae status
  ae status --pack my_pkg --tier 1
''';
      case 'sync':
        return '''
Usage: ae sync [--root <dir>] [--pack <name>] [--prune]

Re-scan source files for artifact packs and report drift (code + intent).

Options:
  --pack   Sync only the named pack (default: all packs in hub).
  --prune  Remove artifacts whose source path no longer exists (spec §6.2).
           Pruned pack names are surfaced in the envelope under `pruned`.

Examples:
  ae sync
  ae sync --pack my_pkg
  ae sync --prune
''';
      case 'use':
        return '''
Usage: ae use <install|uninstall|update> --library-id <id> [--root <dir>]

Local-first shim over `ae registry get`. Resolves the project hub via
.ae_hub at the given --root, looks for a matching local override at
<hub>/artifacts/use/<library_id>/<ae_install|ae_uninstall|ae_update>.md,
and falls back to the registry when no local override exists.

Subcommands:
  ae use install   --help
  ae use uninstall --help
  ae use update    --help
''';
      case 'use install':
        return '''
Usage: ae use install --library-id <id> [--root <dir>]

Returns the install instructions for <id>. Tries
<hub>/artifacts/use/<id>/ae_install.md first, then falls back to
`ae registry get --library-id <id> --action install`.
''';
      case 'use uninstall':
        return '''
Usage: ae use uninstall --library-id <id> [--root <dir>]

Returns the uninstall instructions for <id>. Tries
<hub>/artifacts/use/<id>/ae_uninstall.md first, then falls back to
`ae registry get --library-id <id> --action uninstall`.
''';
      case 'use update':
        return '''
Usage: ae use update --library-id <id> [--root <dir>]

Returns the update instructions for <id>. Tries
<hub>/artifacts/use/<id>/ae_update.md first, then falls back to
`ae registry get --library-id <id> --action update`.
''';
      case 'canonical':
        return '''
Usage: ae canonical <subcommand> [options]

Manage canonical concept packs (specs + matrices) stored under
<hub>/canonical/<concept>/.

Subcommands:
  init      Stub a new canonical pack with an empty matrix.
  scaffold  Heuristic seed from one or more artifacts (no LLM).
  list      List concept ids in the hub.
  distill   Emit delegation instructions for the host agent, or merge its
            returned draft (--from-output). AE never calls a model.
  snapshot  Freeze the live canonical into v<n>/ (bumps version).
  diff      Structural diff between two versions of a concept.
  import    Copy an external canonical directory into this hub.
  import-spec
            Import an external spec document (Spec Kit, ADR, markdown)
            as canonical feature rows. Deterministic, no LLM.

Run `ae canonical <subcommand> --help` for details.
''';
      case 'canonical init':
        return '''
Usage: ae canonical init --concept <slug> --title <text> [--root <dir>]

Scaffold a new canonical pack with empty matrix and minimal meta.

Examples:
  ae canonical init --concept ecs --title "Entity Component System"
''';
      case 'canonical scaffold':
        return '''
Usage: ae canonical scaffold --concept <slug> --title <text>
                             --from-artifact <pack> [--from-artifact <pack2> ...]
                             [--overwrite] [--root <dir>]

Heuristic-seed (no LLM) a draft canonical from one or more artifact packs.
Parses each artifact's `## Public API` section in index.md and emits one
feature row per detected symbol with stub spec/invariant cells the user
fills in. Spec §6.7.

Feature ids: `<artifact_pack>.<sanitized_symbol>` (camelCase becomes
snake_case; non-id chars become underscores). First occurrence wins on
collision across artifacts.

Options:
  --concept        Concept slug (required).
  --title          Human title (required).
  --from-artifact  Artifact pack name (repeatable; required).
  --overwrite      Replace an existing canonical at --concept.

Examples:
  ae canonical scaffold --concept ae/cli --title "AE CLI" --from-artifact agentic_executables_cli
  ae canonical scaffold --concept ecsly/render_pipeline --title "Render pipeline" \\
    --from-artifact dart_render3d --from-artifact dart_render3d_passes
''';
      case 'canonical list':
        return '''
Usage: ae canonical list [--root <dir>]

List all canonical concept ids in the hub.
''';
      case 'canonical import-spec':
        return '''
Usage: ae canonical import-spec --from <file.md> --concept <slug>
                                [--title <text>] [--format auto|speckit|headings]
                                [--root <dir>]

Deterministically parse an external spec document (GitHub Spec Kit spec,
ADR, or any structured markdown) into canonical feature rows. No LLM.

Parsing rules:
  speckit   FR-/NFR-/REQ- requirement lines and User Story sections become
            features; MUST/SHALL bullets fold into the `invariant` cell.
  headings  Every ##+ heading becomes one feature; sentences containing
            must/shall fold into `invariant`.
  auto      Detects speckit shape, falls back to headings.

Merge semantics: existing rows are never overwritten; colliding ids are
reported in skipped_ids. Feature ids are assigned as spec.<slug> with
deterministic _N suffixes on collision.

Examples:
  ae canonical import-spec --from specs/002-login/spec.md \\
    --concept auth --title "Authentication"
''';
      case 'canonical distill':
        return '''
Usage:
  ae canonical distill --pack <artifact> --concept <slug> [--mode upsert|refine]
  ae canonical distill --concept <slug> --from-output <file.json|-> [--root <dir>]

AE never calls a model. Distillation is a two-phase delegation:

Phase 1 (emit): with --pack, AE composes the distillation task from the
artifact's real source files plus the canonical seed rows, and returns
delegation instructions embedding the task JSON (ae.distillation.task.v1).
Hand these to your coding agent (Claude Code, pi, Codex, Cursor...).

Phase 2 (merge): the agent returns an ae.canonical.draft.v1 JSON. Merge it
with --from-output <file> (or "-" for stdin). AE validates the schema,
enforces id stability (no invented ids), merges into the live canonical,
and persists any proposed_concepts for `ae canonical accept-concept`.

Examples:
  ae canonical distill --pack dart_ecs --concept ecs > task.md
  # ...agent enriches rows...
  ae canonical distill --concept ecs --from-output agent_draft.json
''';
      case 'canonical snapshot':
        return '''
Usage: ae canonical snapshot --concept <slug> [--root <dir>]

Freeze the live canonical into v<n>/ and bump the live version.

Examples:
  ae canonical snapshot --concept ecs
''';
      case 'canonical diff':
        return '''
Usage: ae canonical diff --concept <slug> [--from <vN>] [--to <vM|current>] [--root <dir>]

Structural diff between two versions of the same concept. Either side may be
omitted (compares against live).

Examples:
  ae canonical diff --concept ecs --from v1 --to current
  ae canonical diff --concept ecs --from v1 --to v2
''';
      case 'canonical import':
        return '''
Usage: ae canonical import --from <dir> --as <concept-id> [--root <dir>]

Copy a canonical directory (meta.yaml + index.md + matrix.yaml) from another
hub into this hub under the given concept id.

Examples:
  ae canonical import --from ../other/.ae_hub/canonical/ecs --as ecs
''';
      case 'artifact':
        return '''
Usage: ae artifact <subcommand> [options]

Manage artifact packs stored under <hub>/artifacts/<kind>/<name>/.

Subcommands:
  list               List artifact pack names in the hub.
  verify             Tier-classified gap report for one pack.
  link               Attach a canonical reference to a pack.
  upgrade-canonical  Pin a pack's canonical reference to a specific version.

Run `ae artifact <subcommand> --help` for details.
''';
      case 'artifact list':
        return '''
Usage: ae artifact list [--root <dir>]

List all artifact pack names in the hub.
''';
      case 'artifact verify':
        return '''
Usage: ae artifact verify --pack <name> [--strict] [--run-tests] [--root <dir>]

Verify a single artifact pack and emit a tier-classified gap report.

Options:
  --pack    Pack name (required).
  --strict  Exit non-zero when Tier 1 or Tier 2 entries are present.

Examples:
  ae artifact verify --pack my_pkg
  ae artifact verify --pack my_pkg --strict
''';
      case 'artifact mark-evidence':
        return '''
Usage: ae artifact mark-evidence --pack <pack> --feature <id>
                                 --test-command <cmd> [--location <path>]
                                 [--impl <status>] [--notes <text>] [--root <dir>]

Record test evidence for one feature row. The command is stored as
provenance and EXECUTED (not trusted) by `ae artifact verify --run-tests`.

Examples:
  ae artifact mark-evidence --pack agentic_executables_cli \
    --feature agentic_executables_cli.embedded_cli_resources \
    --test-command "dart test test/embedded_resources_test.dart" \
    --location test/embedded_resources_test.dart
''';
      case 'artifact link':
        return '''
Usage: ae artifact link --pack <name> --canonical <ref> [--root <dir>]

Attach a canonical reference to a pack and re-materialize matrix rows.
Reference formats:
  ecs                 live (tracks current)
  gltf/core@v2        locked to snapshot v2

Examples:
  ae artifact link --pack my_pkg --canonical ecs
  ae artifact link --pack my_pkg --canonical gltf/core@v2
''';
      case 'artifact upgrade-canonical':
        return '''
Usage: ae artifact upgrade-canonical --pack <name> --canonical <concept> --to <version> [--root <dir>]

Pin a pack's canonical reference to a specific integer version and
re-materialize matrix rows against the new version.

Examples:
  ae artifact upgrade-canonical --pack my_pkg --canonical ecs --to 2
''';
      case 'spec':
        return '''
Usage: ae spec <export> [options]

Subcommands:
  export   Emit spec_export.v3 (canonical + artifact JSON) from a hub.

Run `ae spec export --help` for details.
''';
      case 'spec export':
        return '''
Usage: ae spec export --out <dir> [--hub <path>] [--root <dir>] [--locale <code>]

Emits the v3 spec bundle into <dir>:
  spec_index.json            (schema: spec_export.v3)
  definition.{yaml,md,json}  (framework definition trio)
  canonical_<slug>.json      (schema: ae.canonical.v3; one per pack)
  artifact_<name>.json       (schema: ae.artifact.v3; one per pack)

Options:
  --out     Output directory (required).
  --hub     Hub path override (bypasses resolution).
  --root    Project root used for hub resolution (default: cwd).
  --locale  Locale code written into spec_index.json (default: en).

Examples:
  ae spec export --out ./.ae_export
  ae spec export --out ./.ae_export --hub ./.ae_hub --locale en
''';
      default:
        return 'No contextual help found for "$commandPath"';
    }
  }

  String _commandPath(final ArgResults root) {
    final parts = <String>[];
    var current = root;
    while (current.command != null) {
      current = current.command!;
      if (current.name != null) {
        parts.add(current.name!);
      }
    }
    return parts.join(' ');
  }

  Future<AeResult<Map<String, dynamic>>> _dispatch(
    final ArgResults root,
  ) async {
    final command = root.command;
    if (command == null) {
      return AeResult.fail(code: 'invalid_command', message: 'Missing command');
    }

    switch (command.name) {
      case 'definition':
        return _handleDefinition();
      case 'instructions':
        return _handleInstructions(command);
      case 'package':
        return _handlePackage(command);
      case 'verify':
        return _handleVerify(command);
      case 'evaluate':
        return _handleEvaluate(command);
      case 'doctor':
        return _handleDoctor(command);
      case 'registry':
        return _handleRegistry(command);
      case 'generate':
        return _handleGenerate(command);
      case 'skill':
        return _handleSkill(command);
      case 'hub':
        return _handleHub(command);
      case 'init':
        return _handleInit(command);
      case 'status':
        return _handleStatus(command);
      case 'sync':
        return _handleSync(command);
      case 'use':
        return _handleUse(command);
      case 'canonical':
        return _handleCanonical(command);
      case 'artifact':
        return _handleArtifact(command);
      case 'spec':
        return _handleSpec(command);
      default:
        return AeResult.fail(
          code: 'invalid_command',
          message: 'Unknown command: ${command.name}',
        );
    }
  }

  AeResult<Map<String, dynamic>> _handleDefinition() {
    final result = const DefaultAeDefinitionService().getDefinition();
    if (!result.success || result.data == null) {
      return AeResult.fail(
        code: result.error?.code ?? 'definition_failed',
        message: result.error?.message ?? 'Failed to get definition',
        details: result.error?.details,
      );
    }

    return AeResult.ok(
      result.data!.toJson(),
      warnings: result.warnings,
      meta: result.meta,
    );
  }

  Future<AeResult<Map<String, dynamic>>> _handleInstructions(
    final ArgResults command,
  ) async {
    final contextRaw = command['context']?.toString();
    final actionRaw = command['action']?.toString();
    if (contextRaw == null || contextRaw.isEmpty) {
      return AeResult.fail(
        code: 'validation_error',
        message: 'Missing required argument: --context',
      );
    }
    if (actionRaw == null || actionRaw.isEmpty) {
      return AeResult.fail(
        code: 'validation_error',
        message: 'Missing required argument: --action',
      );
    }

    final AeContext context;
    final AeAction action;
    try {
      context = AeContext.fromString(contextRaw);
      action = AeAction.fromString(actionRaw);
    } catch (error) {
      return AeResult.fail(code: 'validation_error', message: error.toString());
    }

    final resourcesPath = command['resources-path']?.toString();
    final documentStore = resourcesPath == null || resourcesPath.isEmpty
        ? EmbeddedDocumentStore(EmbeddedCliResources.prompts)
        : FileDocumentStore(resourcesPath);

    final service = DefaultAeInstructionService(documentStore);
    final result = await service.getInstructions(
      GetInstructionsInput(
        context: context,
        action: action,
      ),
    );

    if (!result.success || result.data == null) {
      return AeResult.fail(
        code: result.error?.code ?? 'instructions_failed',
        message: result.error?.message ?? 'Failed to get instructions',
        details: result.error?.details,
      );
    }

    return AeResult.ok(
      result.data!.toJson(),
      warnings: result.warnings,
      meta: {
        ...result.meta,
        if (resourcesPath == null || resourcesPath.isEmpty)
          'resources_source': 'embedded',
        if (resourcesPath != null && resourcesPath.isNotEmpty)
          'resources_path': resourcesPath,
      },
    );
  }

  Future<AeResult<Map<String, dynamic>>> _handlePackage(
    final ArgResults command,
  ) async {
    final subcommand = command.command;
    if (subcommand == null) {
      return AeResult.fail(
        code: 'validation_error',
        message: 'Missing package subcommand',
      );
    }
    switch (subcommand.name) {
      case 'resolve':
        return _handlePackageResolve(subcommand);
      case 'validate':
        return _handlePackageValidate(subcommand);
      default:
        return AeResult.fail(
          code: 'invalid_command',
          message: 'Unknown package subcommand: ${subcommand.name}',
        );
    }
  }

  Future<AeResult<Map<String, dynamic>>> _handlePackageResolve(
    final ArgResults command,
  ) async {
    final packageId = command['package']?.toString().trim() ?? '';
    final target = command['target']?.toString().trim() ?? 'linux';
    final format = command['format']?.toString().trim() ?? 'json';
    final rootRaw = command['package-root']?.toString().trim() ?? '';
    return const DefaultAePackageService().resolve(
      PackageResolveInput(
        packageId: packageId,
        target: target,
        format: format,
        packageRoot: rootRaw,
      ),
    );
  }

  Future<AeResult<Map<String, dynamic>>> _handlePackageValidate(
    final ArgResults command,
  ) async {
    final source = command['instructions']?.toString().trim() ?? '';
    if (source.isEmpty) {
      return AeResult.fail(
        code: 'validation_error',
        message: 'Missing required argument: --instructions',
      );
    }

    late final Map<String, dynamic> instructions;
    try {
      instructions = await _readInstructionsPayload(source);
    } on FormatException catch (error) {
      return AeResult.fail(code: 'validation_error', message: error.message);
    } on FileSystemException catch (error) {
      return AeResult.fail(
        code: 'validation_error',
        message: 'Failed to read instructions: $error',
      );
    }

    return const DefaultAePackageService().validate(
      PackageValidateInput(instructions: instructions),
    );
  }

  Future<AeResult<Map<String, dynamic>>> _handleVerify(
    final ArgResults command,
  ) async {
    final inputPath = command['input'].toString();
    final payload = await _readInputJson(inputPath);

    final contextRaw = payload['context_type']?.toString();
    final actionRaw = payload['action']?.toString();
    if (contextRaw == null || actionRaw == null) {
      return AeResult.fail(
        code: 'validation_error',
        message: 'context_type and action are required',
      );
    }

    final AeContext context;
    final AeAction action;
    try {
      context = AeContext.fromString(contextRaw);
      action = AeAction.fromString(actionRaw);
    } catch (error) {
      return AeResult.fail(code: 'validation_error', message: error.toString());
    }

    final filesRaw = _parseList(payload['files_modified']);
    final files = filesRaw
        .whereType<Map>()
        .map(
          (final entry) => AeModifiedFile.fromJson(
            entry.map(
              (final key, final value) => MapEntry(key.toString(), value),
            ),
          ),
        )
        .toList(growable: false);

    final checklistRaw = _parseMap(payload['checklist_completed']);
    final checklist = <String, bool>{
      for (final entry in checklistRaw.entries)
        entry.key.toString(): _parseBool(entry.value),
    };

    final validation = const DefaultAeValidationService().verify(
      VerifyInput(
        context: context,
        action: action,
        filesModified: files,
        checklistCompleted: checklist,
      ),
    );

    if (!validation.success || validation.data == null) {
      return AeResult.fail(
        code: validation.error?.code ?? 'verify_failed',
        message: validation.error?.message ?? 'Verification failed',
        details: validation.error?.details,
      );
    }

    final output = validation.data!;
    return AeResult.ok(
      {
        'context_type': context.value,
        'action': action.value,
        'verification': output.toJson(),
        'overall_status': output.overallPass ? 'PASS' : 'FAIL',
        'message': output.overallPass
            ? 'Implementation verification passed.'
            : 'Implementation verification failed. Review missing items.',
      },
      warnings: validation.warnings,
      meta: validation.meta,
    );
  }

  Future<AeResult<Map<String, dynamic>>> _handleEvaluate(
    final ArgResults command,
  ) async {
    final inputPath = command['input'].toString();
    final payload = await _readInputJson(inputPath);

    final contextRaw = payload['context_type']?.toString();
    final actionRaw = payload['action']?.toString();
    if (contextRaw == null || actionRaw == null) {
      return AeResult.fail(
        code: 'validation_error',
        message: 'context_type and action are required',
      );
    }

    final AeContext context;
    final AeAction action;
    try {
      context = AeContext.fromString(contextRaw);
      action = AeAction.fromString(actionRaw);
    } catch (error) {
      return AeResult.fail(code: 'validation_error', message: error.toString());
    }

    final filesRaw = _parseList(payload['files_created']);
    final files = filesRaw
        .whereType<Map>()
        .map(
          (final entry) => AeCreatedFile.fromJson(
            entry.map(
              (final key, final value) => MapEntry(key.toString(), value),
            ),
          ),
        )
        .toList(growable: false);

    final sections = _parseList(
      payload['sections_present'],
    ).map((final entry) => entry.toString()).toList(growable: false);

    final validation = const DefaultAeValidationService().evaluate(
      EvaluateInput(
        context: context,
        action: action,
        filesCreated: files,
        sectionsPresent: sections,
        validationStepsExists: _parseBool(payload['validation_steps_exists']),
        integrationPointsDefined: _parseBool(
          payload['integration_points_defined'],
        ),
        reversibilityIncluded: _parseBool(payload['reversibility_included']),
        hasMetaRules: _parseBool(payload['has_meta_rules']),
      ),
    );

    if (!validation.success || validation.data == null) {
      return AeResult.fail(
        code: validation.error?.code ?? 'evaluate_failed',
        message: validation.error?.message ?? 'Evaluation failed',
        details: validation.error?.details,
      );
    }

    final output = validation.data!;
    return AeResult.ok(
      {
        'context_type': context.value,
        'action': action.value,
        'evaluation': output.toJson(),
        'overall_status': output.overallPass ? 'PASS' : 'FAIL',
        'message': output.overallPass
            ? 'Implementation meets AE compliance requirements.'
            : 'Implementation has issues that need to be addressed.',
      },
      warnings: validation.warnings,
      meta: validation.meta,
    );
  }

  Future<AeResult<Map<String, dynamic>>> _handleDoctor(
    final ArgResults command,
  ) async {
    final target = command['target']?.toString() ?? _defaultSkillsBaseDir();

    final doctor = AeDoctor(
      environment: environment,
      registryProbeUrl: registryProbeUrl,
    );

    final output = await doctor.run(skillTarget: target);

    return AeResult.ok(output.toJson(), meta: const {'operation': 'doctor'});
  }

  Future<AeResult<Map<String, dynamic>>> _handleRegistry(
    final ArgResults command,
  ) async {
    final sub = command.command;
    if (sub == null) {
      return AeResult.fail(
        code: 'validation_error',
        message: 'Registry subcommand is required',
      );
    }

    final client = registryClient ?? GitHubRawRegistryClient();
    final ownsClient = registryClient == null;
    final service = DefaultAeRegistryService(client);
    void closeClient() {
      if (!ownsClient) {
        return;
      }
      if (client is GitHubRawRegistryClient) {
        client.close();
      }
    }

    switch (sub.name) {
      case 'get':
        final libraryId = sub['library-id']?.toString() ?? '';
        final actionRaw = sub['action']?.toString() ?? '';
        if (actionRaw.isEmpty) {
          closeClient();
          return AeResult.fail(
            code: 'validation_error',
            message: 'Missing required argument: --action',
          );
        }

        final AeAction action;
        try {
          action = AeAction.fromString(actionRaw);
        } catch (error) {
          closeClient();
          return AeResult.fail(
            code: 'validation_error',
            message: error.toString(),
          );
        }

        final result = await service.getFromRegistry(
          RegistryGetInput(libraryId: libraryId, action: action),
        );

        if (!result.success || result.data == null) {
          closeClient();
          return AeResult.fail(
            code: result.error?.code ?? 'registry_get_failed',
            message: result.error?.message ?? 'Registry get failed',
            details: result.error?.details,
            warnings: result.warnings,
            meta: result.meta,
          );
        }

        final outPathRaw = sub['out']?.toString();
        if (outPathRaw == null || outPathRaw.isEmpty) {
          closeClient();
          return AeResult.ok(
            result.data!.toJson(),
            warnings: result.warnings,
            meta: result.meta,
          );
        }

        final String resolvedOut;
        try {
          resolvedOut = _resolveRegistryOutPath(outPathRaw, action);
        } catch (error) {
          closeClient();
          return AeResult.fail(
            code: 'validation_error',
            message: error.toString(),
          );
        }
        final writeOptions = _safeWriteOptions(sub);
        final writeResult = await const SafeFileWriter().writeAll(
          requests: [
            FileWriteRequest(path: resolvedOut, content: result.data!.content),
          ],
          options: writeOptions,
        );

        closeClient();

        if (writeOptions.check && writeResult.hasChanges) {
          return AeResult.fail(
            code: 'check_mode_changes_detected',
            message: 'Changes detected in --check mode',
            details: writeResult.toJson(),
            warnings: result.warnings,
            meta: result.meta,
          );
        }

        if (writeResult.hasBlocked) {
          return AeResult.fail(
            code: 'write_conflict_no_overwrite',
            message: 'One or more writes were blocked by --no-overwrite',
            details: writeResult.toJson(),
            warnings: result.warnings,
            meta: result.meta,
          );
        }

        return AeResult.ok(
          {
            ...result.data!.toJson(),
            'out_path': resolvedOut,
            'write': writeResult.toJson(),
            'no_op': !writeResult.hasChanges,
          },
          warnings: result.warnings,
          meta: result.meta,
        );

      case 'submit':
        final libraryUrl = sub['library-url']?.toString() ?? '';
        final libraryId = sub['library-id']?.toString() ?? '';
        final files = (sub['ae-use-files'] as List)
            .map((final value) => value.toString())
            .where((final value) => value.isNotEmpty)
            .toList(growable: false);

        final result = await service.submitToRegistry(
          RegistrySubmitInput(
            libraryUrl: libraryUrl,
            libraryId: libraryId,
            aeUseFiles: files,
          ),
        );
        closeClient();

        if (!result.success || result.data == null) {
          return AeResult.fail(
            code: result.error?.code ?? 'registry_submit_failed',
            message: result.error?.message ?? 'Registry submit failed',
            details: result.error?.details,
            warnings: result.warnings,
            meta: result.meta,
          );
        }

        return AeResult.ok(
          result.data!.toJson(),
          warnings: result.warnings,
          meta: result.meta,
        );

      case 'bootstrap-local':
        final aeUsePath = sub['ae-use-path']?.toString() ?? '';
        final result = service.bootstrapLocalRegistry(
          RegistryBootstrapLocalInput(aeUsePath: aeUsePath),
        );
        closeClient();

        if (!result.success || result.data == null) {
          return AeResult.fail(
            code: result.error?.code ?? 'registry_bootstrap_failed',
            message: result.error?.message ?? 'Registry bootstrap failed',
            details: result.error?.details,
            warnings: result.warnings,
            meta: result.meta,
          );
        }

        return AeResult.ok(
          result.data!.toJson(),
          warnings: result.warnings,
          meta: result.meta,
        );
      default:
        closeClient();
        return AeResult.fail(
          code: 'invalid_command',
          message: 'Unknown registry subcommand: ${sub.name}',
        );
    }
  }

  Future<AeResult<Map<String, dynamic>>> _handleUse(
    final ArgResults command,
  ) async {
    final sub = command.command;
    if (sub == null) {
      return AeResult.fail(
        code: 'validation_error',
        message: 'Use subcommand is required (install|uninstall|update).',
      );
    }

    final AeAction action;
    switch (sub.name) {
      case 'install':
        action = AeAction.install;
        break;
      case 'uninstall':
        action = AeAction.uninstall;
        break;
      case 'update':
        action = AeAction.update;
        break;
      default:
        return AeResult.fail(
          code: 'invalid_command',
          message: 'Unknown use subcommand: ${sub.name}',
        );
    }

    final libraryId = sub['library-id']?.toString().trim() ?? '';
    if (libraryId.isEmpty) {
      return AeResult.fail(
        code: 'validation_error',
        message: 'Missing required argument: --library-id',
      );
    }

    final root = sub['root']?.toString() ?? Directory.current.path;
    final hubPath = await FileHubResolver().resolveHub(projectRoot: root);
    if (hubPath == null) {
      return AeResult.fail(
        code: 'no_hub',
        message: 'No .ae_hub at $root',
      );
    }

    // Local-first: artifacts/use/<library_id>/<file> per spec §4.1.
    final localFile = File(
      path.join(hubPath, 'artifacts', 'use', libraryId, action.fileName),
    );
    if (await localFile.exists()) {
      final content = await localFile.readAsString();
      return AeResult.ok(<String, dynamic>{
        'library_id': libraryId,
        'action': action.value,
        'source': 'local_artifact',
        'content': content,
        'path': localFile.path,
      });
    }

    // Fallback: registry get.
    final client = registryClient ?? GitHubRawRegistryClient();
    final ownsClient = registryClient == null;
    try {
      final service = DefaultAeRegistryService(client);
      final result = await service.getFromRegistry(
        RegistryGetInput(libraryId: libraryId, action: action),
      );
      if (!result.success || result.data == null) {
        return AeResult.fail(
          code: result.error?.code ?? 'registry_get_failed',
          message: result.error?.message ?? 'Registry get failed',
          details: result.error?.details,
          warnings: result.warnings,
          meta: result.meta,
        );
      }
      final data = result.data!;
      return AeResult.ok(
        <String, dynamic>{
          'library_id': libraryId,
          'action': action.value,
          'source': 'registry',
          'content': data.content,
          'path': data.sourceUrl,
        },
        warnings: result.warnings,
        meta: result.meta,
      );
    } finally {
      if (ownsClient && client is GitHubRawRegistryClient) {
        client.close();
      }
    }
  }

  String _resolveRegistryOutPath(final String out, final AeAction action) {
    final normalized = path.normalize(out);
    final entityType = FileSystemEntity.typeSync(normalized);

    final looksDirectory = normalized.endsWith(path.separator) ||
        path.extension(path.basename(normalized)).isEmpty;

    if (entityType == FileSystemEntityType.directory ||
        (entityType == FileSystemEntityType.notFound && looksDirectory)) {
      return path.join(normalized, action.fileName);
    }

    if (entityType == FileSystemEntityType.file && looksDirectory) {
      throw ArgumentError(
        'Path "$normalized" looks like a directory but already exists as a file',
      );
    }

    return normalized;
  }

  Future<AeResult<Map<String, dynamic>>> _handleGenerate(
    final ArgResults command,
  ) async {
    final libraryId = command['library-id']?.toString() ?? '';
    final libraryRoot = command['library-root']?.toString() ?? '';
    if (libraryId.isEmpty || libraryRoot.isEmpty) {
      return AeResult.fail(
        code: 'validation_error',
        message: '--library-id and --library-root are required',
      );
    }

    final engineModeRaw = command['engine']?.toString() ?? 'auto';
    final outputDir =
        command['output-dir']?.toString() ?? path.join(libraryRoot, 'ae_use');

    final AeGenerationEngineMode engineMode;
    try {
      engineMode = AeGenerationEngineMode.fromString(engineModeRaw);
    } catch (error) {
      return AeResult.fail(code: 'validation_error', message: error.toString());
    }

    final dryRun = command['dry-run'] == true;
    final writeOptions = _safeWriteOptions(command);

    final codexClient = inferenceClient ??
        CodexExecInferenceClient(
          binaryName: codexBinary ?? 'codex',
          environment: environment,
        );

    final generationService = DefaultAeGenerationService(
      templateEngine: const TemplateGenerationEngine(),
      codexEngine: InferenceGenerationEngine(client: codexClient),
    );

    final generationResult = await generationService.generate(
      GenerateInput(
        libraryId: libraryId,
        libraryRoot: libraryRoot,
        outputDir: outputDir,
        engineMode: engineMode,
        dryRun: dryRun,
      ),
    );

    if (!generationResult.success || generationResult.data == null) {
      return AeResult.fail(
        code: generationResult.error?.code ?? 'generation_failed',
        message: generationResult.error?.message ?? 'Generation failed',
        details: generationResult.error?.details,
        warnings: generationResult.warnings,
        meta: generationResult.meta,
      );
    }

    final output = generationResult.data!;
    final unresolvedWarnings = output.files
        .where((final file) => file.content.contains('TODO:'))
        .map(
          (final file) =>
              'Unresolved placeholder markers found in ${file.path}',
        )
        .toList(growable: false);

    if (dryRun && !writeOptions.check) {
      return AeResult.ok(
        {
          ...output.toJson(),
          'output_dir': outputDir,
          'dry_run': true,
          'write': {
            'files': const [],
            'has_changes': false,
            'has_blocked': false,
            'wrote_any': false,
          },
          'no_op': false,
        },
        warnings: [...generationResult.warnings, ...unresolvedWarnings],
        meta: generationResult.meta,
      );
    }

    final requests = output.files
        .map(
          (final file) => FileWriteRequest(
            path: path.join(outputDir, file.path),
            content: file.content,
          ),
        )
        .toList(growable: false);

    final effectiveOptions = dryRun
        ? SafeWriteOptions(
            check: true,
            diff: writeOptions.diff,
            backup: false,
            noOverwrite: writeOptions.noOverwrite,
          )
        : writeOptions;

    final writeResult = await const SafeFileWriter().writeAll(
      requests: requests,
      options: effectiveOptions,
    );

    if (writeOptions.check && writeResult.hasChanges) {
      return AeResult.fail(
        code: 'check_mode_changes_detected',
        message: 'Changes detected in --check mode',
        details: writeResult.toJson(),
        warnings: [...generationResult.warnings, ...unresolvedWarnings],
        meta: generationResult.meta,
      );
    }

    if (writeResult.hasBlocked) {
      return AeResult.fail(
        code: 'write_conflict_no_overwrite',
        message: 'One or more writes were blocked by --no-overwrite',
        details: writeResult.toJson(),
        warnings: [...generationResult.warnings, ...unresolvedWarnings],
        meta: generationResult.meta,
      );
    }

    return AeResult.ok(
      {
        ...output.toJson(),
        'output_dir': outputDir,
        'dry_run': dryRun,
        'write': writeResult.toJson(),
        'no_op': !writeResult.hasChanges,
      },
      warnings: [...generationResult.warnings, ...unresolvedWarnings],
      meta: generationResult.meta,
    );
  }

  Future<AeResult<Map<String, dynamic>>> _handleSkill(
    final ArgResults command,
  ) async {
    final sub = command.command;
    if (sub == null) {
      return AeResult.fail(
        code: 'validation_error',
        message: 'Skill subcommand is required',
      );
    }

    switch (sub.name) {
      case 'install':
        return _handleSkillInstall(sub);
      case 'update':
        return _handleSkillUpdate(sub);
      default:
        return AeResult.fail(
          code: 'invalid_command',
          message: 'Unknown skill subcommand: ${sub.name}',
        );
    }
  }

  Future<AeResult<Map<String, dynamic>>> _handleSkillInstall(
    final ArgResults command,
  ) async {
    return _installOrUpgradeSkill(
      name: command['name'].toString(),
      targetBase: command['target']?.toString() ?? _defaultSkillsBaseDir(),
      upgrade: command['upgrade'] == true,
      templatePath: command['template-path']?.toString(),
      operation: 'skill_install',
      requireExisting: false,
    );
  }

  Future<AeResult<Map<String, dynamic>>> _handleSkillUpdate(
    final ArgResults command,
  ) async {
    return _installOrUpgradeSkill(
      name: command['name'].toString(),
      targetBase: command['target']?.toString() ?? _defaultSkillsBaseDir(),
      upgrade: true,
      templatePath: command['template-path']?.toString(),
      operation: 'skill_update',
      requireExisting: true,
    );
  }

  Future<AeResult<Map<String, dynamic>>> _handleHub(
    final ArgResults command,
  ) async {
    final sub = command.command;
    if (sub == null) {
      return AeResult.fail(
        code: 'validation_error',
        message: 'Hub subcommand is required',
      );
    }

    final resolver = FileHubResolver();
    final client = registryClient ?? GitHubRawRegistryClient();
    final service = DefaultAeHubService(resolver, registryClient: client);

    switch (sub.name) {
      case 'init':
        final pathArg = sub['path']?.toString();
        final project = sub['project'] == true;
        final result = await service.init(
          HubInitInput(path: pathArg, project: project),
        );
        if (!result.success || result.data == null) {
          return AeResult.fail(
            code: result.error?.code ?? 'hub_init_failed',
            message: result.error?.message ?? 'Hub init failed',
            details: result.error?.details,
          );
        }
        return AeResult.ok(result.data!.toJson());

      case 'status':
        final hubArg = sub['hub']?.toString();
        final result = await service.status(HubStatusInput(hubPath: hubArg));
        if (!result.success || result.data == null) {
          return AeResult.fail(
            code: result.error?.code ?? 'hub_status_failed',
            message: result.error?.message ?? 'Hub status failed',
            details: result.error?.details,
          );
        }
        return AeResult.ok(result.data!.toJson());

      case 'pull':
        final hubArg = sub['hub']?.toString();
        final remote = sub['remote']?.toString() ?? 'origin';
        final libraryId = sub['library-id']?.toString();
        final type = sub['type']?.toString();
        final result = await service.pull(
          HubPullInput(
            hubPath: hubArg,
            remote: remote,
            libraryId: libraryId,
            type: type,
          ),
        );
        if (!result.success || result.data == null) {
          return AeResult.fail(
            code: result.error?.code ?? 'hub_pull_failed',
            message: result.error?.message ?? 'Hub pull failed',
            details: result.error?.details,
          );
        }
        return AeResult.ok(result.data!.toJson(), warnings: result.warnings);

      case 'push':
        final hubArg = sub['hub']?.toString();
        final remote = sub['remote']?.toString() ?? 'origin';
        final result = await service.push(
          HubPushInput(hubPath: hubArg, remote: remote),
        );
        if (!result.success || result.data == null) {
          return AeResult.fail(
            code: result.error?.code ?? 'hub_push_failed',
            message: result.error?.message ?? 'Hub push failed',
            details: result.error?.details,
          );
        }
        return AeResult.ok(result.data!.toJson());

      default:
        return AeResult.fail(
          code: 'invalid_command',
          message: 'Unknown hub subcommand: ${sub.name}',
        );
    }
  }

  Future<AeResult<Map<String, dynamic>>> _handleInit(
    final ArgResults command,
  ) async {
    final root = command['root']?.toString() ?? Directory.current.path;
    final strict = command['strict'] as bool? ?? false;
    final resolver = FileHubResolver();
    final hubPath = await resolver.resolveHub(projectRoot: root);
    if (hubPath == null) {
      return AeResult.fail(
        code: 'no_hub',
        message:
            'No .ae_hub found at $root. Create one with: ae hub init --project',
      );
    }
    final artStore = FileArtifactStore(hubPath);
    final canStore = FileCanonicalStore(hubPath);
    final registry = HeuristicExtractorRegistry(const [
      DartHeuristicExtractor(),
      RustHeuristicExtractor(),
      KotlinSwiftHeuristicExtractor(),
    ]);
    final svc = DefaultArtifactService(
      artifactStore: artStore,
      canonicalStore: canStore,
      extractorRegistry: registry,
    );

    final ingested = <String>[];
    final skipped = <String>[];
    // Scan immediate children of root for handle-able manifests; recurse one
    // level if a child is a workspace-style "umbrella" directory.
    final rootDir = Directory(root);
    final entries = await rootDir.list(followLinks: false).toList();
    for (final entity in entries) {
      // Follow symlinks to directories so nested workspaces (e.g.
      // experiments/<crate> exposed via a link) are ingestible.
      var dirPath = entity.path;
      if (entity is Link) {
        final target = entity.targetSync();
        final resolved = path.isAbsolute(target)
            ? target
            : path.normalize(path.join(root, target));
        if (!Directory(resolved).existsSync()) continue;
        dirPath = resolved;
      } else if (entity is! Directory) {
        continue;
      }
      final base = path.basename(dirPath);
      if (base.startsWith('.') || base == '.ae_hub') continue;
      final handler = await registry.findFor(Directory(dirPath));
      if (handler.languageId != 'generic') {
        final name = await svc.ingest(Directory(dirPath));
        ingested.add(name);
      } else {
        // Generic fallback means findFor never returns null; only ingest
        // dirs a specific extractor recognizes. Unknown dirs are skipped.
        skipped.add(entity.path);
      }
    }
    // Also try the root itself.
    final rootHandler = await registry.findFor(rootDir);
    if (rootHandler.languageId != 'generic') {
      final name = await svc.ingest(rootDir);
      ingested.add(name);
    }

    if (strict && skipped.isNotEmpty) {
      return AeResult.fail(
        code: 'unhandled_subdirs',
        message: 'No extractor for ${skipped.length} subdirectories',
        details: {'skipped': skipped},
      );
    }
    return AeResult.ok({
      'hub_path': hubPath,
      'ingested': ingested,
      'skipped_count': skipped.length,
    });
  }

  Future<AeResult<Map<String, dynamic>>> _handleStatus(
    final ArgResults command,
  ) async {
    final root = command['root']?.toString() ?? Directory.current.path;
    final packName = command['pack']?.toString();
    final tierFilterRaw = command['tier']?.toString();
    final resolver = FileHubResolver();
    final hubPath = await resolver.resolveHub(projectRoot: root);
    if (hubPath == null) {
      return AeResult.fail(
        code: 'no_hub',
        message: 'No .ae_hub found at $root.',
      );
    }
    final artStore = FileArtifactStore(hubPath);
    final canStore = FileCanonicalStore(hubPath);
    final svc = DefaultArtifactService(
      artifactStore: artStore,
      canonicalStore: canStore,
      extractorRegistry: HeuristicExtractorRegistry(const []),
    );
    final report = packName != null
        ? await svc.verifyOne(packName)
        : await svc.verifyProject();
    final entries = tierFilterRaw == null
        ? report.entries
        : report.entries
            .where((final e) => e.tier.tier.toString() == tierFilterRaw)
            .toList();
    return AeResult.ok({
      'hub_path': hubPath,
      'entries': entries.map((final e) => e.toJson()).toList(),
      'tier_counts': {
        for (final entry in report.tierCounts.entries)
          entry.key.code: entry.value,
      },
    });
  }

  Future<AeResult<Map<String, dynamic>>> _handleSync(
    final ArgResults command,
  ) async {
    final root = command['root']?.toString() ?? Directory.current.path;
    final packName = command['pack']?.toString();
    final prune = command['prune'] == true;
    final resolver = FileHubResolver();
    final hubPath = await resolver.resolveHub(projectRoot: root);
    if (hubPath == null) {
      return AeResult.fail(code: 'no_hub', message: 'No hub at $root.');
    }
    final artStore = FileArtifactStore(hubPath);
    final canStore = FileCanonicalStore(hubPath);
    final svc = DefaultArtifactService(
      artifactStore: artStore,
      canonicalStore: canStore,
      extractorRegistry: HeuristicExtractorRegistry(const []),
    );
    final drift = DefaultDriftService(
      artifactStore: artStore,
      canonicalStore: canStore,
    );
    final names = packName != null ? [packName] : await svc.list();
    final results = <Map<String, dynamic>>[];
    final pruned = <String>[];
    for (final name in names) {
      try {
        final outcome = await svc.syncOne(name, prune: prune);
        if (outcome.pruned) {
          pruned.add(name);
          results.add({'pack': name, 'pruned': true});
          continue;
        }
        final report = await drift.buildReport(name, generatedBy: 'ae sync');
        results.add({
          'pack': name,
          'changed': outcome.changed,
          'code_drift_count': report.codeDrift.length,
          'intent_drift_count': report.intentDrift.length,
        });
      } on ArgumentError catch (e) {
        results.add({'pack': name, 'error': e.message?.toString()});
      }
    }
    return AeResult.ok({
      'hub_path': hubPath,
      'results': results,
      'pruned': pruned,
    });
  }

  Future<AeResult<Map<String, dynamic>>> _handleCanonical(
    final ArgResults command,
  ) async {
    final sub = command.command;
    if (sub == null) {
      return AeResult.fail(
        code: 'invalid_command',
        message: 'Missing canonical subcommand. See: ae canonical --help',
      );
    }
    final root = sub['root']?.toString() ?? Directory.current.path;
    final resolver = FileHubResolver();
    final hubPath = await resolver.resolveHub(projectRoot: root);
    if (hubPath == null) {
      return AeResult.fail(code: 'no_hub', message: 'No hub at $root.');
    }
    final canStore = FileCanonicalStore(hubPath);
    final svc = DefaultCanonicalService(store: canStore);
    final specImportSvc = DefaultSpecImportService(
      canonicalService: svc,
    );

    switch (sub.name) {
      case 'init':
        final concept = sub['concept']?.toString();
        final title = sub['title']?.toString();
        if (concept == null || concept.isEmpty) {
          return AeResult.fail(
            code: 'validation_error',
            message: 'Missing required --concept',
          );
        }
        if (title == null || title.isEmpty) {
          return AeResult.fail(
            code: 'validation_error',
            message: 'Missing required --title',
          );
        }
        final pack = await svc.scaffold(concept, title: title);
        return AeResult.ok({
          'concept': pack.meta.concept,
          'version': pack.meta.version,
        });

      case 'scaffold':
        final concept = sub['concept']?.toString();
        final title = sub['title']?.toString();
        final fromArtifacts =
            (sub['from-artifact'] as List?)?.cast<String>() ?? const <String>[];
        final overwrite = sub['overwrite'] == true;
        final update = sub['update'] == true;
        if (concept == null || concept.isEmpty) {
          return AeResult.fail(
            code: 'validation_error',
            message: 'Missing required --concept',
          );
        }
        if (fromArtifacts.isEmpty) {
          return AeResult.fail(
            code: 'validation_error',
            message: 'Missing required --from-artifact (repeatable).',
          );
        }
        if (update && overwrite) {
          return AeResult.fail(
            code: 'validation_error',
            message: '--update and --overwrite are mutually exclusive.',
          );
        }

        final artStore = FileArtifactStore(hubPath);

        if (update) {
          final renameRaw =
              (sub['rename'] as List?)?.cast<String>() ?? const <String>[];
          final renames = <List<String>>[];
          for (final r in renameRaw) {
            final eq = r.indexOf('=');
            if (eq < 1 || eq == r.length - 1) {
              return AeResult.fail(
                code: 'validation_error',
                message: 'malformed --rename "$r": expected old=new',
              );
            }
            renames.add([r.substring(0, eq), r.substring(eq + 1)]);
          }
          try {
            final report = await svc.scaffoldUpdate(
              concept,
              artifactNames: fromArtifacts,
              artifactStore: artStore,
              renames: renames,
            );
            return AeResult.ok({
              'concept': concept,
              'mode': 'update',
              'added': report.added,
              'removed': report.removed,
              'renamed': [
                for (final pair in report.renamed)
                  {'from': pair[0], 'to': pair[1]}
              ],
              'unchanged': report.unchanged,
              'from_artifacts': fromArtifacts,
            });
          } on StateError catch (e) {
            if (e.message.contains('canonical_not_found')) {
              return AeResult.fail(
                code: 'canonical_not_found',
                message: e.message,
              );
            }
            rethrow;
          } on ArgumentError catch (e) {
            final msg = e.message?.toString() ?? '';
            if (msg.contains('rename_collision') ||
                msg.contains('rename_missing') ||
                msg.contains('rename_malformed')) {
              return AeResult.fail(code: 'validation_error', message: msg);
            }
            if (msg.contains('artifact_not_found')) {
              return AeResult.fail(
                code: 'artifact_not_found',
                message: msg,
              );
            }
            return AeResult.fail(code: 'validation_error', message: msg);
          }
        }

        // Original (non-update) path. --title is required only here.
        if (title == null || title.isEmpty) {
          return AeResult.fail(
            code: 'validation_error',
            message: 'Missing required --title',
          );
        }
        try {
          final pack = await svc.scaffoldFromArtifact(
            concept,
            title: title,
            artifactNames: fromArtifacts,
            artifactStore: artStore,
            overwrite: overwrite,
          );
          return AeResult.ok({
            'concept': pack.meta.concept,
            'version': pack.meta.version,
            'feature_count': pack.matrix.features.length,
            'authored': pack.meta.provenance.authored.value,
            'from_artifacts': fromArtifacts,
          });
        } on StateError catch (e) {
          if (e.message.contains('canonical_exists')) {
            return AeResult.fail(
              code: 'canonical_exists',
              message: e.message,
            );
          }
          rethrow;
        } on ArgumentError catch (e) {
          final msg = e.message?.toString() ?? '';
          if (msg.contains('artifact_not_found')) {
            return AeResult.fail(
              code: 'artifact_not_found',
              message: msg,
            );
          }
          return AeResult.fail(code: 'validation_error', message: msg);
        }

      case 'list':
        final ids = await svc.list();
        return AeResult.ok({'concepts': ids});

      case 'snapshot':
        final concept = sub['concept']?.toString();
        if (concept == null || concept.isEmpty) {
          return AeResult.fail(
            code: 'validation_error',
            message: 'Missing --concept',
          );
        }
        final dir = await svc.snapshot(concept);
        return AeResult.ok({'concept': concept, 'snapshot_dir': dir});

      case 'diff':
        final concept = sub['concept']?.toString();
        if (concept == null) {
          return AeResult.fail(
            code: 'validation_error',
            message: 'Missing --concept',
          );
        }
        final fromRaw = sub['from']?.toString();
        final toRaw = sub['to']?.toString();
        int? parseVer(final String? raw) {
          if (raw == null || raw.isEmpty || raw == 'current') return null;
          final s = raw.startsWith('v') ? raw.substring(1) : raw;
          return int.tryParse(s);
        }

        final diff = await svc.diff(
          concept,
          fromVersion: parseVer(fromRaw),
          toVersion: parseVer(toRaw),
        );
        return AeResult.ok(diff.toJson());

      case 'import-spec':
        final specFrom = sub['from']?.toString();
        final specConcept = sub['concept']?.toString();
        if (specFrom == null || specConcept == null) {
          return AeResult.fail(
            code: 'validation_error',
            message: 'Missing --from and/or --concept',
          );
        }
        final specFile = File(specFrom);
        if (!await specFile.exists()) {
          return AeResult.fail(
            code: 'file_not_found',
            message: 'Spec document not found: $specFrom',
          );
        }
        try {
          final result = await specImportSvc.importSpec(
            specConcept,
            markdown: await specFile.readAsString(),
            title: sub['title']?.toString(),
            format: sub['format']?.toString() ?? 'auto',
          );
          return AeResult.ok({
            'concept': result.conceptId,
            'format': result.format,
            'created': result.created,
            'feature_count': result.featureCount,
            'ids': result.ids,
            'skipped_ids': result.skippedIds,
          });
        } on StateError catch (e) {
          return AeResult.fail(code: 'spec_parse_empty', message: e.message);
        }

      case 'import':
        final from = sub['from']?.toString();
        final asConcept = sub['as']?.toString();
        if (from == null || asConcept == null) {
          return AeResult.fail(
            code: 'validation_error',
            message: 'Missing --from and/or --as',
          );
        }
        final pack = await svc.import(from, asConceptId: asConcept);
        return AeResult.ok({
          'imported_as': asConcept,
          'concept_in_meta': pack.meta.concept,
        });

      case 'distill':
        return _handleCanonicalDistill(
          sub: sub,
          hubPath: hubPath,
          canonicalService: svc,
        );

      case 'accept-concept':
        final concept = sub['concept']?.toString();
        final id = sub['id']?.toString();
        final fromProposal = sub['from-proposal']?.toString();
        if (concept == null || concept.isEmpty) {
          return AeResult.fail(
            code: 'validation_error',
            message: 'Missing required --concept',
          );
        }
        if (id == null || id.isEmpty) {
          return AeResult.fail(
            code: 'validation_error',
            message: 'Missing required --id',
          );
        }
        if (fromProposal == null || fromProposal.isEmpty) {
          return AeResult.fail(
            code: 'validation_error',
            message: 'Missing required --from-proposal',
          );
        }
        try {
          final result = await svc.acceptConcept(
            concept,
            newId: id,
            fromProposal: fromProposal,
          );
          return AeResult.ok({
            'concept': concept,
            'accepted_id': result.acceptedId,
            'from_proposal': result.proposalName,
          });
        } on ProposalNotFoundException catch (e) {
          return AeResult.fail(
            code: 'proposal_not_found',
            message: e.toString(),
          );
        } on IdCollisionException catch (e) {
          final detail = e.isTombstone
              ? ' The row was previously removed; reuse will be supported by `--revive` (planned).'
              : '';
          return AeResult.fail(
            code: 'id_collision',
            message: '${e.toString()}$detail',
          );
        } on ArgumentError catch (e) {
          // FeatureId.parse rejects malformed ids (hyphens, uppercase, etc.).
          return AeResult.fail(
            code: 'invalid_feature_id',
            message: e.toString(),
          );
        } on ProposalNotFoundException catch (e) {
          return AeResult.fail(
              code: 'proposal_not_found', message: e.toString());
        } on StateError catch (e) {
          if (e.message.contains('canonical_not_found')) {
            return AeResult.fail(
              code: 'canonical_not_found',
              message: e.message,
            );
          }
          rethrow;
        }

      default:
        return AeResult.fail(
          code: 'invalid_command',
          message: 'Unknown canonical subcommand: ${sub.name}',
        );
    }
  }

  Future<AeResult<Map<String, dynamic>>> _handleCanonicalDistill({
    required final ArgResults sub,
    required final String hubPath,
    required final DefaultCanonicalService canonicalService,
  }) async {
    final pack = sub['pack']?.toString();
    final concept = sub['concept']?.toString();
    final fromOutput = sub['from-output']?.toString();
    if (concept == null || concept.isEmpty) {
      return AeResult.fail(
        code: 'validation_error',
        message: 'Missing required --concept',
      );
    }

    // ---- Phase 2: merge a returned draft (host agent did the model work).
    if (fromOutput != null) {
      final String raw;
      if (fromOutput == '-') {
        raw = await systemEncoding.decoder.bind(stdin).join();
      } else {
        final f = File(fromOutput);
        if (!await f.exists()) {
          return AeResult.fail(
            code: 'file_not_found',
            message: 'Draft output not found: $fromOutput',
          );
        }
        raw = await f.readAsString();
      }

      Map<String, dynamic> decoded;
      try {
        decoded = jsonDecode(raw) as Map<String, dynamic>;
      } on FormatException catch (e) {
        return AeResult.fail(
          code: 'draft_parse_failed',
          message: 'Draft output is not valid JSON: ${e.message}',
        );
      }
      if (decoded['schema']?.toString() != 'ae.canonical.draft.v1') {
        return AeResult.fail(
          code: 'draft_schema_mismatch',
          message: 'Expected schema "ae.canonical.draft.v1", got '
              '"${decoded['schema']}"',
        );
      }

      final DistillationOutput output;
      try {
        output = DistillationOutput.fromMap(decoded);
      } catch (e) {
        return AeResult.fail(
          code: 'draft_invalid',
          message: 'Draft output failed validation: $e',
        );
      }
      if (output.conceptId != concept) {
        return AeResult.fail(
          code: 'draft_concept_mismatch',
          message:
              'Draft is for concept "${output.conceptId}", expected "$concept"',
        );
      }

      try {
        final mergeReport = await canonicalService.mergeDistillationDetailed(
          concept,
          output,
        );
        await canonicalService.writeProposalsFile(
          concept,
          proposals: mergeReport.proposedConcepts,
          executorUsed: 'host_agent',
        );
        final merged = mergeReport.pack;
        return AeResult.ok({
          'merged': true,
          'concept': concept,
          'version': merged.meta.version,
          'feature_count': mergeReport.featureCountAfterMerge,
          'feature_count_received': mergeReport.featureCountReceived,
          'feature_count_after_merge': mergeReport.featureCountAfterMerge,
          'executor_used': 'host_agent',
          if (mergeReport.proposedConcepts.isNotEmpty)
            'proposed_concepts': mergeReport.proposedConcepts
                .map((final c) => c.toJson())
                .toList(growable: false),
        }, warnings: mergeReport.warnings);
      } on IdNotInMatrixException catch (e) {
        return AeResult.fail(code: 'id_not_in_matrix', message: e.toString());
      }
    }

    // ---- Phase 1: emit delegation instructions (AE never calls a model).
    final repoUrl = sub['repo']?.toString();
    if (repoUrl != null && repoUrl.isNotEmpty) {
      if (pack != null && pack.isNotEmpty) {
        return AeResult.fail(
          code: 'validation_error',
          message: 'Use either --pack or --repo, not both.',
        );
      }
      return _emitFromRepo(
        repoUrl: repoUrl,
        concept: concept,
        hubPath: hubPath,
        canonicalService: canonicalService,
      );
    }
    if (pack == null || pack.isEmpty) {
      return AeResult.fail(
        code: 'validation_error',
        message: 'Missing required --pack (or --repo <url>) in emit phase',
      );
    }

    final artStore = FileArtifactStore(hubPath);
    final artifact = await artStore.load(pack);
    if (artifact == null) {
      return AeResult.fail(
        code: 'artifact_not_found',
        message: 'Artifact pack not found: \$pack',
      );
    }

    final existing = await canonicalService.load(concept);
    final emission = const DefaultDistillDelegationService().buildEmission(
      pack: pack,
      concept: concept,
      artifact: artifact,
      existingCanonical: existing,
    );

    return AeResult.ok({
      'mode': 'delegate',
      'concept': concept,
      'pack': pack,
      'seed_rows': emission.task.matrixSeedRows.length,
      'instructions': emission.instructions,
      'next': 'Hand these instructions to your coding agent, save its JSON '
          'response, then run: ae canonical distill --concept \$concept '
          '--from-output <file.json>',
    });
  }

  /// Code-agnostic emit path: shallow-clone a public repo, ingest it via
  /// the generic extractor, and emit delegation instructions from the
  /// resulting artifact pack. The temp clone is deleted before returning.
  Future<AeResult<Map<String, dynamic>>> _emitFromRepo({
    required final String repoUrl,
    required final String concept,
    required final String hubPath,
    required final DefaultCanonicalService canonicalService,
  }) async {
    final cloner = RepoCloner();
    Directory tempDir;
    try {
      tempDir = await cloner.clone(repoUrl);
    } on ProcessException catch (e) {
      return AeResult.fail(
        code: 'repo_clone_failed',
        message: e.message,
      );
    }

    try {
      final artStore = FileArtifactStore(hubPath);
      final packName = await DefaultArtifactService(
        artifactStore: artStore,
        canonicalStore: FileCanonicalStore(hubPath),
        extractorRegistry: HeuristicExtractorRegistry(const [
          DartHeuristicExtractor(),
          RustHeuristicExtractor(),
          KotlinSwiftHeuristicExtractor(),
        ]),
      ).ingest(tempDir);

      // Re-point source.path at the repo URL so sync doesn't chase a
      // deleted temp dir; keep hashed files as the durable record.
      final artifact = await artStore.load(packName);
      if (artifact != null) {
        await artStore.save(artifact);
      }

      final loaded = await artStore.load(packName);
      if (loaded == null) {
        return AeResult.fail(
          code: 'artifact_not_found',
          message: 'Ingested pack vanished: $packName',
        );
      }

      final existing = await canonicalService.load(concept);
      final emission = const DefaultDistillDelegationService().buildEmission(
        pack: packName,
        concept: concept,
        artifact: loaded,
        existingCanonical: existing,
      );

      return AeResult.ok({
        'mode': 'delegate',
        'concept': concept,
        'repo': repoUrl,
        'pack': packName,
        'extractor': loaded.meta.extractor,
        'seed_rows': emission.task.matrixSeedRows.length,
        'instructions': emission.instructions,
        'next': 'Hand these instructions to your coding agent, save its JSON '
            'response, then run: ae canonical distill --concept \$concept '
            '--from-output <file.json>',
      });
    } finally {
      await cloner.cleanup(tempDir);
    }
  }

  Future<AeResult<Map<String, dynamic>>> _handleArtifact(
    final ArgResults command,
  ) async {
    final sub = command.command;
    if (sub == null) {
      return AeResult.fail(
        code: 'invalid_command',
        message: 'Missing artifact subcommand.',
      );
    }
    final root = sub['root']?.toString() ?? Directory.current.path;
    final resolver = FileHubResolver();
    final hubPath = await resolver.resolveHub(projectRoot: root);
    if (hubPath == null) {
      return AeResult.fail(code: 'no_hub', message: 'No hub at $root.');
    }
    final artStore = FileArtifactStore(hubPath);
    final canStore = FileCanonicalStore(hubPath);
    final svc = DefaultArtifactService(
      artifactStore: artStore,
      canonicalStore: canStore,
      extractorRegistry: HeuristicExtractorRegistry(const [
        DartHeuristicExtractor(),
        RustHeuristicExtractor(),
        KotlinSwiftHeuristicExtractor(),
      ]),
    );

    switch (sub.name) {
      case 'list':
        return AeResult.ok({'artifacts': await svc.list()});

      case 'verify':
        final pack = sub['pack']?.toString();
        final strict = sub['strict'] as bool? ?? false;
        final runTests = sub['run-tests'] as bool? ?? false;
        if (pack == null) {
          return AeResult.fail(
            code: 'validation_error',
            message: 'Missing --pack',
          );
        }
        final report = await svc.verifyOne(pack, runTests: runTests);
        if (strict && report.hasBlockingTiers) {
          return AeResult.fail(
            code: 'verify_failed',
            message: 'Pack $pack has blocking-tier entries (--strict)',
            details: report.toJson(),
          );
        }
        return AeResult.ok(report.toJson());

      case 'mark-evidence':
        final pack = sub['pack']?.toString();
        final feature = sub['feature']?.toString();
        final testCommand = sub['test-command']?.toString();
        if (pack == null || feature == null || testCommand == null) {
          return AeResult.fail(
            code: 'validation_error',
            message: 'Missing --pack, --feature, and/or --test-command',
          );
        }
        try {
          final implRaw = sub['impl']?.toString();
          final result = await svc.markEvidence(
            pack,
            feature,
            testCommand: testCommand,
            location: sub['location']?.toString(),
            notes: sub['notes']?.toString(),
            impl: ImplStatus.fromString(implRaw ?? 'done'),
          );
          return AeResult.ok({
            'pack': result.pack,
            'feature_id': result.featureId,
            'cell': result.cell.toJson(),
            'note': 'Evidence recorded. Run ae artifact verify --pack $pack '
                '--run-tests to execute it.',
          });
        } on ArgumentError catch (e) {
          final msg = e.message?.toString() ?? e.toString();
          return AeResult.fail(
            code: msg.contains('not found in pack')
                ? 'feature_not_found'
                : 'artifact_not_found',
            message: msg,
          );
        }

      case 'link':
        final pack = sub['pack']?.toString();
        final canonicalRaw = sub['canonical']?.toString();
        if (pack == null || canonicalRaw == null) {
          return AeResult.fail(
            code: 'validation_error',
            message: 'Missing --pack or --canonical',
          );
        }
        final ref = CanonicalReference.parse(canonicalRaw);
        await svc.link(
          pack,
          ref.conceptId,
          lockedVersion: ref.lockedVersion,
        );
        await svc.materialize(pack);
        return AeResult.ok({
          'pack': pack,
          'canonical': ref.toString(),
        });

      case 'upgrade-canonical':
        final pack = sub['pack']?.toString();
        final concept = sub['canonical']?.toString();
        final toRaw = sub['to']?.toString();
        if (pack == null || concept == null || toRaw == null) {
          return AeResult.fail(
            code: 'validation_error',
            message: 'Missing --pack / --canonical / --to',
          );
        }
        final v = int.tryParse(toRaw);
        if (v == null) {
          return AeResult.fail(
            code: 'validation_error',
            message: '--to must be an integer',
          );
        }
        await svc.upgradeCanonical(pack, concept, toVersion: v);
        await svc.materialize(pack);
        return AeResult.ok({
          'pack': pack,
          'canonical': '$concept@v$v',
        });

      default:
        return AeResult.fail(
          code: 'invalid_command',
          message: 'Unknown artifact subcommand: ${sub.name}',
        );
    }
  }

  Future<AeResult<Map<String, dynamic>>> _handleSpec(
    final ArgResults command,
  ) async {
    final sub = command.command;
    if (sub == null) {
      return AeResult.fail(
        code: 'invalid_command',
        message: 'Missing spec subcommand. See: ae spec --help',
      );
    }
    switch (sub.name) {
      case 'export':
        final outRaw = sub['out']?.toString();
        if (outRaw == null || outRaw.isEmpty) {
          return AeResult.fail(
            code: 'validation_error',
            message: 'Missing required --out',
          );
        }
        final locale = sub['locale']?.toString() ?? 'en';
        final hubOverride = sub['hub']?.toString();
        final root = sub['root']?.toString() ?? Directory.current.path;
        final String hubPath;
        if (hubOverride != null && hubOverride.isNotEmpty) {
          hubPath = hubOverride;
        } else {
          final resolved =
              await FileHubResolver().resolveHub(projectRoot: root);
          if (resolved == null) {
            return AeResult.fail(
              code: 'no_hub',
              message:
                  'No .ae_hub found at $root. Use --hub <path> to point at a hub directly.',
            );
          }
          hubPath = resolved;
        }
        final result = await exportSpec(
          outDir: outRaw,
          hubPath: hubPath,
          locale: locale,
        );
        return AeResult.ok(result.toJson());

      default:
        return AeResult.fail(
          code: 'invalid_command',
          message: 'Unknown spec subcommand: ${sub.name}',
        );
    }
  }

  Future<AeResult<Map<String, dynamic>>> _installOrUpgradeSkill({
    required final String name,
    required final String targetBase,
    required final bool upgrade,
    required final String operation,
    required final bool requireExisting,
    final String? templatePath,
  }) async {
    final SkillTemplateProvider provider;
    if (templatePath != null && templatePath.isNotEmpty) {
      provider = FileSkillTemplateProvider(templatePath);
    } else {
      provider = const EmbeddedSkillTemplateProvider();
    }

    final String template;
    final String? version;
    try {
      template = await provider.readTemplate();
      version = await provider.readVersion();
    } catch (error) {
      return AeResult.fail(
        code: 'skill_template_load_failed',
        message: 'Failed to load skill template',
        details: error.toString(),
      );
    }

    final skillDir = Directory(path.join(targetBase, name));
    final skillFile = File(path.join(skillDir.path, 'SKILL.md'));

    final exists = await skillFile.exists();
    if (!exists && requireExisting) {
      return AeResult.fail(
        code: 'skill_missing',
        message:
            'Skill not found at ${skillDir.path}. Run skill install first.',
      );
    }

    if (!exists) {
      await skillDir.create(recursive: true);
      await skillFile.writeAsString(template);
      if (version != null) {
        await File(
          path.join(skillDir.path, '.ae_cli_skill_version'),
        ).writeAsString(version);
      }

      return AeResult.ok(
        {
          'name': name,
          'target': skillDir.path,
          'installed': true,
          'upgraded': false,
          'version': version,
          'no_op': false,
        },
        meta: {'operation': operation},
      );
    }

    final currentContent = await skillFile.readAsString();
    final currentVersion = await _readInstalledSkillVersion(skillDir.path);

    if (currentContent == template) {
      return AeResult.ok(
        {
          'name': name,
          'target': skillDir.path,
          'installed': false,
          'upgraded': false,
          'version': currentVersion,
          'no_op': true,
          'message': 'Skill already up-to-date',
        },
        meta: {'operation': operation},
      );
    }

    if (!upgrade) {
      return AeResult.fail(
        code: 'skill_upgrade_required',
        message:
            'Skill at ${skillDir.path} differs from bundled template. Re-run with --upgrade to replace it.',
        details: {
          'name': name,
          'target': skillDir.path,
          'installed_version': currentVersion,
          'available_version': version,
        },
      );
    }

    final backupDir = Directory(
      '${skillDir.path}.backup.${DateTime.now().millisecondsSinceEpoch}',
    );
    await _copyDirectory(skillDir, backupDir);

    await skillFile.writeAsString(template);

    if (version != null) {
      await File(
        path.join(skillDir.path, '.ae_cli_skill_version'),
      ).writeAsString(version);
    }

    return AeResult.ok(
      {
        'name': name,
        'target': skillDir.path,
        'installed': false,
        'upgraded': true,
        'previous_version': currentVersion,
        'version': version,
        'backup_path': backupDir.path,
        'no_op': false,
      },
      meta: {'operation': operation},
    );
  }

  Future<void> _copyDirectory(
    final Directory source,
    final Directory destination,
  ) async {
    await destination.create(recursive: true);
    await for (final entity in source.list(recursive: true)) {
      final relative = path.relative(entity.path, from: source.path);
      final targetPath = path.join(destination.path, relative);

      if (entity is Directory) {
        await Directory(targetPath).create(recursive: true);
        continue;
      }
      if (entity is File) {
        await File(targetPath).parent.create(recursive: true);
        await entity.copy(targetPath);
      }
    }
  }

  Future<String?> _readInstalledSkillVersion(final String skillDir) async {
    final markerFile = File(path.join(skillDir, '.ae_cli_skill_version'));
    if (await markerFile.exists()) {
      final marker = (await markerFile.readAsString()).trim();
      if (marker.isNotEmpty) {
        return marker;
      }
    }

    final skillFile = File(path.join(skillDir, 'SKILL.md'));
    if (!await skillFile.exists()) {
      return null;
    }
    final content = await skillFile.readAsString();
    final lines = content.split('\n');
    for (final line in lines) {
      final normalized = line.trim();
      if (normalized.startsWith('<!-- ae-cli-skill-version:')) {
        return normalized
            .replaceFirst('<!-- ae-cli-skill-version:', '')
            .replaceFirst('-->', '')
            .trim();
      }
    }
    return null;
  }

  String _defaultSkillsBaseDir() {
    final envMap = environment ?? Platform.environment;
    final codexHome = envMap['CODEX_HOME'];
    if (codexHome != null && codexHome.isNotEmpty) {
      return path.join(codexHome, 'skills');
    }

    final home = envMap['HOME'] ?? envMap['USERPROFILE'];
    if (home == null || home.isEmpty) {
      throw StateError(
        'Unable to resolve home directory for skill target path',
      );
    }

    return path.join(home, '.codex', 'skills');
  }

  SafeWriteOptions _safeWriteOptions(final ArgResults command) {
    return SafeWriteOptions(
      check: command['check'] == true,
      diff: command['diff'] == true,
      backup: command['backup'] == true,
      noOverwrite: command['no-overwrite'] == true,
    );
  }

  int _renderPackageCommand(
    final String commandPath,
    final Map<String, dynamic> envelope,
  ) {
    if (envelope['success'] != true) {
      final error = envelope['error'] as Map<String, dynamic>?;
      _err.writeln(error?['message'] ?? 'Package command failed');
      if (error?['details'] != null) {
        _err.writeln(error!['details']);
      }
      return 1;
    }

    final data = envelope['data'] as Map<String, dynamic>? ?? const {};
    if (commandPath == 'package resolve') {
      _out.writeln(jsonEncode(data['instructions'] ?? const {}));
    } else if (commandPath == 'package validate') {
      _out.writeln('ok');
    }
    return 0;
  }

  Future<Map<String, dynamic>> _readInstructionsPayload(
    final String source,
  ) async {
    final raw = switch (source) {
      '-' => await stdin.transform(utf8.decoder).join(),
      _ => await (() async {
          final file = File(source);
          if (await file.exists()) {
            return file.readAsString();
          }
          return source;
        })(),
    };
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Instruction JSON must be an object');
    }
    return decoded;
  }

  Future<Map<String, dynamic>> _readInputJson(final String source) async {
    final raw = source == '-'
        ? await stdin.transform(utf8.decoder).join()
        : await File(source).readAsString();

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('Input JSON must be an object');
    }
    return decoded;
  }

  List _parseList(final Object? value) {
    if (value == null) {
      return const [];
    }
    if (value is List) {
      return value;
    }
    if (value is String) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) {
          return decoded;
        }
      } catch (_) {
        return value
            .split(',')
            .map((final part) => part.trim())
            .where((final part) => part.isNotEmpty)
            .toList(growable: false);
      }
    }
    return const [];
  }

  Map _parseMap(final Object? value) {
    if (value == null) {
      return const {};
    }
    if (value is Map) {
      return value;
    }
    if (value is String) {
      try {
        final decoded = jsonDecode(value);
        return decoded is Map ? decoded : const {};
      } catch (_) {
        return const {};
      }
    }
    return const {};
  }

  bool _parseBool(final Object? value) {
    if (value is bool) {
      return value;
    }
    if (value is String) {
      return value.toLowerCase() == 'true';
    }
    return false;
  }

  Map<String, dynamic> _resultToEnvelope(
    final String command,
    final AeResult<Map<String, dynamic>> result,
  ) {
    if (!result.success || result.data == null) {
      return _errorEnvelope(
        command: command,
        code: result.error?.code ?? 'command_failed',
        message: result.error?.message ?? 'Command failed',
        details: result.error?.details,
        warnings: result.warnings,
        meta: result.meta,
      );
    }

    return {
      'success': true,
      'command': command,
      'data': result.data,
      'warnings': result.warnings,
      'meta': result.meta,
    };
  }

  Map<String, dynamic> _errorEnvelope({
    required final String command,
    required final String code,
    required final String message,
    final Object? details,
    final List<String> warnings = const [],
    final Map<String, dynamic> meta = const {},
  }) =>
      {
        'success': false,
        'command': command,
        'data': const {},
        'error': {
          'code': code,
          'message': message,
          if (details != null) 'details': details,
        },
        'warnings': warnings,
        'meta': meta,
      };

  void _printHuman(final Map<String, dynamic> envelope) {
    if (envelope['success'] == true) {
      _out.writeln('Success: ${envelope['command']}');
      _out.writeln(
        const JsonEncoder.withIndent('  ').convert(envelope['data']),
      );
      final warnings = envelope['warnings'] as List<dynamic>?;
      if (warnings != null && warnings.isNotEmpty) {
        _out.writeln('Warnings:');
        for (final warning in warnings) {
          _out.writeln('- $warning');
        }
      }
    } else {
      final error = envelope['error'] as Map<String, dynamic>?;
      _err.writeln(
        'Error [${error?['code'] ?? 'unknown'}]: ${error?['message'] ?? 'Unknown error'}',
      );
      if (error?['details'] != null) {
        _err.writeln(error!['details']);
      }
    }
  }
}
