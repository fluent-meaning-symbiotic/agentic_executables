import 'dart:convert';

import '../ae_validation_config.dart';

/// Tool for evaluating AE implementation compliance with objective metrics.
class EvaluateAEComplianceTool {
  /// Evaluates implementation using structured metrics and hardcoded scoring.
  Map<String, dynamic> execute(Map<String, dynamic> params) {
    final contextType = params['context_type'] as String?;
    final action = params['action'] as String?;

    // Parse files_created (can be List or String)
    final filesCreated = _parseList(params['files_created']);

    // Parse sections_present (can be List or String)
    final sectionsPresent = _parseList(params['sections_present']);

    // Parse boolean flags (can be bool or String)
    final validationStepsExists = _parseBool(params['validation_steps_exists']);
    final integrationPointsDefined =
        _parseBool(params['integration_points_defined']);
    final reversibilityIncluded = _parseBool(params['reversibility_included']);
    final hasMetaRules = _parseBool(params['has_meta_rules']);

    // Validate required parameters
    if (contextType == null || contextType.isEmpty) {
      return _errorResponse('Parameter "context_type" is required');
    }
    if (!['library', 'project'].contains(contextType)) {
      return _errorResponse(
        'Invalid context_type. Must be "library" or "project"',
      );
    }
    if (action == null || action.isEmpty) {
      return _errorResponse('Parameter "action" is required');
    }
    if (!['bootstrap', 'install', 'uninstall', 'update', 'use']
        .contains(action)) {
      return _errorResponse(
        'Invalid action. Must be one of: bootstrap, install, uninstall, update, use',
      );
    }

    final evaluation = _evaluateMetrics(
      contextType: contextType,
      action: action,
      filesCreated: filesCreated,
      sectionsPresent: sectionsPresent,
      validationStepsExists: validationStepsExists,
      integrationPointsDefined: integrationPointsDefined,
      reversibilityIncluded: reversibilityIncluded,
      hasMetaRules: hasMetaRules,
    );

    return {
      'success': true,
      'context_type': contextType,
      'action': action,
      'evaluation': evaluation,
      'overall_status': evaluation['overall_pass'] ? 'PASS' : 'FAIL',
      'message': evaluation['overall_pass']
          ? 'Implementation meets AE compliance requirements.'
          : 'Implementation has issues that need to be addressed.',
    };
  }

