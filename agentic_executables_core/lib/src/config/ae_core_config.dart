import '../models/types.dart';

class AeCoreConfig {
  static const String frameworkVersion = '3.2.0';

  static const String registryOwner = 'fluent-meaning-symbiotic';
  static const String registryRepo = 'agentic_executables_registry';
  static const String registryBranch = 'main';
  static const String registryBasePath = 'ae_use';

  static const String hubDirName = 'ae_hub';
  static const String hubConfigFile = 'hub.yaml';
  static const String hubKnowDir = 'know';
  // --- AE 3.0 hub layout (additive; coexists with v2 dirs above) ---
  static const String hubCanonicalDir = 'canonical';
  static const String hubArtifactsDir = 'artifacts';

  static const String artifactKindLocal = 'local';
  static const String artifactKindExternal = 'external';
  static const String artifactKindUse = 'use';

  static const String canonicalIndexFile = 'index.md';
  static const String canonicalMatrixFile = 'matrix.yaml';
  static const String canonicalMetaFile = 'meta.yaml';
  static const String canonicalChangelogFile = 'CHANGELOG.md';

  static const String artifactIndexFile = 'index.md';
  static const String artifactMatrixFile = 'matrix.yaml';
  static const String artifactMetaFile = 'meta.yaml';
  static const String artifactPatternsFile = 'patterns.md';
  static const String artifactDriftFile = 'drift.yaml';
  static const String hubUseDir = 'use';
  static const String hubPackagesDir = 'packages';
  static const String knowIndexFile = 'index.md';
  static const String knowMetaFile = 'meta.yaml';
  static const String knowPatternsFile = 'patterns.md';
  static const String knowMatrixFile = 'matrix.yaml';
  static const String knowMatrixMarkdownFile = 'matrix.md';
  static const String knowAliasesFile = 'aliases.yaml';
  static const String knowAliasesDir = '_aliases';
  static const String knowBySourceDir = '_by_source';
  static const String knowVersionsDir = 'versions';

  static const String license = 'MIT';
  static const String author = 'Arenukvern and contributors';

  static const int maxLoc = 800;
  static const int warningLoc = 500;

  static const List<String> requiredRegistryFiles = [
    'ae_install.md',
    'ae_uninstall.md',
    'ae_update.md',
    'ae_use.md',
  ];

  static String get registryRepositoryUrl =>
      'https://github.com/$registryOwner/$registryRepo';

  static String registryFolder(final String libraryId) =>
      '$registryBasePath/$libraryId';

  static String registryPath(final String libraryId, final AeAction action) =>
      '${registryFolder(libraryId)}/${action.fileName}';

  static String buildGitHubRawUrl({
    required final String owner,
    required final String repo,
    required final String branch,
    required final String path,
  }) {
    final normalized = path.replaceFirst(RegExp(r'^/+'), '');
    return 'https://raw.githubusercontent.com/$owner/$repo/$branch/$normalized';
  }

  static final RegExp libraryIdPattern = RegExp(r'^[a-z]+_[a-z0-9_]+$');

  static bool isValidLibraryId(final String libraryId) =>
      libraryIdPattern.hasMatch(libraryId) && libraryId.split('_').length >= 2;

  static String? extractLanguage(final String libraryId) {
    if (!isValidLibraryId(libraryId)) {
      return null;
    }
    return libraryId.split('_').first;
  }

  static String? extractLibraryName(final String libraryId) {
    if (!isValidLibraryId(libraryId)) {
      return null;
    }
    final parts = libraryId.split('_');
    return parts.sublist(1).join('_');
  }

  static String suggestLibraryId(
    final String language,
    final String libraryName,
  ) {
    final normalizedLanguage = language.toLowerCase().replaceAll(
          RegExp(r'\s+'),
          '_',
        );
    final normalizedName = libraryName.toLowerCase().replaceAll(
          RegExp('[^a-z0-9_]'),
          '_',
        );
    return '${normalizedLanguage}_$normalizedName';
  }

  static List<String> getRequiredFiles(
    final AeContext context,
    final AeAction action,
  ) {
    if (context == AeContext.library) {
      switch (action) {
        case AeAction.bootstrap:
        case AeAction.update:
          return [
            'ae_bootstrap.md',
            'ae_install.md',
            'ae_uninstall.md',
            'ae_update.md',
            'ae_use.md',
          ];
        default:
          return const [];
      }
    }

    return const [];
  }

