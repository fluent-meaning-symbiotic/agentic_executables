import 'dart:io';

import 'package:prompts_framework_mcp/server/prompts_framework_server.dart';

Future<void> main(List<String> args) async {
  final server = PromptsFrameworkServer();
  await server.serveStdio();
  // Keep process alive if needed (stub)
  if (args.contains('--stay-alive')) {
    await stdin.first;
  }
}
