/// Models for Agentic Executable (AE) context and operations
library ae_context;

/// Represents the core AE principles and definitions
class AEContext {
  static const String definition = '''
Agentic Executable (AE): A library or package treated as an executable program, 
managed by AI agents for installation, configuration, usage, and uninstallation.
''';

  static const List<String> corePrinciples = [
    'Agent Empowerment',
    'Modularity',
    'Contextual Awareness',
    'Reversibility',
    'Validation',
    'Documentation Focus',
  ];

  static const List<String> lifecycleSteps = [
    'Installation',
    'Configuration',
    'Integration',
    'Usage',
    'Uninstallation',
  ];
}

/// Represents a library that can be managed as an AE
class LibraryInfo {
  final String name;
  final String path;
  final String? version;
  final Map<String, dynamic> metadata;
  final List<String> dependencies;

  const LibraryInfo({
    required this.name,
    required this.path,
    this.version,
    this.metadata = const {},
    this.dependencies = const [],
  });

  factory LibraryInfo.fromJson(Map<String, dynamic> json) {
    return LibraryInfo(
      name: json['name'] as String,
      path: json['path'] as String,
      version: json['version'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      dependencies:
          (json['dependencies'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'path': path,
      'version': version,
      'metadata': metadata,
      'dependencies': dependencies,
    };
  }
}

/// Represents the project context where AE operations will be performed
class ProjectContext {
  final String rootPath;
  final String targetAIAgent;
  final Map<String, dynamic> configuration;
  final List<String> existingAEFiles;

  const ProjectContext({
    required this.rootPath,
    required this.targetAIAgent,
    this.configuration = const {},
    this.existingAEFiles = const [],
  });

  factory ProjectContext.fromJson(Map<String, dynamic> json) {
    return ProjectContext(
      rootPath: json['rootPath'] as String,
      targetAIAgent: json['targetAIAgent'] as String,
      configuration: json['configuration'] as Map<String, dynamic>? ?? {},
      existingAEFiles:
          (json['existingAEFiles'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rootPath': rootPath,
      'targetAIAgent': targetAIAgent,
      'configuration': configuration,
      'existingAEFiles': existingAEFiles,
    };
  }
}

/// Represents the result of an AE operation
class AEOperationResult {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;
  final List<String>? warnings;
  final List<String>? errors;

  const AEOperationResult({
    required this.success,
    required this.message,
    this.data,
    this.warnings,
    this.errors,
  });

  factory AEOperationResult.success(
    String message, {
    Map<String, dynamic>? data,
  }) {
    return AEOperationResult(success: true, message: message, data: data);
  }

  factory AEOperationResult.failure(String message, {List<String>? errors}) {
    return AEOperationResult(success: false, message: message, errors: errors);
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data,
      'warnings': warnings,
      'errors': errors,
    };
  }
}
