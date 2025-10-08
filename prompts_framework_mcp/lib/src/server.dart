import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_mcp/server.dart';
import 'package:path/path.dart' as path;

import 'resources/ae_documents.dart';
import 'tools/evaluate_ae_compliance.dart';
import 'tools/get_ae_instructions.dart';
import 'tools/verify_ae_implementation.dart';

/// MCP Server for Agentic Executables Framework.
/// Provides strategic guidance tools for AI agents managing AE.
base class PromptsFrameworkMCPServer extends MCPServer with ToolsSupport {
  late final AEDocuments _documents;
  late final GetAEInstructionsTool _getInstructionsTool;
  late final VerifyAEImplementationTool _verifyTool;
  late final EvaluateAEComplianceTool _evaluateTool;

  PromptsFrameworkMCPServer(
    super.channel, {
    String? resourcesPath,
  }) : super.fromStreamChannel(
          implementation: Implementation(
            name: 'prompts-framework-mcp',
            version: '0.1.0',
          ),
          instructions:
              'Strategic guidance tool for AI agents managing Agentic Executables (AE) framework',
        ) {
    // Determine resources path
    final resolvedPath = resourcesPath ?? _defaultResourcesPath();
    _documents = AEDocuments(resolvedPath);

    // Initialize tools
    _getInstructionsTool = GetAEInstructionsTool(_documents);
    _verifyTool = VerifyAEImplementationTool();
    _evaluateTool = EvaluateAEComplianceTool();

    // Register tools
    registerTool(_createGetInstructionsTool(), _handleGetInstructions);
    registerTool(_createVerifyTool(), _handleVerify);
    registerTool(_createEvaluateTool(), _handleEvaluate);
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

  /// Creates the verify_ae_implementation tool definition.
  Tool _createVerifyTool() => Tool(
        name: 'verify_ae_implementation',
        description:
            'Generates a verification checklist based on AE core principles (Modularity, Reversibility, Validation, Contextual Awareness, Agent Empowerment). Use this to verify implementation compliance.',
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
            'description': Schema.string(
              description:
                  'Brief description of what was implemented for context',
            ),
          },
          required: ['context_type', 'action', 'description'],
        ),
      );

  /// Creates the evaluate_ae_compliance tool definition.
  Tool _createEvaluateTool() => Tool(
        name: 'evaluate_ae_compliance',
        description:
            'Evaluates implementation details against AE core principles and provides compliance scores with recommendations. Returns detailed scoring for Agent Empowerment, Modularity, Contextual Awareness, Reversibility, Validation, and Documentation Quality.',
        inputSchema: Schema.object(
          properties: {
            'implementation_details': Schema.string(
              description:
                  'Detailed description of the implementation to evaluate',
            ),
            'context_type': Schema.string(
              description: 'Context: "library" or "project"',
              enumValues: ['library', 'project'],
            ),
          },
          required: ['implementation_details', 'context_type'],
        ),
      );

  /// Handles get_ae_instructions tool calls.
  Future<CallToolResult> _handleGetInstructions(CallToolRequest request) async {
    final result = await _getInstructionsTool.execute(request.arguments ?? {});
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

  /// Formats result as pretty JSON string.
  String _formatJson(Map<String, dynamic> data) => jsonEncode(data);
}
