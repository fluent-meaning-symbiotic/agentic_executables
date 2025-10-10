import 'dart:io';

import 'package:dart_mcp/stdio.dart';
import 'package:prompts_framework_mcp/src/ae_framework_config.dart';
import 'package:prompts_framework_mcp/src/server.dart';

/// Entry point for the Prompts Framework MCP Server.
/// Communicates via STDIO transport for MCP protocol.
Future<void> main(final List<String> args) async {
  // Get version from config
  final version = await AEFrameworkConfig.getVersion();

  // Log to stderr (stdout is reserved for MCP protocol)
  stderr.writeln('Prompts Framework MCP Server starting...');
  stderr.writeln('Version: $version');
  stderr.writeln('Protocol: Model Context Protocol (MCP)');

  try {
    // Create and initialize the server with STDIO channel
    PromptsFrameworkMCPServer(
      stdioChannel(input: stdin, output: stdout),
      version: version,
    );

    stderr.writeln('Server started successfully. Waiting for connections...');
  } catch (e, stack) {
    stderr.writeln('Error starting server: $e');
    stderr.writeln('Stack trace: $stack');
    exit(1);
  }
}
