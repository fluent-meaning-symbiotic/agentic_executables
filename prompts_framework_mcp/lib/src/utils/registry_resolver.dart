import '../ae_framework_config.dart';
import 'github_raw_fetcher.dart';

/// Resolves library IDs and paths within the AE registry.
class RegistryResolver {
  final GitHubRawFetcher _fetcher;
  final String registryOwner;
  final String registryRepo;
  final String registryBranch;

  RegistryResolver(
    this._fetcher, {
    String? registryOwner,
    String? registryRepo,
    String? registryBranch,
  })  : registryOwner = registryOwner ?? AEFrameworkConfig.registryOwner,
        registryRepo = registryRepo ?? AEFrameworkConfig.registryRepo,
        registryBranch = registryBranch ?? AEFrameworkConfig.defaultBranch;

  /// Validates library ID format: `<language>_<library_name>`
  ///
  /// Examples:
  /// - dart_provider ✓
  /// - python_requests ✓
  /// - javascript_react ✓
  /// - mylib ✗ (missing language prefix)
  /// - dart_ ✗ (missing library name)
  bool isValidLibraryId(String libraryId) =>
      AEFrameworkConfig.isValidLibraryId(libraryId);

  /// Extracts language from library ID.
  ///
  /// Example: 'dart_provider' -> 'dart'
  String? extractLanguage(String libraryId) =>
      AEFrameworkConfig.extractLanguage(libraryId);

  /// Extracts library name from library ID.
  ///
  /// Example: 'dart_xsoulspace_lints' -> 'xsoulspace_lints'
  String? extractLibraryName(String libraryId) =>
      AEFrameworkConfig.extractLibraryName(libraryId);

  /// Maps action to corresponding AE filename.
  ///
  /// - install -> ae_install.md
  /// - uninstall -> ae_uninstall.md
  /// - update -> ae_update.md
  /// - use -> ae_use.md
  String actionToFilename(String action) =>
      AEFrameworkConfig.getAEFileName(action);

  /// Builds the registry path for a library file.
  ///
  /// [libraryId] - Library identifier (e.g., 'dart_provider')
  /// [action] - Action name (install, uninstall, update, use)
  ///
  /// Returns path like: 'ae_use_registry/dart_provider/ae_install.md'
  String getRegistryPath(String libraryId, String action) {
    if (!isValidLibraryId(libraryId)) {
      throw ArgumentError(
        AEFrameworkConfig.getInvalidLibraryIdError(libraryId),
      );
    }
    return AEFrameworkConfig.getRegistryFilePath(libraryId, action);
  }

  /// Builds the registry folder path for a library.
  ///
  /// [libraryId] - Library identifier
  ///
  /// Returns path like: 'ae_use_registry/dart_provider'
  String getRegistryFolder(String libraryId) {
    if (!isValidLibraryId(libraryId)) {
      throw ArgumentError(
        AEFrameworkConfig.getInvalidLibraryIdError(libraryId),
      );
    }
    return AEFrameworkConfig.getRegistryFolder(libraryId);
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
  String suggestLibraryId(String language, String libraryName) =>
      AEFrameworkConfig.suggestLibraryId(language, libraryName);

  /// Validates action name.
  ///
  /// Valid actions: install, uninstall, update, use
  bool isValidAction(String action) =>
      AEFrameworkConfig.isValidRegistryAction(action);

  /// Gets all valid action names.
  List<String> getValidActions() => AEFrameworkConfig.getValidRegistryActions();

  /// Gets all required AE files for a library.
  List<String> getRequiredFiles() => AEFrameworkConfig.getRequiredAEFiles();
}
