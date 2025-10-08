import 'dart:io';

import 'package:dart_mcp/stdio.dart';
import 'package:prompts_framework_mcp/src/server.dart';

/// Entry point for the Prompts Framework MCP Server.
/// Communicates via STDIO transport for MCP protocol.
void main(List<String> args) {
  // Log to stderr (stdout is reserved for MCP protocol)
  stderr.writeln('Prompts Framework MCP Server starting...');
  stderr.writeln('Version: 0.1.0');
  stderr.writeln('Protocol: Model Context Protocol (MCP)');

  try {
    // Create and initialize the server with STDIO channel
    PromptsFrameworkMCPServer(
      stdioChannel(input: stdin, output: stdout),
    );

    stderr.writeln('Server started successfully. Waiting for connections...');
  } catch (e, stack) {
    stderr.writeln('Error starting server: $e');
    stderr.writeln('Stack trace: $stack');
    exit(1);
  }
}
