/// Tool for verifying AE implementation against core principles.
class VerifyAEImplementationTool {
  /// Verifies implementation based on AE principles.
  Map<String, dynamic> execute(Map<String, dynamic> params) {
    final contextType = params['context_type'] as String?;
    final action = params['action'] as String?;
    final description = params['description'] as String?;

    // Validate required parameters
    if (contextType == null || contextType.isEmpty) {
      return _errorResponse('Parameter "context_type" is required');
    }
    if (action == null || action.isEmpty) {
      return _errorResponse('Parameter "action" is required');
    }
    if (description == null || description.isEmpty) {
      return _errorResponse('Parameter "description" is required');
    }

    // Validate enum values
    if (!['library', 'project'].contains(contextType)) {
      return _errorResponse(
        'Invalid context_type. Must be "library" or "project"',
      );
    }
    if (!['bootstrap', 'install', 'uninstall', 'update', 'use']
        .contains(action)) {
      return _errorResponse(
        'Invalid action. Must be one of: bootstrap, install, uninstall, update, use',
      );
    }

    final checklist = _generateChecklist(contextType, action);

    return {
      'success': true,
      'context_type': contextType,
      'action': action,
      'verification_checklist': checklist,
      'message':
          'Verification checklist generated. Review each item against your implementation.',
    };
  }

  /// Generates verification checklist based on AE principles.
  List<Map<String, dynamic>> _generateChecklist(
    String contextType,
    String action,
  ) {
    final checklist = <Map<String, dynamic>>[];

    // Core principles applicable to all actions
    checklist.addAll([
      {
        'principle': 'Modularity',
        'check':
            'Are instructions structured in clear, reusable steps that can be followed sequentially?',
        'critical': true,
      },
      {
        'principle': 'Contextual Awareness',
        'check':
            'Does documentation provide sufficient domain knowledge for agents to understand integration points?',
        'critical': true,
      },
      {
        'principle': 'Agent Empowerment',
        'check':
            'Can AI agents autonomously execute these instructions without manual intervention?',
        'critical': true,
      },
      {
        'principle': 'Documentation Focus',
        'check':
            'Are instructions concise and agent-readable rather than verbose human-oriented docs?',
        'critical': false,
      },
    ]);

    // Action-specific checks
    if (action == 'install' || action == 'bootstrap') {
      checklist.addAll([
        {
          'principle': 'Validation',
          'check':
              'Are there checks included to verify successful installation/configuration?',
          'critical': true,
        },
        {
          'principle': 'Integration',
          'check':
              'Are integration points clearly defined with the existing codebase?',
          'critical': true,
        },
      ]);
    }

    if (action == 'uninstall') {
      checklist.addAll([
        {
          'principle': 'Reversibility',
          'check':
              'Does uninstallation cleanly remove all traces and restore the original state?',
          'critical': true,
        },
        {
          'principle': 'Cleanup',
          'check':
              'Are all resources, configurations, and dependencies properly removed?',
          'critical': true,
        },
      ]);
    }

    if (action == 'update') {
      checklist.addAll([
        {
          'principle': 'Migration',
          'check':
              'Are migration steps clearly defined for version transitions?',
          'critical': true,
        },
        {
          'principle': 'Backup/Rollback',
          'check': 'Are backup and rollback procedures included for safety?',
          'critical': true,
        },
        {
          'principle': 'Breaking Changes',
          'check':
              'Are breaking changes identified and migration paths provided?',
          'critical': true,
        },
      ]);
    }

    if (action == 'use') {
      checklist.addAll([
        {
          'principle': 'Best Practices',
          'check':
              'Are common use cases and best practices clearly documented?',
          'critical': false,
        },
        {
          'principle': 'Anti-patterns',
          'check': 'Are common pitfalls and anti-patterns identified?',
          'critical': false,
        },
      ]);
    }

    if (contextType == 'library' && action == 'bootstrap') {
      checklist.addAll([
        {
          'principle': 'Analysis',
          'check':
              'Are instructions for analyzing the codebase architecture included?',
          'critical': true,
        },
        {
          'principle': 'File Generation',
          'check':
              'Are guidelines for generating ae_install.md, ae_uninstall.md, ae_update.md included?',
          'critical': true,
        },
        {
          'principle': 'Abstraction',
          'check':
              'Are instructions abstract enough to apply to different library types/languages?',
          'critical': true,
        },
      ]);
    }

    return checklist;
  }

  Map<String, dynamic> _errorResponse(String message) {
    return {
      'success': false,
      'error': message,
    };
  }
}
