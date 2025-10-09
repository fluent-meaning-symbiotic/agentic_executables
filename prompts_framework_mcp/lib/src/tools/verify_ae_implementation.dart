import 'dart:convert';

/// Tool for verifying AE implementation with structured metrics.
class VerifyAEImplementationTool {
  /// Verifies implementation using agent-provided checklist completion.
  Map<String, dynamic> execute(Map<String, dynamic> params) {
    final contextType = params['context_type'] as String?;
    final action = params['action'] as String?;

    // Parse files_modified (can be List or String)
    final filesModified = _parseList(params['files_modified']);

    // Parse checklist_completed (can be Map or String)
    final checklistCompleted = _parseMap(params['checklist_completed']);

    // Validate required parameters
    if (contextType == null || contextType.isEmpty) {
      return _errorResponse('Parameter "context_type" is required');
    }
    if (action == null || action.isEmpty) {
      return _errorResponse('Parameter "action" is required');
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

    final verification = _verifyImplementation(
      contextType: contextType,
      action: action,
      filesModified: filesModified,
      checklistCompleted: checklistCompleted,
    );

    return {
      'success': true,
      'context_type': contextType,
      'action': action,
      'verification': verification,
      'overall_status': verification['overall_pass'] ? 'PASS' : 'FAIL',
      'message': verification['overall_pass']
          ? 'Implementation verification passed.'
          : 'Implementation verification failed. Review missing items.',
    };
  }

  /// Verifies implementation against required checklist.
  Map<String, dynamic> _verifyImplementation({
    required String contextType,
    required String action,
    required List filesModified,
    required Map checklistCompleted,
  }) {
    final results = <Map<String, dynamic>>[];
    var passCount = 0;
    var totalChecks = 0;

    // Get required checklist items for this action
    final requiredItems = _getRequiredChecklistItems(contextType, action);

    // Verify each required item
    for (final item in requiredItems) {
      final itemKey = item['key'] as String;
      final itemName = item['name'] as String;
      final isCritical = item['critical'] as bool;
      final isCompleted = checklistCompleted[itemKey] == true;

      totalChecks++;
      if (isCompleted) passCount++;

      results.add({
        'item': itemName,
        'key': itemKey,
        'status': isCompleted ? 'PASS' : 'FAIL',
        'critical': isCritical,
        'details': isCompleted
            ? 'Checklist item completed'
            : 'Checklist item not completed',
      });
    }

    // Verify file structure
    final fileResults =
        _verifyFileStructure(contextType, action, filesModified);
    results.addAll(fileResults['checks'] as List<Map<String, dynamic>>);
    totalChecks += fileResults['total'] as int;
    passCount += fileResults['passed'] as int;

    final overallPass = passCount == totalChecks;

    return {
      'overall_pass': overallPass,
      'pass_count': passCount,
      'total_checks': totalChecks,
      'pass_rate':
          totalChecks > 0 ? (passCount / totalChecks * 100).round() : 0,
      'checks': results,
      'missing_items': _getMissingItems(results),
      'warnings': _getWarnings(filesModified),
    };
  }

  /// Returns required checklist items based on context and action.
  List<Map<String, dynamic>> _getRequiredChecklistItems(
    String contextType,
    String action,
  ) {
    // Core items applicable to all actions
    final coreItems = [
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

    final items = <Map<String, dynamic>>[...coreItems];

    // Action-specific items
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

  /// Verifies file structure and LOC thresholds.
  Map<String, dynamic> _verifyFileStructure(
    String contextType,
    String action,
    List filesModified,
  ) {
    final checks = <Map<String, dynamic>>[];
    var passed = 0;
    var total = 0;

    // Check expected files for library context
    if (contextType == 'library') {
      final expectedFiles = _getExpectedFiles(action);

      for (final expectedFile in expectedFiles) {
        final fileExists = filesModified.any(
          (f) => f['path'] == expectedFile,
        );

        total++;
        if (fileExists) passed++;

        checks.add({
          'item': 'Expected File: $expectedFile',
          'key': 'file_$expectedFile',
          'status': fileExists ? 'PASS' : 'FAIL',
          'critical': true,
          'details': fileExists
              ? 'File present in modifications'
              : 'Expected file not found in modifications',
        });
      }
    }

    // Check LOC thresholds for all files
    for (final file in filesModified) {
      final filePath = file['path'] as String;
      final loc = file['loc'] as int? ?? 0;

      total++;

      if (loc > 800) {
        checks.add({
          'item': 'LOC Check: $filePath',
          'key': 'loc_$filePath',
          'status': 'FAIL',
          'critical': true,
          'details':
              '$loc LOC exceeds maximum (800). Documentation is too verbose.',
        });
      } else if (loc > 500) {
        passed++;
        checks.add({
          'item': 'LOC Check: $filePath',
          'key': 'loc_$filePath',
          'status': 'PASS (with warning)',
          'critical': false,
          'details':
              '$loc LOC is acceptable but consider reducing below 500 for better conciseness.',
        });
      } else {
        passed++;
        checks.add({
          'item': 'LOC Check: $filePath',
          'key': 'loc_$filePath',
          'status': 'PASS',
          'critical': false,
          'details': '$loc LOC is concise and agent-friendly.',
        });
      }
    }

    // Check sections in files
    for (final file in filesModified) {
      final filePath = file['path'] as String;
      final sections = file['sections'] as List?;

      if (sections != null && sections.isNotEmpty) {
        final requiredSections = _getRequiredSectionsForFile(filePath, action);

        if (requiredSections.isNotEmpty) {
          final missingSections =
              requiredSections.where((s) => !sections.contains(s)).toList();

          total++;

          if (missingSections.isEmpty) {
            passed++;
            checks.add({
              'item': 'Sections Check: $filePath',
              'key': 'sections_$filePath',
              'status': 'PASS',
              'critical': true,
              'details': 'All required sections present',
            });
          } else {
            checks.add({
              'item': 'Sections Check: $filePath',
              'key': 'sections_$filePath',
              'status': 'FAIL',
              'critical': true,
              'details': 'Missing sections: ${missingSections.join(", ")}',
            });
          }
        }
      }
    }

    return {
      'checks': checks,
      'passed': passed,
      'total': total,
    };
  }

  /// Returns expected files for library actions.
  List<String> _getExpectedFiles(String action) {
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

  /// Returns required sections for a specific file.
  List<String> _getRequiredSectionsForFile(String filePath, String action) {
    if (filePath.contains('install')) {
      return ['Installation', 'Configuration', 'Integration', 'Validation'];
    } else if (filePath.contains('uninstall')) {
      return ['Cleanup', 'Restore', 'Verification'];
    } else if (filePath.contains('update')) {
      return ['Migration', 'Validation'];
    } else if (filePath.contains('bootstrap')) {
      return ['Analysis', 'Generation', 'Validation'];
    } else if (filePath.contains('use')) {
      return ['Usage', 'Best Practices'];
    }
    return [];
  }

  /// Extracts missing items from verification results.
  List<String> _getMissingItems(List<Map<String, dynamic>> results) {
    return results
        .where((r) => r['status'] != 'PASS' && r['critical'] == true)
        .map((r) => '${r["item"]}: ${r["details"]}')
        .toList()
        .cast<String>();
  }

  /// Generates warnings for non-critical issues.
  List<String> _getWarnings(List filesModified) {
    final warnings = <String>[];

    for (final file in filesModified) {
      final loc = file['loc'] as int? ?? 0;
      if (loc > 500 && loc <= 800) {
        warnings.add(
          '${file["path"]}: Consider reducing from $loc to <500 LOC for better agent readability',
        );
      }
    }

    return warnings;
  }

  Map<String, dynamic> _errorResponse(String message) {
    return {
      'success': false,
      'error': message,
    };
  }

  /// Parses a parameter that can be either a List or a JSON string.
  List _parseList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value;
    if (value is String) {
      try {
        final decoded = jsonDecode(value);
        return decoded is List ? decoded : [];
      } catch (e) {
        return [];
      }
    }
    return [];
  }

  /// Parses a parameter that can be either a Map or a JSON string.
  Map _parseMap(dynamic value) {
    if (value == null) return {};
    if (value is Map) return value;
    if (value is String) {
      try {
        final decoded = jsonDecode(value);
        return decoded is Map ? decoded : {};
      } catch (e) {
        return {};
      }
    }
    return {};
  }
}
