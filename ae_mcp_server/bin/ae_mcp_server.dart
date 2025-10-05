#!/usr/bin/env dart

/// Main executable for AE MCP Server
import 'dart:io';

import 'package:ae_mcp_server/ae_mcp_server.dart';

/// Main entry point for the AE MCP Server
Future<void> main(List<String> arguments) async {
  // Create server
  final server = AEMCPServer();

  try {
    // Initialize the server
    await server.initialize();

    // Keep the server running
    print('AE MCP Server initialized successfully');
    print(
        'Available tools: bootstrap_ae, improve_ae_bootstrap, install_ae, uninstall_ae');

    // Simple command loop for testing
    while (true) {
      stdout.write('AE> ');
      final input = stdin.readLineSync();
      if (input == null || input.toLowerCase() == 'exit') {
        break;
      }

      // Parse and execute commands
      final parts = input.split(' ');
      if (parts.isNotEmpty) {
        final toolName = parts[0];
        final args = <String, dynamic>{};

        // Simple argument parsing
        for (int i = 1; i < parts.length; i += 2) {
          if (i + 1 < parts.length) {
            args[parts[i]] = parts[i + 1];
          }
        }

        try {
          final result = await server.callTool(toolName, args);
          print('Result: $result');
        } catch (e) {
          print('Error: $e');
        }
      }
    }
  } catch (e) {
    stderr.writeln('Failed to start AE MCP Server: $e');
    exit(1);
  }
}