  static List<String> getRequiredSections(final AeAction action) {
    switch (action) {
      case AeAction.bootstrap:
        return const ['Workflow', 'Guidelines'];
      case AeAction.install:
        return const ['Setup', 'Config', 'Integration', 'Validation'];
      case AeAction.uninstall:
        return const ['Cleanup', 'Verification'];
      case AeAction.update:
        return const ['Migration', 'Validation'];
      case AeAction.use:
        return const ['Workflow', 'Actions', 'Guidelines'];
    }
  }

  static List<String> getRequiredSectionsForFile(
    final String filePath,
    final AeAction action,
  ) {
    if (filePath.contains('install')) {
      return const ['Setup', 'Config', 'Integration', 'Validation'];
    }
    if (filePath.contains('uninstall')) {
      return const ['Cleanup', 'Verification'];
    }
    if (filePath.contains('update')) {
      return const ['Migration', 'Validation'];
    }
    if (filePath.contains('bootstrap')) {
      return const ['Workflow', 'Guidelines'];
    }
    if (filePath.contains('use')) {
      return const ['Workflow', 'Actions', 'Guidelines'];
    }
    return const [];
  }

  static List<String> getExpectedFiles(final AeAction action) {
    switch (action) {
      case AeAction.bootstrap:
        return const [
          'ae_bootstrap.md',
          'ae_install.md',
          'ae_uninstall.md',
          'ae_update.md',
          'ae_use.md',
        ];
      case AeAction.update:
        return const ['ae_bootstrap.md'];
      default:
        return const [];
    }
  }

  static List<Map<String, Object>> getCoreChecklistItems() => const [
        {'key': 'modularity', 'name': 'Modularity', 'critical': true},
        {
          'key': 'contextual_awareness',
          'name': 'Contextual Awareness',
          'critical': true,
        },
        {
          'key': 'agent_empowerment',
          'name': 'Agent Empowerment',
          'critical': true
        },
      ];

  static List<Map<String, Object>> getActionChecklistItems(
    final AeContext context,
    final AeAction action,
  ) {
    final items = <Map<String, Object>>[];

    if (action == AeAction.install || action == AeAction.bootstrap) {
      items.addAll(const [
        {'key': 'validation', 'name': 'Validation', 'critical': true},
        {'key': 'integration', 'name': 'Integration', 'critical': true},
      ]);
    }

    if (action == AeAction.uninstall) {
      items.addAll(const [
        {'key': 'reversibility', 'name': 'Reversibility', 'critical': true},
        {'key': 'cleanup', 'name': 'Cleanup', 'critical': true},
      ]);
    }

    if (action == AeAction.update) {
      items.addAll(const [
        {'key': 'migration', 'name': 'Migration', 'critical': true},
        {'key': 'backup_rollback', 'name': 'Backup/Rollback', 'critical': true},
      ]);
    }

    if (action == AeAction.use) {
      items.addAll(const [
        {'key': 'best_practices', 'name': 'Best Practices', 'critical': false},
        {'key': 'anti_patterns', 'name': 'Anti-patterns', 'critical': false},
      ]);
    }

    if (context == AeContext.library && action == AeAction.bootstrap) {
      items.addAll(const [
        {
          'key': 'analysis_guidance',
          'name': 'Analysis Guidance',
          'critical': true,
        },
        {
          'key': 'file_generation_rules',
          'name': 'File Generation Rules',
          'critical': true,
        },
        {'key': 'abstraction', 'name': 'Abstraction', 'critical': true},
      ]);
    }

    return items;
  }

  static bool requiresValidation(final AeAction action) =>
      action == AeAction.bootstrap ||
      action == AeAction.install ||
      action == AeAction.update;

  static bool requiresIntegration(final AeAction action) =>
      action == AeAction.install || action == AeAction.bootstrap;

  static bool requiresReversibility(final AeAction action) =>
      action == AeAction.uninstall || action == AeAction.update;

  static bool requiresMetaRules(final AeAction action) =>
      action == AeAction.bootstrap;
}
