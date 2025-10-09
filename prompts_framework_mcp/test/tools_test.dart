import 'package:prompts_framework_mcp/src/tools/evaluate_ae_compliance.dart';
import 'package:prompts_framework_mcp/src/tools/verify_ae_implementation.dart';
import 'package:test/test.dart';

void main() {
  group('VerifyAEImplementationTool', () {
    late VerifyAEImplementationTool tool;

    setUp(() {
      tool = VerifyAEImplementationTool();
    });

    test('should validate required parameters', () {
      final result = tool.execute({});
      expect(result['success'], false);
      expect(result['error'], contains('context_type'));
    });

    test('should validate context_type enum', () {
      final result = tool.execute({
        'context_type': 'invalid',
        'action': 'bootstrap',
      });
      expect(result['success'], false);
      expect(result['error'], contains('Invalid context_type'));
    });

    test('should validate action enum', () {
      final result = tool.execute({
        'context_type': 'library',
        'action': 'invalid',
      });
      expect(result['success'], false);
      expect(result['error'], contains('Invalid action'));
    });

    test('should pass verification for compliant library bootstrap', () {
      final result = tool.execute({
        'context_type': 'library',
        'action': 'bootstrap',
        'files_modified': [
          {
            'path': 'ae_bootstrap.md',
            'loc': 400,
            'sections': ['Analysis', 'Generation', 'Validation']
          },
          {'path': 'ae_install.md', 'loc': 350, 'sections': []},
          {'path': 'ae_uninstall.md', 'loc': 200, 'sections': []},
          {'path': 'ae_update.md', 'loc': 250, 'sections': []},
          {'path': 'ae_use.md', 'loc': 300, 'sections': []},
        ],
        'checklist_completed': {
          'modularity': true,
          'contextual_awareness': true,
          'agent_empowerment': true,
          'validation': true,
          'integration': true,
          'analysis_guidance': true,
          'file_generation_rules': true,
          'abstraction': true,
        },
      });

      expect(result['success'], true);
      expect(result['overall_status'], 'PASS');
      final verification = result['verification'] as Map;
      expect(verification['overall_pass'], true);
      expect(verification['checks'], isA<List>());
    });

    test('should fail verification for missing files', () {
      final result = tool.execute({
        'context_type': 'library',
        'action': 'bootstrap',
        'files_modified': [
          {'path': 'ae_bootstrap.md', 'loc': 400, 'sections': []},
        ],
        'checklist_completed': {
          'modularity': true,
          'contextual_awareness': true,
          'agent_empowerment': true,
        },
      });

      expect(result['success'], true);
      expect(result['overall_status'], 'FAIL');
      final verification = result['verification'] as Map;
      expect(verification['overall_pass'], false);
      expect(verification['missing_items'], isNotEmpty);
    });

    test('should warn about high LOC files', () {
      final result = tool.execute({
        'context_type': 'library',
        'action': 'bootstrap',
        'files_modified': [
          {'path': 'ae_bootstrap.md', 'loc': 600, 'sections': []},
          {'path': 'ae_install.md', 'loc': 550, 'sections': []},
          {'path': 'ae_uninstall.md', 'loc': 520, 'sections': []},
          {'path': 'ae_update.md', 'loc': 510, 'sections': []},
          {'path': 'ae_use.md', 'loc': 505, 'sections': []},
        ],
        'checklist_completed': {
          'modularity': true,
          'contextual_awareness': true,
          'agent_empowerment': true,
          'validation': true,
          'integration': true,
          'analysis_guidance': true,
          'file_generation_rules': true,
          'abstraction': true,
        },
      });

      final verification = result['verification'] as Map;
      expect(verification['warnings'], isNotEmpty);
    });

    test('should fail verification for excessive LOC', () {
      final result = tool.execute({
        'context_type': 'library',
        'action': 'bootstrap',
        'files_modified': [
          {'path': 'ae_bootstrap.md', 'loc': 900, 'sections': []},
          {'path': 'ae_install.md', 'loc': 350, 'sections': []},
          {'path': 'ae_uninstall.md', 'loc': 200, 'sections': []},
          {'path': 'ae_update.md', 'loc': 250, 'sections': []},
          {'path': 'ae_use.md', 'loc': 300, 'sections': []},
        ],
        'checklist_completed': {
          'modularity': true,
          'contextual_awareness': true,
          'agent_empowerment': true,
          'validation': true,
          'integration': true,
          'analysis_guidance': true,
          'file_generation_rules': true,
          'abstraction': true,
        },
      });

      expect(result['overall_status'], 'FAIL');
      final verification = result['verification'] as Map;
      expect(verification['overall_pass'], false);
    });

    test('should verify required checklist items for install', () {
      final result = tool.execute({
        'context_type': 'project',
        'action': 'install',
        'files_modified': [],
        'checklist_completed': {
          'modularity': true,
          'contextual_awareness': true,
          'agent_empowerment': true,
          'validation': true,
          'integration': true,
        },
      });

      expect(result['success'], true);
      final verification = result['verification'] as Map;
      final checks = verification['checks'] as List;

      final checkNames = checks.map((c) => c['item']).toList();
      expect(checkNames.any((n) => n.toString().contains('Modularity')), true);
      expect(checkNames.any((n) => n.toString().contains('Validation')), true);
      expect(checkNames.any((n) => n.toString().contains('Integration')), true);
    });

    test('should handle JSON string inputs', () {
      final result = tool.execute({
        'context_type': 'library',
        'action': 'bootstrap',
        'files_modified':
            '[{"path": "ae_bootstrap.md", "loc": 400}, {"path": "ae_install.md", "loc": 350}, {"path": "ae_uninstall.md", "loc": 200}, {"path": "ae_update.md", "loc": 250}, {"path": "ae_use.md", "loc": 300}]',
        'checklist_completed':
            '{"modularity": true, "contextual_awareness": true, "agent_empowerment": true, "validation": true, "integration": true, "analysis_guidance": true, "file_generation_rules": true, "abstraction": true}',
      });

      expect(result['success'], true);
      expect(result['overall_status'], 'PASS');
    });
  });

  group('EvaluateAEComplianceTool', () {
    late EvaluateAEComplianceTool tool;

    setUp(() {
      tool = EvaluateAEComplianceTool();
    });

    test('should validate required parameters', () {
      final result = tool.execute({});
      expect(result['success'], false);
      expect(result['error'], contains('context_type'));
    });

    test('should validate context_type', () {
      final result = tool.execute({
        'context_type': 'invalid',
        'action': 'bootstrap',
      });
      expect(result['success'], false);
      expect(result['error'], contains('Invalid context_type'));
    });

    test('should validate action parameter', () {
      final result = tool.execute({
        'context_type': 'library',
        'action': 'invalid',
      });
      expect(result['success'], false);
      expect(result['error'], contains('Invalid action'));
    });

    test('should pass evaluation for compliant implementation', () {
      final result = tool.execute({
        'context_type': 'library',
        'action': 'bootstrap',
        'files_created': [
          {'path': 'ae_bootstrap.md', 'loc': 400},
          {'path': 'ae_install.md', 'loc': 350},
          {'path': 'ae_uninstall.md', 'loc': 200},
          {'path': 'ae_update.md', 'loc': 250},
          {'path': 'ae_use.md', 'loc': 300},
        ],
        'sections_present': [
          'Analysis',
          'Generation',
          'Validation',
        ],
        'validation_steps_exists': true,
        'integration_points_defined': true,
        'reversibility_included': false,
        'has_meta_rules': true,
      });

      expect(result['success'], true);
      expect(result['overall_status'], 'PASS');

      final evaluation = result['evaluation'] as Map<String, dynamic>;
      expect(evaluation['overall_pass'], true);
      expect(evaluation['checks'], isA<List>());
      expect(evaluation['actionable_fixes'], isA<List>());
    });

    test('should fail evaluation for missing required files', () {
      final result = tool.execute({
        'context_type': 'library',
        'action': 'bootstrap',
        'files_created': [
          {'path': 'ae_bootstrap.md', 'loc': 400},
        ],
        'sections_present': ['Analysis', 'Generation', 'Validation'],
        'validation_steps_exists': true,
        'integration_points_defined': true,
        'has_meta_rules': true,
      });

      expect(result['success'], true);
      expect(result['overall_status'], 'FAIL');

      final evaluation = result['evaluation'] as Map<String, dynamic>;
      expect(evaluation['overall_pass'], false);
      expect(evaluation['actionable_fixes'], isNotEmpty);
    });

    test('should penalize excessive LOC', () {
      final result = tool.execute({
        'context_type': 'library',
        'action': 'bootstrap',
        'files_created': [
          {'path': 'ae_bootstrap.md', 'loc': 900},
          {'path': 'ae_install.md', 'loc': 850},
          {'path': 'ae_uninstall.md', 'loc': 820},
          {'path': 'ae_update.md', 'loc': 810},
          {'path': 'ae_use.md', 'loc': 805},
        ],
        'sections_present': ['Analysis', 'Generation', 'Validation'],
        'validation_steps_exists': true,
        'integration_points_defined': true,
        'has_meta_rules': true,
      });

      expect(result['overall_status'], 'FAIL');

      final evaluation = result['evaluation'] as Map<String, dynamic>;
      expect(evaluation['overall_pass'], false);

      final checks = evaluation['checks'] as List;
      final locCheck = checks.firstWhere(
        (c) => c['criterion'] == 'Documentation Conciseness',
      );
      expect(locCheck['status'], 'FAIL');
    });

    test('should warn about moderate LOC', () {
      final result = tool.execute({
        'context_type': 'library',
        'action': 'bootstrap',
        'files_created': [
          {'path': 'ae_bootstrap.md', 'loc': 600},
          {'path': 'ae_install.md', 'loc': 550},
          {'path': 'ae_uninstall.md', 'loc': 520},
          {'path': 'ae_update.md', 'loc': 510},
          {'path': 'ae_use.md', 'loc': 505},
        ],
        'sections_present': ['Analysis', 'Generation', 'Validation'],
        'validation_steps_exists': true,
        'integration_points_defined': true,
        'has_meta_rules': true,
      });

      final evaluation = result['evaluation'] as Map<String, dynamic>;
      final checks = evaluation['checks'] as List;
      final locCheck = checks.firstWhere(
        (c) => c['criterion'] == 'Documentation Conciseness',
      );
      expect(locCheck['status'], contains('warnings'));
    });

    test('should fail evaluation for missing required sections', () {
      final result = tool.execute({
        'context_type': 'library',
        'action': 'bootstrap',
        'files_created': [
          {'path': 'ae_bootstrap.md', 'loc': 400},
          {'path': 'ae_install.md', 'loc': 350},
          {'path': 'ae_uninstall.md', 'loc': 200},
          {'path': 'ae_update.md', 'loc': 250},
          {'path': 'ae_use.md', 'loc': 300},
        ],
        'sections_present': ['Analysis'], // Missing Generation and Validation
        'validation_steps_exists': true,
        'integration_points_defined': true,
        'has_meta_rules': true,
      });

      expect(result['overall_status'], 'FAIL');

      final evaluation = result['evaluation'] as Map<String, dynamic>;
      expect(evaluation['overall_pass'], false);

      final checks = evaluation['checks'] as List;
      final sectionsCheck = checks.firstWhere(
        (c) => c['criterion'] == 'Required Sections',
      );
      expect(sectionsCheck['status'], 'FAIL');
    });

    test('should check action-specific requirements', () {
      // Test install action requires validation
      final installResult = tool.execute({
        'context_type': 'project',
        'action': 'install',
        'files_created': [],
        'sections_present': [
          'Installation',
          'Configuration',
          'Integration',
          'Validation'
        ],
        'validation_steps_exists': false, // Missing!
        'integration_points_defined': true,
      });

      expect(installResult['overall_status'], 'FAIL');

      // Test uninstall action requires reversibility
      final uninstallResult = tool.execute({
        'context_type': 'project',
        'action': 'uninstall',
        'files_created': [],
        'sections_present': ['Cleanup', 'Restore', 'Verification'],
        'reversibility_included': false, // Missing!
      });

      expect(uninstallResult['overall_status'], 'FAIL');
    });

    test('should handle JSON string inputs', () {
      final result = tool.execute({
        'context_type': 'library',
        'action': 'bootstrap',
        'files_created':
            '[{"path": "ae_bootstrap.md", "loc": 400}, {"path": "ae_install.md", "loc": 350}, {"path": "ae_uninstall.md", "loc": 200}, {"path": "ae_update.md", "loc": 250}, {"path": "ae_use.md", "loc": 300}]',
        'sections_present': '["Analysis", "Generation", "Validation"]',
        'validation_steps_exists': 'true',
        'integration_points_defined': 'true',
        'has_meta_rules': 'true',
      });

      expect(result['success'], true);
      expect(result['overall_status'], 'PASS');
    });

    test('should provide actionable fixes for failures', () {
      final result = tool.execute({
        'context_type': 'library',
        'action': 'bootstrap',
        'files_created': [
          {'path': 'ae_bootstrap.md', 'loc': 900}, // Too verbose
        ],
        'sections_present': [], // Missing sections
        'validation_steps_exists': false,
        'integration_points_defined': false,
        'has_meta_rules': false,
      });

      final evaluation = result['evaluation'] as Map<String, dynamic>;
      final fixes = evaluation['actionable_fixes'] as List;

      expect(fixes, isNotEmpty);
      expect(fixes.length, greaterThan(3));
      expect(
        fixes.any((f) =>
            f.toString().contains('LOC') || f.toString().contains('verbosity')),
        true,
      );
    });
  });
}
