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
        'description': 'Test',
      });
      expect(result['success'], false);
      expect(result['error'], contains('Invalid context_type'));
    });

    test('should validate action enum', () {
      final result = tool.execute({
        'context_type': 'library',
        'action': 'invalid',
        'description': 'Test',
      });
      expect(result['success'], false);
      expect(result['error'], contains('Invalid action'));
    });

    test('should generate checklist for library bootstrap', () {
      final result = tool.execute({
        'context_type': 'library',
        'action': 'bootstrap',
        'description': 'Bootstrapping AE for axios library',
      });
      expect(result['success'], true);
      expect(result['verification_checklist'], isA<List>());

      final checklist = result['verification_checklist'] as List;
      expect(checklist.length, greaterThan(0));

      // Should include core principles
      final principles =
          checklist.map((c) => c['principle'] as String).toList();
      expect(principles, contains('Modularity'));
      expect(principles, contains('Agent Empowerment'));
      expect(principles, contains('Analysis')); // Bootstrap-specific
    });

    test('should generate checklist for project install', () {
      final result = tool.execute({
        'context_type': 'project',
        'action': 'install',
        'description': 'Installing library as AE',
      });
      expect(result['success'], true);

      final checklist = result['verification_checklist'] as List;
      final principles =
          checklist.map((c) => c['principle'] as String).toList();
      expect(principles, contains('Validation'));
      expect(principles, contains('Integration'));
    });

    test('should include reversibility check for uninstall', () {
      final result = tool.execute({
        'context_type': 'project',
        'action': 'uninstall',
        'description': 'Uninstalling library',
      });
      expect(result['success'], true);

      final checklist = result['verification_checklist'] as List;
      final principles =
          checklist.map((c) => c['principle'] as String).toList();
      expect(principles, contains('Reversibility'));
      expect(principles, contains('Cleanup'));
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
      expect(result['error'], contains('implementation_details'));
    });

    test('should validate context_type', () {
      final result = tool.execute({
        'implementation_details': 'Test implementation',
        'context_type': 'invalid',
      });
      expect(result['success'], false);
      expect(result['error'], contains('Invalid context_type'));
    });

    test('should evaluate implementation with good indicators', () {
      final result = tool.execute({
        'implementation_details': '''
          Created modular, step-by-step instructions for autonomous AI agents.
          Included validation checks at each step to ensure reliability.
          Provided clear uninstall procedures to restore original state.
          Added contextual domain knowledge and integration points.
          Made documentation concise and agent-readable.
        ''',
        'context_type': 'library',
      });

      expect(result['success'], true);
      expect(result['evaluation'], isA<Map>());

      final evaluation = result['evaluation'] as Map<String, dynamic>;
      expect(evaluation['overall_score'], isA<int>());
      expect(evaluation['overall_rating'], isA<String>());
      expect(evaluation['principle_scores'], isA<List>());
      expect(evaluation['recommendations'], isA<List>());

      // Should have decent score with good indicators
      final overallScore = evaluation['overall_score'] as int;
      expect(overallScore, greaterThan(50));
    });

    test('should score principle components correctly', () {
      final result = tool.execute({
        'implementation_details': '''
          Autonomous agent can execute without manual intervention.
          Instructions structured in modular, reusable steps.
          Includes validation and verification at each stage.
        ''',
        'context_type': 'project',
      });

      final evaluation = result['evaluation'] as Map<String, dynamic>;
      final scores = evaluation['principle_scores'] as List;

      // Find Agent Empowerment score
      final agentEmpowerment = scores.firstWhere(
        (s) => s['principle'] == 'Agent Empowerment',
      );
      expect(agentEmpowerment['score'], greaterThan(0));

      // Find Modularity score
      final modularity = scores.firstWhere(
        (s) => s['principle'] == 'Modularity',
      );
      expect(modularity['score'], greaterThan(0));
    });

    test('should provide recommendations for low scores', () {
      final result = tool.execute({
        'implementation_details': 'Basic implementation',
        'context_type': 'library',
      });

      final evaluation = result['evaluation'] as Map<String, dynamic>;
      final recommendations = evaluation['recommendations'] as List;

      expect(recommendations, isNotEmpty);
      expect(recommendations.length, greaterThan(3));
    });
  });
}
