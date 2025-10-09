import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_mcp/server.dart';
import 'package:path/path.dart' as path;

import 'resources/ae_documents.dart';
import 'tools/evaluate_ae_compliance.dart';
import 'tools/get_ae_instructions.dart';
import 'tools/get_agentic_executable_definition.dart';
import 'tools/manage_ae_registry.dart';
import 'tools/verify_ae_implementation.dart';

/// MCP Server for Agentic Executables Framework.
/// Provides strategic guidance tools for AI agents managing AE.
base class PromptsFrameworkMCPServer extends MCPServer with ToolsSupport {
  late final AEDocuments _documents;
  late final GetAEInstructionsTool _getInstructionsTool;
  late final GetAgenticExecutableDefinitionTool _getDefinitionTool;
  late final VerifyAEImplementationTool _verifyTool;
  late final EvaluateAEComplianceTool _evaluateTool;
  late final ManageAERegistryTool _manageRegistryTool;

  PromptsFrameworkMCPServer(
    super.channel, {
    String? resourcesPath,
  }) : super.fromStreamChannel(
          implementation: Implementation(
            name: 'prompts-framework-mcp',
            version: '0.1.0',
          ),
          instructions: '''
Agentic Executables (AE): Libraries/packages managed by AI agents as executable programs for installation, configuration, usage, and uninstallation.

CONTEXTS & ACTIONS:
- Contexts: "library" (maintain AE files) | "project" (use AE in projects)
- Actions: bootstrap, install, uninstall, update, use

TOOLS:
- get_agentic_executable_definition: Get core AE definition and framework overview (use this first if unfamiliar with AE)
- get_ae_instructions: Retrieve contextual documentation for context+action combination
- verify_ae_implementation: Generate verification checklist based on AE principles
- evaluate_ae_compliance: Score implementation compliance with detailed feedback
- manage_ae_registry: Submit libraries to registry (authors) or fetch library files from registry (developers)

USAGE:
Library maintainers: Call get_ae_instructions(context="library", action="bootstrap") to create AE files, then manage_ae_registry(operation="submit_to_registry") to publish to registry.
Project developers: Call manage_ae_registry(operation="get_from_registry") to fetch library instructions, then follow the returned ae_install.md/ae_uninstall.md content.
After implementation: Call verify_ae_implementation for checklist, then evaluate_ae_compliance for scoring.

CORE PRINCIPLES: Agent Empowerment, Modularity, Contextual Awareness, Reversibility, Validation, Documentation Focus.

This server provides strategic guidance; full documentation comes from tool responses.
''',
        ) {
    // Determine resources path
    final resolvedPath = resourcesPath ?? _defaultResourcesPath();
    _documents = AEDocuments(resolvedPath);

    // Initialize tools
    _getInstructionsTool = GetAEInstructionsTool(_documents);
    _getDefinitionTool = GetAgenticExecutableDefinitionTool();
    _verifyTool = VerifyAEImplementationTool();
    _evaluateTool = EvaluateAEComplianceTool();
    _manageRegistryTool = ManageAERegistryTool();

    // Register tools
    registerTool(_createGetInstructionsTool(), _handleGetInstructions);
    registerTool(_createGetDefinitionTool(), _handleGetDefinition);
    registerTool(_createVerifyTool(), _handleVerify);
    registerTool(_createEvaluateTool(), _handleEvaluate);
    registerTool(_createManageRegistryTool(), _handleManageRegistry);
  }

  /// Determines the default resources path relative to the executable.
  String _defaultResourcesPath() {
    // When compiled as executable, resources should be in ../resources
    // When running via dart run, they're in resources/
    final executable = Platform.resolvedExecutable;
    final execDir = path.dirname(executable);

    // Check for compiled executable layout first
    var resourcesDir = path.join(execDir, '..', 'resources');
    if (Directory(resourcesDir).existsSync()) {
      return path.normalize(resourcesDir);
    }

    // Fall back to development layout
    resourcesDir = path.join(Directory.current.path, 'resources');
    if (Directory(resourcesDir).existsSync()) {
      return path.normalize(resourcesDir);
    }

    // Last resort: try relative to script
    resourcesDir = path.join(
      path.dirname(Platform.script.toFilePath()),
      '..',
      '..',
      'resources',
    );
    return path.normalize(resourcesDir);
  }

  /// Creates the get_ae_instructions tool definition.
  Tool _createGetInstructionsTool() => Tool(
        name: 'get_ae_instructions',
        description:
            'Retrieves AE framework instructions based on context (library/project) and action (bootstrap/install/uninstall/update/use). Returns relevant documentation files with guidance for AI agents.',
        inputSchema: Schema.object(
          properties: {
            'context_type': Schema.string(
              description:
                  'Context: "library" for maintaining AE files, "project" for using AE in projects',
              enumValues: ['library', 'project'],
            ),
            'action': Schema.string(
              description:
                  'Action to perform: bootstrap (library only), install, uninstall, update, or use',
              enumValues: [
                'bootstrap',
                'install',
                'uninstall',
                'update',
                'use'
              ],
            ),
          },
          required: ['context_type', 'action'],
        ),
      );

  /// Creates the get_agentic_executable_definition tool definition.
  Tool _createGetDefinitionTool() => Tool(
        name: 'get_agentic_executable_definition',
        description:
            'Retrieves the core Agentic Executable (AE) definition, framework overview, available tools, and core principles. Use this tool when you need to understand what AE is, which contexts and actions are available, or which tools you can use. Essential for agents without access to server instructions.',
        inputSchema: Schema.object(
          properties: {},
        ),
      );

  /// Creates the verify_ae_implementation tool definition.
  Tool _createVerifyTool() => Tool(
        name: 'verify_ae_implementation',
        description:
            '''Verifies AE implementation using structured metrics. Agent provides checklist completion status and file modifications, MCP performs objective verification with pass/fail results.

Expected input format:
{
  "context_type": "library" or "project",
  "action": "bootstrap"|"install"|"uninstall"|"update"|"use",
  "files_modified": [
    {"path": "ae_install.md", "loc": 180, "sections": ["Installation", "Configuration"]}
  ],
  "checklist_completed": {
    "modularity": true,
    "contextual_awareness": true,
    "agent_empowerment": false,
    "validation": true,
    "integration": true,
    "reversibility": true,
    "cleanup": true,
    "migration": true,
    "backup_rollback": true,
    "best_practices": true,
    "anti_patterns": true,
    "analysis_guidance": true,
    "file_generation_rules": true,
    "abstraction": true
  }
}''',
        inputSchema: Schema.object(
          properties: {
            'context_type': Schema.string(
              description: 'Context: "library" or "project"',
              enumValues: ['library', 'project'],
            ),
            'action': Schema.string(
              description: 'Action that was performed',
              enumValues: [
                'bootstrap',
                'install',
                'uninstall',
                'update',
                'use'
              ],
            ),
            'files_modified': Schema.string(
              description:
                  'JSON string array of file objects: [{"path": "ae_install.md", "loc": 180, "sections": ["Installation"]}]',
            ),
            'checklist_completed': Schema.string(
              description:
                  'JSON string object of checklist items: {"modularity": true, "contextual_awareness": true, ...}',
            ),
          },
          required: ['context_type', 'action'],
        ),
      );

  /// Creates the evaluate_ae_compliance tool definition.
  Tool _createEvaluateTool() => Tool(
        name: 'evaluate_ae_compliance',
        description:
            '''Evaluates AE implementation using structured metrics and hardcoded scoring. Agent provides concrete data (files, LOC, sections, flags), MCP performs objective pass/fail evaluation. Favors concise documentation (lower LOC = better score).

Expected input format:
{
  "context_type": "library" or "project",
  "action": "bootstrap"|"install"|"uninstall"|"update"|"use",
  "files_created": [
    {"path": "ae_install.md", "loc": 150},
    {"path": "ae_uninstall.md", "loc": 80}
  ],
  "sections_present": ["Installation", "Configuration", "Integration", "Validation"],
  "validation_steps_exists": true,
  "integration_points_defined": true,
  "reversibility_included": true,
  "has_meta_rules": true
}

LOC Scoring: <500=PASS, 500-800=WARNING, >800=FAIL (lower is better)''',
        inputSchema: Schema.object(
          properties: {
            'context_type': Schema.string(
              description: 'Context: "library" or "project"',
              enumValues: ['library', 'project'],
            ),
            'action': Schema.string(
              description: 'Action that was performed',
              enumValues: [
                'bootstrap',
                'install',
                'uninstall',
                'update',
                'use'
              ],
            ),
            'files_created': Schema.string(
              description:
                  'JSON string array of file objects: [{"path": "ae_install.md", "loc": 150}]',
            ),
            'sections_present': Schema.string(
              description:
                  'JSON string array of section names: ["Installation", "Configuration", "Validation"]',
            ),
            'validation_steps_exists': Schema.string(
              description: 'Boolean string: "true" or "false"',
            ),
            'integration_points_defined': Schema.string(
              description: 'Boolean string: "true" or "false"',
            ),
            'reversibility_included': Schema.string(
              description: 'Boolean string: "true" or "false"',
            ),
            'has_meta_rules': Schema.string(
              description: 'Boolean string: "true" or "false"',
            ),
          },
          required: ['context_type', 'action'],
        ),
      );

  /// Handles get_ae_instructions tool calls.
  Future<CallToolResult> _handleGetInstructions(CallToolRequest request) async {
    final result = await _getInstructionsTool.execute(request.arguments ?? {});
    return CallToolResult(
      content: [TextContent(text: _formatJson(result))],
    );
  }

  /// Handles get_agentic_executable_definition tool calls.
  Future<CallToolResult> _handleGetDefinition(CallToolRequest request) async {
    final result = _getDefinitionTool.execute(request.arguments ?? {});
    return CallToolResult(
      content: [TextContent(text: _formatJson(result))],
    );
  }

  /// Handles verify_ae_implementation tool calls.
  Future<CallToolResult> _handleVerify(CallToolRequest request) async {
    final result = _verifyTool.execute(request.arguments ?? {});
    return CallToolResult(
      content: [TextContent(text: _formatJson(result))],
    );
  }

  /// Handles evaluate_ae_compliance tool calls.
  Future<CallToolResult> _handleEvaluate(CallToolRequest request) async {
    final result = _evaluateTool.execute(request.arguments ?? {});
    return CallToolResult(
      content: [TextContent(text: _formatJson(result))],
    );
  }

  /// Creates the manage_ae_registry tool definition.
  Tool _createManageRegistryTool() => Tool(
        name: 'manage_ae_registry',
        description: '''Manages AE registry for library authors and developers.

OPERATIONS:
1. submit_to_registry: Generate PR instructions for library authors to submit/update library AE files
2. get_from_registry: Fetch library AE files directly from registry for developers
3. bootstrap_local_registry: Set up local registry structure for monorepos

LIBRARY AUTHORS:
Use submit_to_registry after creating ae_use folder with all required files.
Provides PR instructions and file mappings for contributing to the registry.

DEVELOPERS:
Use get_from_registry to fetch ae_install.md, ae_uninstall.md, ae_update.md, or ae_use.md
Returns file content directly from GitHub registry (no auth required).

MONOREPO:
Use bootstrap_local_registry to create registry structure for internal libraries.''',
        inputSchema: Schema.object(
          properties: {
            'operation': Schema.string(
              description: 'Operation type',
              enumValues: [
                'submit_to_registry',
                'get_from_registry',
                'bootstrap_local_registry'
              ],
            ),
            'library_url': Schema.string(
              description:
                  'GitHub repository URL (for submit_to_registry). Example: https://github.com/owner/repo',
            ),
            'library_id': Schema.string(
              description:
                  'Library identifier in format <language>_<library_name> (for submit_to_registry and get_from_registry). Example: dart_provider, python_requests',
            ),
            'ae_use_files': Schema.string(
              description:
                  'Comma-separated list of ae_use file paths from library (for submit_to_registry). Example: ae_use/ae_install.md,ae_use/ae_uninstall.md,ae_use/ae_update.md,ae_use/ae_use.md',
            ),
            'action': Schema.string(
              description:
                  'Action to fetch from registry (for get_from_registry)',
              enumValues: ['install', 'uninstall', 'update', 'use'],
            ),
            'ae_use_path': Schema.string(
              description:
                  'Path to local ae_use folder (for bootstrap_local_registry)',
            ),
          },
          required: ['operation'],
        ),
      );

  /// Handles manage_ae_registry tool calls.
  Future<CallToolResult> _handleManageRegistry(
    CallToolRequest request,
  ) async {
    final result = await _manageRegistryTool.execute(request.arguments ?? {});
    return CallToolResult(
      content: [TextContent(text: _formatJson(result))],
    );
  }

  /// Formats result as pretty JSON string.
  String _formatJson(Map<String, dynamic> data) => jsonEncode(data);
}
