import 'dart:io';

import 'package:meta/meta.dart';
// import 'package:dart_mcp/server.dart'; // Integrate once wiring is implemented

@immutable
class ResourceDescriptor {
  const ResourceDescriptor({required this.uri, required this.filePath});
  final String uri;
  final String filePath;
}

class PromptsFrameworkServer {
  PromptsFrameworkServer();

  Future<void> serveStdio() async {
    // TODO: Wire up dart_mcp STDIO transport and register tools/resources.
    stderr.writeln('[prompts_framework_mcp] STDIO server stub started.');
  }

  List<ResourceDescriptor> get resources => <ResourceDescriptor>[
    ResourceDescriptor(
      uri: 'resource://prompts_framework/ae_context.md',
      filePath: '${Directory.current.path}/prompts_framework/ae_context.md',
    ),
    ResourceDescriptor(
      uri: 'resource://prompts_framework/ae_boostrap.md',
      filePath: '${Directory.current.path}/prompts_framework/ae_boostrap.md',
    ),
    ResourceDescriptor(
      uri: 'resource://prompts_framework/ae_use.md',
      filePath: '${Directory.current.path}/prompts_framework/ae_use.md',
    ),
  ];
}
