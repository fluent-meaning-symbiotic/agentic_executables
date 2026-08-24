import 'dart:convert';
import 'dart:io';

import 'package:dart_mcp/server.dart';
import 'package:path/path.dart' as path;

import 'adapter.dart';

/// MCP v3 thin adapter for Agentic Executables core services.
base class AgenticExecutablesMcpServer extends MCPServer with ToolsSupport {
  AgenticExecutablesMcpServer(
    super.channel, {
    final String? resourcesPath,
    final String? version,
  }) : super.fromStreamChannel(
          implementation: Implementation(
            name: 'agentic-executables-mcp',
            version: version ?? '3.2.0',
          ),
          instructions: '''
Agentic Executables MCP v3 (thin adapter over shared core).

TOOLS:
- ae_definition
- ae_instructions
- ae_generate
- ae_registry
- ae_verify
- ae_evaluate
- ae_hub
- ae_init
- ae_status
- ae_sync
- ae_canonical
- ae_artifact
- ae_doctor
- ae_package
''',
        ) {
    _adapter =
        AeMcpAdapter(resourcesPath: resourcesPath ?? _defaultResourcesPath());

    registerTool(_toolDefinition(), _handleDefinition);
    registerTool(_toolInstructions(), _handleInstructions);
    registerTool(_toolGenerate(), _handleGenerate);
    registerTool(_toolRegistry(), _handleRegistry);
    registerTool(_toolVerify(), _handleVerify);
    registerTool(_toolEvaluate(), _handleEvaluate);
    registerTool(_toolHub(), _handleHub);
    registerTool(_toolInit(), _handleInit);
    registerTool(_toolStatus(), _handleStatus);
    registerTool(_toolSync(), _handleSync);
    registerTool(_toolCanonical(), _handleCanonical);
    registerTool(_toolArtifact(), _handleArtifact);
    registerTool(_toolDoctor(), _handleDoctor);
    registerTool(_toolPackage(), _handlePackage);
  }

  late final AeMcpAdapter _adapter;

  String _defaultResourcesPath() {
    final executable = Platform.resolvedExecutable;
    final execDir = path.dirname(executable);

    var resourcesDir = path.join(execDir, '..', 'resources');
    if (Directory(resourcesDir).existsSync()) {
      return path.normalize(resourcesDir);
    }

    resourcesDir = path.join(Directory.current.path, 'resources');
    if (Directory(resourcesDir).existsSync()) {
      return path.normalize(resourcesDir);
    }

    resourcesDir = path.join(
      path.dirname(Platform.script.toFilePath()),
      '..',
      '..',
      'resources',
    );
    return path.normalize(resourcesDir);
  }

  Tool _toolDefinition() => Tool(
        name: 'ae_definition',
        description: 'Get core AE definition and framework overview.',
        inputSchema: Schema.object(properties: {}),
      );

  Tool _toolInstructions() => Tool(
        name: 'ae_instructions',
        description:
            'Retrieve AE instructions for context (library/project) and action.',
        inputSchema: Schema.object(
          properties: {
            'context_type': Schema.string(
              enumValues: ['library', 'project'],
            ),
            'action': Schema.string(
              enumValues: [
                'bootstrap',
                'install',
                'uninstall',
                'update',
                'use',
              ],
            ),
            'know_name': Schema.string(),
          },
          required: ['context_type', 'action'],
        ),
      );

  Tool _toolGenerate() => Tool(
        name: 'ae_generate',
        description:
            'Generate AE files using auto|template engine selection (auto resolves to template in MCP).',
        inputSchema: Schema.object(
          properties: {
            'library_id': Schema.string(),
            'library_root': Schema.string(),
            'output_dir': Schema.string(),
            'engine': Schema.string(
              enumValues: ['auto', 'template'],
            ),
            'dry_run': Schema.bool(),
            'know_name': Schema.string(),
          },
          required: ['library_id', 'library_root'],
        ),
      );

  Tool _toolRegistry() => Tool(
        name: 'ae_registry',
        description:
            'Registry operations: submit_to_registry, get_from_registry, bootstrap_local_registry.',
        inputSchema: Schema.object(
          properties: {
            'operation': Schema.string(
              enumValues: [
                'submit_to_registry',
                'get_from_registry',
                'bootstrap_local_registry',
              ],
            ),
            'library_url': Schema.string(),
            'library_id': Schema.string(),
            'ae_use_files': Schema.string(),
            'action': Schema.string(
              enumValues: ['install', 'uninstall', 'update', 'use'],
            ),
            'ae_use_path': Schema.string(),
          },
          required: ['operation'],
        ),
      );

  Tool _toolVerify() => Tool(
        name: 'ae_verify',
        description:
            'Verify AE implementation using typed checklist input. Legacy string-encoded JSON payloads are rejected.',
        inputSchema: Schema.object(
          properties: {
            'context_type': Schema.string(
              enumValues: ['library', 'project'],
            ),
            'action': Schema.string(
              enumValues: [
                'bootstrap',
                'install',
                'uninstall',
                'update',
                'use',
              ],
            ),
            'files_modified': Schema.list(
              items: Schema.object(
                properties: {
                  'path': Schema.string(),
                  'loc': Schema.int(),
                  'sections': Schema.list(items: Schema.string()),
                },
                required: ['path', 'loc'],
                additionalProperties: false,
              ),
            ),
            'checklist_completed': Schema.object(
              additionalProperties: Schema.bool(),
            ),
          },
          required: ['context_type', 'action'],
        ),
      );

  Tool _toolEvaluate() => Tool(
        name: 'ae_evaluate',
        description:
            'Evaluate AE compliance using typed payload fields. Legacy string-encoded JSON payloads are rejected.',
        inputSchema: Schema.object(
          properties: {
            'context_type': Schema.string(
              enumValues: ['library', 'project'],
            ),
            'action': Schema.string(
              enumValues: [
                'bootstrap',
                'install',
                'uninstall',
                'update',
                'use',
              ],
            ),
            'files_created': Schema.list(
              items: Schema.object(
                properties: {
                  'path': Schema.string(),
                  'loc': Schema.int(),
                },
                required: ['path', 'loc'],
                additionalProperties: false,
              ),
            ),
            'sections_present': Schema.list(items: Schema.string()),
            'validation_steps_exists': Schema.bool(),
            'integration_points_defined': Schema.bool(),
            'reversibility_included': Schema.bool(),
            'has_meta_rules': Schema.bool(),
          },
          required: ['context_type', 'action'],
        ),
      );

  Tool _toolHub() => Tool(
        name: 'ae_hub',
        description: 'Hub management: init, status, pull, push.',
        inputSchema: Schema.object(
          properties: {
            'operation': Schema.string(
              enumValues: ['init', 'status', 'pull', 'push'],
            ),
            'path': Schema.string(),
            'project': Schema.bool(),
            'hub_path': Schema.string(),
            'remote': Schema.string(),
            'library_id': Schema.string(),
            'type': Schema.string(
              enumValues: ['know', 'use', 'packages'],
            ),
          },
          required: ['operation'],
        ),
      );

  Tool _toolInit() => Tool(
        name: 'ae_init',
        description:
            'Scan project for known language manifests and ingest each '
            'sub-package as a local artifact.',
        inputSchema: Schema.object(
          properties: {
            'root': Schema.string(
              description: 'Project root path (default: cwd).',
            ),
            'strict': Schema.bool(
              description: 'Exit non-zero on unhandled subdirectories.',
            ),
          },
        ),
      );

  Future<CallToolResult> _handleInit(final CallToolRequest request) async {
    final result = await _adapter.init(request.arguments ?? {});
    return _result(result);
  }

  Tool _toolStatus() => Tool(
        name: 'ae_status',
        description: 'Project-wide tier-classified gap report. '
            'Tier 1 invariant violations, 2 upstream blockers, '
            '3 partial features, 4 unreferenced canonicals.',
        inputSchema: Schema.object(
          properties: {
            'root': Schema.string(),
            'pack': Schema.string(
              description: 'Narrow to a single artifact pack (verifyOne).',
            ),
            'tier': Schema.string(
              description: 'Show only entries at this tier (1-4).',
            ),
          },
        ),
      );

  Future<CallToolResult> _handleStatus(final CallToolRequest request) async {
    final result = await _adapter.status(request.arguments ?? {});
    return _result(result);
  }

  Tool _toolSync() => Tool(
        name: 'ae_sync',
        description: 'Re-scan source files for artifact packs and report drift '
            '(code + intent). Pass prune=true to remove artifacts whose '
            'source path no longer exists.',
        inputSchema: Schema.object(
          properties: {
            'root': Schema.string(),
            'pack': Schema.string(
              description: 'Sync only the named pack (default: all).',
            ),
            'prune': Schema.bool(
              description:
                  'Remove artifacts whose source path no longer exists '
                  '(spec §6.2).',
            ),
          },
        ),
      );

  Future<CallToolResult> _handleSync(final CallToolRequest request) async {
    final result = await _adapter.sync(request.arguments ?? {});
    return _result(result);
  }

  Tool _toolCanonical() => Tool(
        name: 'ae_canonical',
        description:
            'Canonical pack operations: init, scaffold, list, snapshot, '
            'diff, import, distill.',
        inputSchema: Schema.object(
          properties: {
            'operation': Schema.string(
              enumValues: [
                'init',
                'scaffold',
                'list',
                'snapshot',
                'diff',
                'import',
                'distill',
              ],
            ),
            'concept': Schema.string(),
            'title': Schema.string(),
            'from': Schema.string(),
            'to': Schema.string(),
            'as': Schema.string(),
            'pack': Schema.string(),
            'mode': Schema.string(enumValues: ['upsert', 'refine']),
            'from_artifact': Schema.string(
              description:
                  'Artifact pack name (string or list of strings) for the '
                  'scaffold operation.',
            ),
            'overwrite': Schema.bool(
              description: 'Replace an existing canonical at "concept" '
                  '(scaffold operation).',
            ),
            'root': Schema.string(),
          },
          required: ['operation'],
        ),
      );

  Future<CallToolResult> _handleCanonical(
    final CallToolRequest request,
  ) async {
    final result = await _adapter.canonical(request.arguments ?? {});
    return _result(result);
  }

  Tool _toolArtifact() => Tool(
        name: 'ae_artifact',
        description:
            'Artifact pack operations: list, verify, link, upgrade-canonical.',
        inputSchema: Schema.object(
          properties: {
            'operation': Schema.string(
              enumValues: ['list', 'verify', 'link', 'upgrade-canonical'],
            ),
            'pack': Schema.string(),
            'canonical': Schema.string(),
            'to': Schema.string(),
            'strict': Schema.bool(),
            'root': Schema.string(),
          },
          required: ['operation'],
        ),
      );

  Future<CallToolResult> _handleArtifact(
    final CallToolRequest request,
  ) async {
    final result = await _adapter.artifact(request.arguments ?? {});
    return _result(result);
  }

  Tool _toolDoctor() => Tool(
        name: 'ae_doctor',
        description:
            'Preflight checks: codex availability, Dart SDK, skill target '
            'writability (critical), and registry reachability (critical). '
            'Spec §13.',
        inputSchema: Schema.object(
          properties: {
            'target': Schema.string(
              description: 'Skill target directory to probe for writability '
                  '(e.g. ~/.codex/skills).',
            ),
          },
          required: ['target'],
        ),
      );

  Future<CallToolResult> _handleDoctor(final CallToolRequest request) async {
    final result = await _adapter.doctor(request.arguments ?? {});
    return _result(result);
  }

  Tool _toolPackage() => Tool(
        name: 'ae_package',
        description: 'Resolve / validate Lythe-compatible package instructions '
            '(`ae.v3.package.v1`). Spec §13.',
        inputSchema: Schema.object(
          properties: {
            'operation': Schema.string(
              enumValues: ['resolve', 'validate'],
            ),
            'package': Schema.string(
              description: 'Package id (required for resolve).',
            ),
            'target': Schema.string(
              description: 'Runtime target (default: linux).',
            ),
            'format': Schema.string(
              description: 'Output format (default: json).',
            ),
            'package_root': Schema.string(
              description: 'Optional path to detect the package version from a '
                  'pubspec.yaml / package.json / pyproject.toml.',
            ),
            'instructions': Schema.string(
              description:
                  'Instruction payload for validate: a JSON object, an '
                  'inline JSON string, or a path to a JSON file.',
            ),
          },
          required: ['operation'],
        ),
      );

  Future<CallToolResult> _handlePackage(final CallToolRequest request) async {
    final result = await _adapter.package(request.arguments ?? {});
    return _result(result);
  }

  Future<CallToolResult> _handleHub(final CallToolRequest request) async {
    final result = await _adapter.hub(request.arguments ?? {});
    return _result(result);
  }

  Future<CallToolResult> _handleDefinition(
      final CallToolRequest request,) async {
    final result = await _adapter.definition(request.arguments ?? {});
    return _result(result);
  }

  Future<CallToolResult> _handleInstructions(
    final CallToolRequest request,
  ) async {
    final result = await _adapter.instructions(request.arguments ?? {});
    return _result(result);
  }

  Future<CallToolResult> _handleGenerate(final CallToolRequest request) async {
    final result = await _adapter.generate(request.arguments ?? {});
    return _result(result);
  }

  Future<CallToolResult> _handleRegistry(final CallToolRequest request) async {
    final result = await _adapter.registry(request.arguments ?? {});
    return _result(result);
  }

  Future<CallToolResult> _handleVerify(final CallToolRequest request) async {
    final result = await _adapter.verify(request.arguments ?? {});
    return _result(result);
  }

  Future<CallToolResult> _handleEvaluate(final CallToolRequest request) async {
    final result = await _adapter.evaluate(request.arguments ?? {});
    return _result(result);
  }

  CallToolResult _result(final Map<String, dynamic> payload) => CallToolResult(
        content: [
          TextContent(text: jsonEncode(payload)),
        ],
      );
}
