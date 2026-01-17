/// Type-safe enums for Agentic Executables framework.
/// Provides compile-time safety for context types and actions.

/// Context types for AE operations
enum AEContextType {
  /// Library context - for library maintainers creating/updating AE files
  library('library'),

  /// Project context - for developers using AE files in projects
  project('project');

  const AEContextType(this.value);

  /// String value for serialization
  final String value;

  /// Parse from string value
  static AEContextType fromString(final String value) {
    switch (value.toLowerCase()) {
      case 'library':
        return AEContextType.library;
      case 'project':
        return AEContextType.project;
      default:
        throw ArgumentError(
          'Invalid context_type: $value. Must be one of: library, project',
        );
    }
  }

  /// Get all valid context types as strings
  static List<String> get validValues =>
      AEContextType.values.map((e) => e.value).toList();

  @override
  String toString() => value;
}

/// Action types for AE operations
enum AEAction {
  /// Bootstrap action - create/update AE files (library context only)
  bootstrap('bootstrap'),

  /// Install action - install and integrate library
  install('install'),

  /// Uninstall action - remove library and cleanup
  uninstall('uninstall'),

  /// Update action - migrate to new version
  update('update'),

  /// Use action - usage patterns and best practices
  use('use');

  const AEAction(this.value);

  /// String value for serialization
  final String value;

  /// Parse from string value
  static AEAction fromString(final String value) {
    switch (value.toLowerCase()) {
      case 'bootstrap':
        return AEAction.bootstrap;
      case 'install':
        return AEAction.install;
      case 'uninstall':
        return AEAction.uninstall;
      case 'update':
        return AEAction.update;
      case 'use':
        return AEAction.use;
      default:
        throw ArgumentError(
          'Invalid action: $value. Must be one of: bootstrap, install, uninstall, update, use',
        );
    }
  }

  /// Get all valid actions as strings
  static List<String> get validValues =>
      AEAction.values.map((e) => e.value).toList();

  /// Get registry actions (excludes bootstrap)
  static List<String> get registryActions =>
      [install, uninstall, update, use].map((e) => e.value).toList();

  /// Check if action is valid for registry operations
  bool get isRegistryAction => this != AEAction.bootstrap;

  /// Get corresponding AE filename
  String get fileName {
    switch (this) {
      case AEAction.bootstrap:
        return 'ae_bootstrap.md';
      case AEAction.install:
        return 'ae_install.md';
      case AEAction.uninstall:
        return 'ae_uninstall.md';
      case AEAction.update:
        return 'ae_update.md';
      case AEAction.use:
        return 'ae_use.md';
    }
  }

  @override
  String toString() => value;
}

/// Registry operations for manage_ae_registry tool
enum AERegistryOperation {
  /// Submit library to registry
  submitToRegistry('submit_to_registry'),

  /// Fetch library from registry
  getFromRegistry('get_from_registry'),

  /// Bootstrap local registry
  bootstrapLocalRegistry('bootstrap_local_registry');

  const AERegistryOperation(this.value);

  /// String value for serialization
  final String value;

  /// Parse from string value
  static AERegistryOperation fromString(final String value) {
    switch (value.toLowerCase()) {
      case 'submit_to_registry':
        return AERegistryOperation.submitToRegistry;
      case 'get_from_registry':
        return AERegistryOperation.getFromRegistry;
      case 'bootstrap_local_registry':
        return AERegistryOperation.bootstrapLocalRegistry;
      default:
        throw ArgumentError(
          'Invalid operation: $value. Must be one of: submit_to_registry, get_from_registry, bootstrap_local_registry',
        );
    }
  }

  /// Get all valid operations as strings
  static List<String> get validValues =>
      AERegistryOperation.values.map((e) => e.value).toList();

  @override
  String toString() => value;
}

/// Type-safe context-action pairing with validation
class AEContextAction {
  AEContextAction(this.context, this.action) {
    _validate();
  }

  /// Context type
  final AEContextType context;

  /// Action type
  final AEAction action;

  /// Validate context-action combination
  void _validate() {
    // Bootstrap is only valid for library context
    if (action == AEAction.bootstrap && context != AEContextType.library) {
      throw ArgumentError(
        'Bootstrap action is only valid for library context',
      );
    }
  }

  /// Get document files for this context-action pair
  List<String> getDocumentFiles() {
    switch (context) {
      case AEContextType.library:
        if (action == AEAction.bootstrap) {
          return ['ae_context.md', 'ae_bootstrap.md'];
        }
        // Library context using AE files
        return ['ae_context.md', 'ae_use.md'];

      case AEContextType.project:
        // Project context always uses ae_context.md + ae_use.md
        return ['ae_context.md', 'ae_use.md'];
    }
  }

  @override
  String toString() => '${context.value}:${action.value}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AEContextAction &&
          runtimeType == other.runtimeType &&
          context == other.context &&
          action == other.action;

  @override
  int get hashCode => context.hashCode ^ action.hashCode;
}
