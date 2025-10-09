import 'github_raw_fetcher.dart';

/// Resolves library IDs and paths within the AE registry.
class RegistryResolver {
  final GitHubRawFetcher _fetcher;
  final String registryOwner;
  final String registryRepo;
  final String registryBranch;

  RegistryResolver(
    this._fetcher, {
    this.registryOwner = 'fluent-meaning-symbiotic',
    this.registryRepo = 'agentic_executables',
    this.registryBranch = 'main',
  });

  /// Validates library ID format: `<language>_<library_name>`
  ///
  /// Examples:
  /// - dart_provider ✓
  /// - python_requests ✓
  /// - javascript_react ✓
  /// - mylib ✗ (missing language prefix)
  /// - dart_ ✗ (missing library name)
  bool isValidLibraryId(String libraryId) {
    final pattern = RegExp(r'^[a-z]+_[a-z0-9_]+$');
    return pattern.hasMatch(libraryId) && libraryId.split('_').length >= 2;
  }

  /// Extracts language from library ID.
  ///
  /// Example: 'dart_provider' -> 'dart'
  String? extractLanguage(String libraryId) {
    if (!isValidLibraryId(libraryId)) return null;
    return libraryId.split('_').first;
  }

  /// Extracts library name from library ID.
  ///
  /// Example: 'dart_xsoulspace_lints' -> 'xsoulspace_lints'
  String? extractLibraryName(String libraryId) {
    if (!isValidLibraryId(libraryId)) return null;
    final parts = libraryId.split('_');
    return parts.sublist(1).join('_');
  }

  /// Maps action to corresponding AE filename.
  ///
  /// - install -> ae_install.md
  /// - uninstall -> ae_uninstall.md
  /// - update -> ae_update.md
  /// - use -> ae_use.md
  String actionToFilename(String action) {
    switch (action.toLowerCase()) {
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

  /// Builds the registry path for a library file.
  ///
  /// [libraryId] - Library identifier (e.g., 'dart_provider')
  /// [action] - Action name (install, uninstall, update, use)
  ///
  /// Returns path like: 'ae_use_registry/dart_provider/ae_install.md'
  String getRegistryPath(String libraryId, String action) {
    if (!isValidLibraryId(libraryId)) {
      throw ArgumentError(
        'Invalid library ID format: $libraryId. '
        'Expected format: <language>_<library_name>',
      );
    }

    final filename = actionToFilename(action);
    return 'ae_use_registry/$libraryId/$filename';
  }

  /// Builds the registry folder path for a library.
  ///
  /// [libraryId] - Library identifier
  ///
  /// Returns path like: 'ae_use_registry/dart_provider'
  String getRegistryFolder(String libraryId) {
    if (!isValidLibraryId(libraryId)) {
      throw ArgumentError(
        'Invalid library ID format: $libraryId. '
        'Expected format: <language>_<library_name>',
      );
    }

    return 'ae_use_registry/$libraryId';
  }

  /// Checks if a library exists in the registry.
  ///
  /// [libraryId] - Library identifier to check
  ///
  /// Returns true if the library folder exists in the registry.
  Future<bool> libraryExistsInRegistry(String libraryId) async {
    if (!isValidLibraryId(libraryId)) return false;

    return await _fetcher.libraryExistsInRegistry(
      libraryId,
      registryOwner: registryOwner,
      registryRepo: registryRepo,
      branch: registryBranch,
    );
  }

  /// Fetches a specific AE file from the registry.
  ///
  /// [libraryId] - Library identifier
  /// [action] - Action name (install, uninstall, update, use)
  ///
  /// Returns the file content.
  /// Throws [Exception] if file not found or network error.
  Future<String> fetchRegistryFile(String libraryId, String action) async {
    final path = getRegistryPath(libraryId, action);

    return await _fetcher.fetchFile(
      registryOwner,
      registryRepo,
      path,
      branch: registryBranch,
    );
  }

  /// Builds the full raw URL for a registry file.
  ///
  /// [libraryId] - Library identifier
  /// [action] - Action name
  ///
  /// Returns the complete GitHub raw URL.
  String buildRegistryUrl(String libraryId, String action) {
    final path = getRegistryPath(libraryId, action);
    return _fetcher.buildRawUrl(
      registryOwner,
      registryRepo,
      path,
      registryBranch,
    );
  }

  /// Suggests a library ID based on repository information.
  ///
  /// [language] - Programming language (e.g., 'dart', 'python')
  /// [libraryName] - Library name (e.g., 'provider', 'requests')
  ///
  /// Returns a suggested library ID (e.g., 'dart_provider')
  String suggestLibraryId(String language, String libraryName) {
    final normalizedLanguage =
        language.toLowerCase().replaceAll(RegExp(r'\s+'), '_');
    final normalizedName =
        libraryName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '_');
    return '${normalizedLanguage}_$normalizedName';
  }

  /// Validates action name.
  ///
  /// Valid actions: install, uninstall, update, use
  bool isValidAction(String action) {
    return getValidActions().contains(action.toLowerCase());
  }

  /// Gets all valid action names.
  List<String> getValidActions() {
    return ['install', 'uninstall', 'update', 'use'];
  }

  /// Gets all required AE files for a library.
  List<String> getRequiredFiles() {
    return [
      'ae_install.md',
      'ae_uninstall.md',
      'ae_update.md',
      'ae_use.md',
    ];
  }
}
