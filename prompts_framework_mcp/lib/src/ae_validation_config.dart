/// Centralized configuration for AE validation and compliance checking.
class AEValidationConfig {
  /// Current AE specification version
  static const String currentVersion = '1.0.0';

  /// AE repository URL
  static const String repositoryUrl =
      'https://github.com/fluent-meaning-symbiotic/agentic_executables';

  /// License type
  static const String license = 'MIT';

  /// Author information
  static const String author = 'Arenukvern and contributors';

  /// LOC thresholds for documentation
  static const int maxLoc = 800;
  static const int warningLoc = 500;

  /// Returns required files based on context and action.
  static List<String> getRequiredFiles(String contextType, String action) {
    if (contextType == 'library') {
      switch (action) {
        case 'bootstrap':
        case 'update':
          return [
            'ae_bootstrap.md',
            'ae_install.md',
            'ae_uninstall.md',
            'ae_update.md',
            'ae_use.md'
          ];
        default:
          return [];
      }
    }
    return [];
  }

  /// Returns required sections based on action.
  static List<String> getRequiredSections(String action) {
    switch (action) {
      case 'bootstrap':
        return ['Workflow', 'Guidelines'];
      case 'install':
        return ['Setup', 'Config', 'Integration', 'Validation'];
      case 'uninstall':
        return ['Cleanup', 'Verification'];
      case 'update':
        return ['Migration', 'Validation'];
      case 'use':
        return ['Workflow', 'Actions', 'Guidelines'];
      default:
        return [];
    }
  }

  /// Returns required sections for a specific file path.
  static List<String> getRequiredSectionsForFile(
    String filePath,
    String action,
  ) {
    if (filePath.contains('install')) {
      return ['Setup', 'Config', 'Integration', 'Validation'];
    } else if (filePath.contains('uninstall')) {
      return ['Cleanup', 'Verification'];
    } else if (filePath.contains('update')) {
      return ['Migration', 'Validation'];
    } else if (filePath.contains('bootstrap')) {
      return ['Workflow', 'Guidelines'];
    } else if (filePath.contains('use')) {
      return ['Workflow', 'Actions', 'Guidelines'];
    }
    return [];
  }

  /// Returns expected files for library actions.
  static List<String> getExpectedFiles(String action) {
    switch (action) {
      case 'bootstrap':
        return [
          'ae_bootstrap.md',
          'ae_install.md',
          'ae_uninstall.md',
          'ae_update.md',
          'ae_use.md'
        ];
      case 'update':
        return ['ae_bootstrap.md'];
      default:
        return [];
    }
  }

  /// Returns core checklist items applicable to all actions.
  static List<Map<String, dynamic>> getCoreChecklistItems() {
    return [
      {
        'key': 'modularity',
        'name': 'Modularity',
        'critical': true,
      },
      {
        'key': 'contextual_awareness',
        'name': 'Contextual Awareness',
        'critical': true,
      },
      {
        'key': 'agent_empowerment',
        'name': 'Agent Empowerment',
        'critical': true,
      },
    ];
  }

  /// Returns action-specific checklist items.
  static List<Map<String, dynamic>> getActionChecklistItems(
    String contextType,
    String action,
  ) {
    final items = <Map<String, dynamic>>[];

    if (action == 'install' || action == 'bootstrap') {
      items.addAll([
        {
          'key': 'validation',
          'name': 'Validation',
          'critical': true,
        },
        {
          'key': 'integration',
          'name': 'Integration',
          'critical': true,
        },
      ]);
    }

    if (action == 'uninstall') {
      items.addAll([
        {
          'key': 'reversibility',
          'name': 'Reversibility',
          'critical': true,
        },
        {
          'key': 'cleanup',
          'name': 'Cleanup',
          'critical': true,
        },
      ]);
    }

    if (action == 'update') {
      items.addAll([
        {
          'key': 'migration',
          'name': 'Migration',
          'critical': true,
        },
        {
          'key': 'backup_rollback',
          'name': 'Backup/Rollback',
          'critical': true,
        },
      ]);
    }

    if (action == 'use') {
      items.addAll([
        {
          'key': 'best_practices',
          'name': 'Best Practices',
          'critical': false,
        },
        {
          'key': 'anti_patterns',
          'name': 'Anti-patterns',
          'critical': false,
        },
      ]);
    }

    if (contextType == 'library' && action == 'bootstrap') {
      items.addAll([
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
        {
          'key': 'abstraction',
          'name': 'Abstraction',
          'critical': true,
        },
      ]);
    }

    return items;
  }

  /// Checks if validation is required for the action.
  static bool requiresValidation(String action) =>
      ['bootstrap', 'install', 'update'].contains(action);

  /// Checks if integration is required for the action.
  static bool requiresIntegration(String action) =>
      ['install', 'bootstrap'].contains(action);

  /// Checks if reversibility is required for the action.
  static bool requiresReversibility(String action) =>
      ['uninstall', 'update'].contains(action);

  /// Checks if meta-rules are required for the action.
  static bool requiresMetaRules(String action) => action == 'bootstrap';
}
