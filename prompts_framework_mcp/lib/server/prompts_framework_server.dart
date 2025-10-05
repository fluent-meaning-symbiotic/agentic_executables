import 'dart:io';

import 'package:meta/meta.dart';
// import 'package:dart_mcp/server.dart';
import 'package:prompts_framework_mcp/tools/bootstrap_ae.dart' as bootstrap;
import 'package:prompts_framework_mcp/tools/improve_ae_bootstrap.dart'
    as improve;
import 'package:prompts_framework_mcp/tools/install_library_as_ae.dart'
    as install;
import 'package:prompts_framework_mcp/tools/uninstall_library_as_ae.dart'
    as uninstall;

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
      uri: 'resource://prompts_framework/ae_bootstrap.md',
      filePath: '${Directory.current.path}/prompts_framework/ae_bootstrap.md',
    ),
    ResourceDescriptor(
      uri: 'resource://prompts_framework/ae_use.md',
      filePath: '${Directory.current.path}/prompts_framework/ae_use.md',
    ),
  ];

  // Schemas to advertise via MCP Tools API (when wired)
  Map<String, Object?> get bootstrapInputSchema => <String, Object?>{
    'type': 'object',
    'required': <String>['root_path', 'library_name'],
    'properties': <String, Object?>{
      'root_path': <String, Object?>{'type': 'string'},
      'library_name': <String, Object?>{'type': 'string'},
      'output_dir': <String, Object?>{'type': 'string', 'default': 'ae_use'},
      'overwrite': <String, Object?>{'type': 'boolean', 'default': false},
    },
  };

  Map<String, Object?> get improveInputSchema => <String, Object?>{
    'type': 'object',
    'required': <String>['root_path'],
    'properties': <String, Object?>{
      'root_path': <String, Object?>{'type': 'string'},
      'targets': <String, Object?>{
        'type': 'array',
        'items': <String, Object?>{'type': 'string'},
      },
      'style_guidelines': <String, Object?>{'type': 'string'},
      'use_client_sampling': <String, Object?>{
        'type': 'boolean',
        'default': true,
      },
    },
  };

  Map<String, Object?> get installInputSchema => <String, Object?>{
    'type': 'object',
    'required': <String>['project_path'],
    'properties': <String, Object?>{
      'project_path': <String, Object?>{'type': 'string'},
      'ae_source_dir': <String, Object?>{'type': 'string'},
      'placement': <String, Object?>{
        'enum': <String>['ae_use', '.cursor/rules', 'custom'],
        'default': 'ae_use',
      },
      'custom_placement_dir': <String, Object?>{'type': 'string'},
      'validate': <String, Object?>{'type': 'boolean', 'default': true},
    },
  };

  Map<String, Object?> get uninstallInputSchema => <String, Object?>{
    'type': 'object',
    'required': <String>['project_path'],
    'properties': <String, Object?>{
      'project_path': <String, Object?>{'type': 'string'},
      'placement': <String, Object?>{
        'enum': <String>['ae_use', '.cursor/rules', 'custom'],
        'default': 'ae_use',
      },
      'custom_placement_dir': <String, Object?>{'type': 'string'},
      'dry_run': <String, Object?>{'type': 'boolean', 'default': false},
    },
  };

  // Wrapper handlers (maps suitable for MCP tool responses)
  Future<Map<String, Object?>> handleBootstrapAe(
    Map<String, Object?> args,
  ) async {
    final result = await bootstrap.bootstrapAe(
      rootPath: (args['root_path'] as String),
      libraryName: (args['library_name'] as String),
      outputDir: (args['output_dir'] as String?) ?? 'ae_use',
      overwrite: (args['overwrite'] as bool?) ?? false,
    );
    return <String, Object?>{
      'created_files': result.createdFiles,
      'warnings': result.warnings,
    };
  }

  Future<Map<String, Object?>> handleImproveAeBootstrap(
    Map<String, Object?> args,
  ) async {
    final result = await improve.improveAeBootstrap(
      rootPath: (args['root_path'] as String),
      targets: (args['targets'] as List?)?.cast<String>(),
      styleGuidelines: args['style_guidelines'] as String?,
      useClientSampling: (args['use_client_sampling'] as bool?) ?? true,
    );
    return <String, Object?>{
      'updated_files': result.updatedFiles,
      'diff_preview': result.diffPreview,
    };
  }

  Future<Map<String, Object?>> handleInstallAe(
    Map<String, Object?> args,
  ) async {
    final result = await install.installLibraryAsAe(
      projectPath: (args['project_path'] as String),
      aeSourceDir: args['ae_source_dir'] as String?,
      placement: (args['placement'] as String?) ?? 'ae_use',
      customPlacementDir: args['custom_placement_dir'] as String?,
      validate: (args['validate'] as bool?) ?? true,
    );
    return <String, Object?>{
      'installed_files': result.installedFiles,
      'validation': <String, Object?>{
        'passed': result.validation.passed,
        'messages': result.validation.messages,
      },
    };
  }

  Future<Map<String, Object?>> handleUninstallAe(
    Map<String, Object?> args,
  ) async {
    final result = await uninstall.uninstallLibraryAsAe(
      projectPath: (args['project_path'] as String),
      placement: (args['placement'] as String?) ?? 'ae_use',
      customPlacementDir: args['custom_placement_dir'] as String?,
      dryRun: (args['dry_run'] as bool?) ?? false,
    );
    return <String, Object?>{
      'removed_files': result.removedFiles,
      'leftovers': result.leftovers,
    };
  }
}
