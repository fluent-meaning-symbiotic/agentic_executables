import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

/// Centralized configuration for the AE Framework MCP Server.
/// Contains all server metadata, registry settings, and framework constants.
class AEFrameworkConfig {
  // ============================================================================
  // SERVER METADATA
  // ============================================================================

  /// Server name for MCP protocol
  static const String serverName = 'prompts-framework-mcp';

  /// Server description
  static const String serverDescription =
      'MCP server providing strategic guidance for AI agents managing Agentic Executables (AE) framework';

  /// Reads server version from pubspec.yaml at runtime
  static Future<String> getVersion() async {
    try {
      // Try multiple paths to find pubspec.yaml
      final possiblePaths = [
        'pubspec.yaml',
        '../pubspec.yaml',
        '../../pubspec.yaml',
        path.join(Directory.current.path, 'pubspec.yaml'),
      ];

      String? pubspecContent;
      for (final pubspecPath in possiblePaths) {
        final file = File(pubspecPath);
        if (await file.exists()) {
          pubspecContent = await file.readAsString();
          break;
        }
      }

      if (pubspecContent == null) {
        return '0.1.0'; // Fallback version
      }

      final yaml = loadYaml(pubspecContent);
      return yaml['version']?.toString() ?? '0.1.0';
    } catch (e) {
      return '0.1.0'; // Fallback version on error
    }
  }

  // ============================================================================
  // REGISTRY CONFIGURATION
  // ============================================================================

  /// Default registry repository owner
  static const String registryOwner = 'fluent-meaning-symbiotic';

  /// Default registry repository name
  static const String registryRepo = 'agentic_executables_registry';

  /// Default registry branch
  static const String defaultBranch = 'main';

  /// Registry base path within repository
  static const String registryBasePath = 'ae_use';

  /// Repository URL
  static const String repositoryUrl =
      'https://github.com/$registryOwner/$registryRepo';

  /// Builds full registry URL
  static String getRegistryUrl() => repositoryUrl;

  /// Builds registry folder path for a library
  static String getRegistryFolder(final String libraryId) =>
      '$registryBasePath/$libraryId';

  /// Builds full registry file path for a library and action
  static String getRegistryFilePath(
    final String libraryId,
    final String action,
  ) {
    final fileName = getAEFileName(action);
    return '$registryBasePath/$libraryId/$fileName';
  }

  // ============================================================================
  // AE FILE DEFINITIONS
  // ============================================================================

  /// All required AE file names
  static const List<String> aeFileNames = [
    'ae_install.md',
    'ae_uninstall.md',
    'ae_update.md',
    'ae_use.md',
  ];

  /// All AE file names including bootstrap (library-only)
  static const List<String> allAEFileNames = [
    'ae_bootstrap.md',
    ...aeFileNames,
  ];

  /// Maps action to corresponding AE filename
  static String getAEFileName(final String action) {
    switch (action.toLowerCase()) {
      case 'bootstrap':
        return 'ae_bootstrap.md';
      case 'install':
        return 'ae_install.md';
      case 'uninstall':
        return 'ae_uninstall.md';
      case 'update':
        return 'ae_update.md';
      case 'use':
        return 'ae_use.md';
      default:
        throw ArgumentError('Invalid action: $action');
    }
  }

  /// Returns all required AE files for registry submission
  static List<String> getRequiredAEFiles() => List.from(aeFileNames);

  // ============================================================================
  // VALID ENUMS - CONTEXTS
  // ============================================================================

  /// Valid context types
  static const List<String> validContexts = ['library', 'project'];

  /// Validates context type
  static bool isValidContext(final String context) =>
      validContexts.contains(context.toLowerCase());

  /// Returns all valid contexts
  static List<String> getValidContexts() => List.from(validContexts);

  /// Error message for invalid context
  static String getInvalidContextError() =>
      'Invalid context_type. Must be one of: ${validContexts.join(", ")}';

  // ============================================================================
  // VALID ENUMS - ACTIONS
  // ============================================================================

  /// Valid action types (all contexts)
  static const List<String> validActions = [
    'bootstrap',
    'install',
    'uninstall',
    'update',
    'use',
  ];

