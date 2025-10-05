/// Main MCP server for Agentic Executable (AE) framework
library ae_mcp_server;

import 'tools/bootstrap_tool.dart';
import 'tools/improve_tool.dart';
import 'tools/install_tool.dart';
import 'tools/uninstall_tool.dart';

/// MCP Server for Agentic Executable framework management
class AEMCPServer {
  AEMCPServer();

  /// Initialize the MCP server
  Future<void> initialize() async {
    // Server initialization logic would go here
    // For now, we'll just mark as initialized
  }

  /// Handle tool calls
  Future<Map<String, dynamic>> callTool(
    String name,
    Map<String, dynamic> arguments,
  ) async {
    switch (name) {
      case 'bootstrap_ae':
        return await _handleBootstrapAE(arguments);
      case 'improve_ae_bootstrap':
        return await _handleImproveAEBootstrap(arguments);
      case 'install_ae':
        return await _handleInstallAE(arguments);
      case 'uninstall_ae':
        return await _handleUninstallAE(arguments);
      default:
        throw Exception('Unknown tool: $name');
    }
  }

  /// Handle bootstrap AE tool
  Future<Map<String, dynamic>> _handleBootstrapAE(
    Map<String, dynamic> arguments,
  ) async {
    final libraryPath = arguments['libraryPath'] as String;
    final targetAIAgent = arguments['targetAIAgent'] as String;
    final options = arguments['options'] as Map<String, dynamic>?;

    final result = await BootstrapTool.bootstrapAE(
      libraryPath: libraryPath,
      targetAIAgent: targetAIAgent,
      options: options,
    );

    return result.toJson();
  }

  /// Handle improve AE bootstrap tool
  Future<Map<String, dynamic>> _handleImproveAEBootstrap(
    Map<String, dynamic> arguments,
  ) async {
    final libraryPath = arguments['libraryPath'] as String;
    final improvementGoals = (arguments['improvementGoals'] as List<dynamic>)
        .map((e) => e as String)
        .toList();
    final options = arguments['options'] as Map<String, dynamic>?;

    final result = await ImproveTool.improveAEBootstrap(
      libraryPath: libraryPath,
      improvementGoals: improvementGoals,
      options: options,
    );

    return result.toJson();
  }

  /// Handle install AE tool
  Future<Map<String, dynamic>> _handleInstallAE(
    Map<String, dynamic> arguments,
  ) async {
    final libraryPath = arguments['libraryPath'] as String;
    final targetProjectPath = arguments['targetProjectPath'] as String;
    final options = arguments['options'] as Map<String, dynamic>?;

    final result = await InstallTool.installAE(
      libraryPath: libraryPath,
      targetProjectPath: targetProjectPath,
      options: options,
    );

    return result.toJson();
  }

  /// Handle uninstall AE tool
  Future<Map<String, dynamic>> _handleUninstallAE(
    Map<String, dynamic> arguments,
  ) async {
    final libraryPath = arguments['libraryPath'] as String;
    final targetProjectPath = arguments['targetProjectPath'] as String;
    final options = arguments['options'] as Map<String, dynamic>?;

    final result = await UninstallTool.uninstallAE(
      libraryPath: libraryPath,
      targetProjectPath: targetProjectPath,
      options: options,
    );

    return result.toJson();
  }
}