  /// Evaluates metrics against hardcoded thresholds.
  Map<String, dynamic> _evaluateMetrics({
    required String contextType,
    required String action,
    required List filesCreated,
    required List sectionsPresent,
    required bool validationStepsExists,
    required bool integrationPointsDefined,
    required bool reversibilityIncluded,
    required bool hasMetaRules,
  }) {
    final results = <Map<String, dynamic>>[];
    var passCount = 0;
    var totalChecks = 0;

    // Check 1: Required files present
    final requiredFiles = _getRequiredFiles(contextType, action);
    final createdPaths = filesCreated.map((f) => f['path'] as String).toList();
    final missingFiles =
        requiredFiles.where((f) => !createdPaths.contains(f)).toList();
    final filesPass = missingFiles.isEmpty;

    totalChecks++;
    if (filesPass) passCount++;

    results.add({
      'criterion': 'Required Files',
      'status': filesPass ? 'PASS' : 'FAIL',
      'details': filesPass
          ? 'All required files present: ${requiredFiles.join(", ")}'
          : 'Missing files: ${missingFiles.join(", ")}',
      'critical': true,
    });

    // Check 2: LOC per file (lower is better)
    final locResults = <String>[];
    var locPass = true;
    var locWarning = false;

    for (final file in filesCreated) {
      final filePath = file['path'] as String;
      final loc = file['loc'] as int? ?? 0;

      if (loc > AEValidationConfig.maxLoc) {
        locPass = false;
        locResults.add(
            '$filePath: $loc LOC (FAIL - too verbose, should be <${AEValidationConfig.maxLoc})');
      } else if (loc > AEValidationConfig.warningLoc) {
        locWarning = true;
        locResults.add(
            '$filePath: $loc LOC (WARNING - consider reducing to <${AEValidationConfig.warningLoc})');
      } else {
        locResults.add('$filePath: $loc LOC (PASS - concise)');
      }
    }

    totalChecks++;
    if (locPass) passCount++;

    results.add({
      'criterion': 'Documentation Conciseness',
      'status':
          locPass ? (locWarning ? 'PASS (with warnings)' : 'PASS') : 'FAIL',
      'details': locResults.join('; '),
      'critical': true,
    });

    // Check 3: Required sections present
    final requiredSections = _getRequiredSections(action);
    final missingSections =
        requiredSections.where((s) => !sectionsPresent.contains(s)).toList();
    final sectionsPass = missingSections.isEmpty;

    totalChecks++;
    if (sectionsPass) passCount++;

    results.add({
      'criterion': 'Required Sections',
      'status': sectionsPass ? 'PASS' : 'FAIL',
      'details': sectionsPass
          ? 'All required sections present: ${requiredSections.join(", ")}'
          : 'Missing sections: ${missingSections.join(", ")}',
      'critical': true,
    });

    // Check 4: Validation steps (action-specific)
    if (_requiresValidation(action)) {
      totalChecks++;
      if (validationStepsExists) passCount++;

      results.add({
        'criterion': 'Validation Steps',
        'status': validationStepsExists ? 'PASS' : 'FAIL',
        'details': validationStepsExists
            ? 'Validation steps are defined'
            : 'Validation steps are missing',
        'critical': true,
      });
    }

    // Check 5: Integration points (action-specific)
    if (_requiresIntegration(action)) {
      totalChecks++;
      if (integrationPointsDefined) passCount++;

      results.add({
        'criterion': 'Integration Points',
        'status': integrationPointsDefined ? 'PASS' : 'FAIL',
        'details': integrationPointsDefined
            ? 'Integration points are defined'
            : 'Integration points are missing',
        'critical': true,
      });
    }

    // Check 6: Reversibility (action-specific)
    if (_requiresReversibility(action)) {
      totalChecks++;
      if (reversibilityIncluded) passCount++;

      results.add({
        'criterion': 'Reversibility',
        'status': reversibilityIncluded ? 'PASS' : 'FAIL',
        'details': reversibilityIncluded
            ? 'Reversibility procedures are included'
            : 'Reversibility procedures are missing',
        'critical': true,
      });
    }

    // Check 7: Meta-rules (action-specific)
    if (_requiresMetaRules(action)) {
      totalChecks++;
      if (hasMetaRules) passCount++;

      results.add({
        'criterion': 'Meta-rules',
        'status': hasMetaRules ? 'PASS' : 'FAIL',
        'details': hasMetaRules
            ? 'Meta-rules for agent guidance are present'
            : 'Meta-rules are missing',
        'critical': true,
      });
    }

    final overallPass = passCount == totalChecks;

    return {
      'overall_pass': overallPass,
      'pass_count': passCount,
      'total_checks': totalChecks,
      'pass_rate':
          totalChecks > 0 ? (passCount / totalChecks * 100).round() : 0,
      'checks': results,
      'actionable_fixes': _generateActionableFixes(results),
    };
  }

  /// Returns required files based on context and action.
  List<String> _getRequiredFiles(String contextType, String action) {
    return AEValidationConfig.getRequiredFiles(contextType, action);
  }

  /// Returns required sections based on action.
  List<String> _getRequiredSections(String action) {
    return AEValidationConfig.getRequiredSections(action);
  }

  bool _requiresValidation(String action) =>
      AEValidationConfig.requiresValidation(action);

  bool _requiresIntegration(String action) =>
      AEValidationConfig.requiresIntegration(action);

  bool _requiresReversibility(String action) =>
      AEValidationConfig.requiresReversibility(action);

  bool _requiresMetaRules(String action) =>
      AEValidationConfig.requiresMetaRules(action);

  /// Generates actionable fixes for failed checks.
  List<String> _generateActionableFixes(List<Map<String, dynamic>> results) {
    final fixes = <String>[];

    for (final result in results) {
      if (result['status'] != 'PASS') {
        final criterion = result['criterion'] as String;
        final details = result['details'] as String;

        switch (criterion) {
          case 'Required Files':
            fixes.add('Create missing files: $details');
            break;
          case 'Documentation Conciseness':
            fixes.add(
              'Reduce documentation verbosity: $details. Focus on agent-executable instructions, not human explanations.',
            );
            break;
          case 'Required Sections':
            fixes.add('Add missing sections: $details');
            break;
          case 'Validation Steps':
            fixes.add(
              'Add validation steps to verify successful execution (e.g., check installation, verify configuration)',
            );
            break;
          case 'Integration Points':
            fixes.add(
              'Define clear integration points showing how to connect with existing codebase',
            );
            break;
          case 'Reversibility':
            fixes.add(
              'Add reversibility procedures to cleanly undo changes and restore original state',
            );
            break;
          case 'Meta-rules':
            fixes.add(
              'Include meta-rules that guide agents on how to adapt instructions to specific contexts',
            );
            break;
        }
      }
    }

    if (fixes.isEmpty) {
      fixes.add('All checks passed. Implementation is compliant.');
    }

    return fixes;
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

  /// Parses a parameter that can be either a bool or a string.
  bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true';
    }
    return false;
  }
}