  /// Valid actions for registry operations (excludes bootstrap)
  static const List<String> registryActions = [
    'install',
    'uninstall',
    'update',
    'use',
  ];

  /// Validates action type
  static bool isValidAction(final String action) =>
      validActions.contains(action.toLowerCase());

  /// Validates registry action type
  static bool isValidRegistryAction(final String action) =>
      registryActions.contains(action.toLowerCase());

  /// Returns all valid actions
  static List<String> getValidActions() => List.from(validActions);

  /// Returns valid registry actions
  static List<String> getValidRegistryActions() => List.from(registryActions);

  /// Error message for invalid action
  static String getInvalidActionError() =>
      'Invalid action. Must be one of: ${validActions.join(", ")}';

  /// Error message for invalid registry action
  static String getInvalidRegistryActionError() =>
      'Invalid action. Must be one of: ${registryActions.join(", ")}';

  // ============================================================================
  // VALID ENUMS - REGISTRY OPERATIONS
  // ============================================================================

  /// Valid registry operations
  static const List<String> validRegistryOperations = [
    'submit_to_registry',
    'get_from_registry',
    'bootstrap_local_registry',
  ];

  /// Validates registry operation
  static bool isValidRegistryOperation(final String operation) =>
      validRegistryOperations.contains(operation.toLowerCase());

  /// Returns all valid registry operations
  static List<String> getValidRegistryOperations() =>
      List.from(validRegistryOperations);

  /// Error message for invalid registry operation
  static String getInvalidRegistryOperationError() =>
      'Invalid operation. Must be one of: ${validRegistryOperations.join(", ")}';

  // ============================================================================
  // LIBRARY ID VALIDATION
  // ============================================================================

  /// Library ID format pattern: `<language>_<library_name>`
  static final RegExp libraryIdPattern = RegExp(r'^[a-z]+_[a-z0-9_]+$');

  /// Validates library ID format
  static bool isValidLibraryId(final String libraryId) =>
      libraryIdPattern.hasMatch(libraryId) && libraryId.split('_').length >= 2;

  /// Extracts language from library ID
  static String? extractLanguage(final String libraryId) {
    if (!isValidLibraryId(libraryId)) return null;
    return libraryId.split('_').first;
  }

  /// Extracts library name from library ID
  static String? extractLibraryName(final String libraryId) {
    if (!isValidLibraryId(libraryId)) return null;
    final parts = libraryId.split('_');
    return parts.sublist(1).join('_');
  }

  /// Suggests a library ID from language and library name
  static String suggestLibraryId(
    final String language,
    final String libraryName,
  ) {
    final normalizedLanguage =
        language.toLowerCase().replaceAll(RegExp(r'\s+'), '_');
    final normalizedName =
        libraryName.toLowerCase().replaceAll(RegExp('[^a-z0-9_]'), '_');
    return '${normalizedLanguage}_$normalizedName';
  }

  /// Error message for invalid library ID
  static String getInvalidLibraryIdError(final String libraryId) =>
      'Invalid library_id format: $libraryId. Expected format: `<language>_<library_name>` (e.g., dart_provider, python_requests)';

  // ============================================================================
  // LICENSE & AUTHOR
  // ============================================================================

  /// License type
  static const String license = 'MIT';

  /// Author information
  static const String author = 'Arenukvern and contributors';

  // ============================================================================
  // GITHUB RAW URL BUILDING
  // ============================================================================

  /// Builds a raw GitHub URL for file access
  static String buildGitHubRawUrl(
    final String owner,
    final String repo,
    final String filePath,
    final String branch,
  ) {
    final cleanPath =
        filePath.startsWith('/') ? filePath.substring(1) : filePath;
    return 'https://raw.githubusercontent.com/$owner/$repo/$branch/$cleanPath';
  }

  /// Builds raw URL for registry file
  static String buildRegistryRawUrl(
    final String libraryId,
    final String action,
  ) {
    final filePath = getRegistryFilePath(libraryId, action);
    return buildGitHubRawUrl(
      registryOwner,
      registryRepo,
      filePath,
      defaultBranch,
    );
  }
}
