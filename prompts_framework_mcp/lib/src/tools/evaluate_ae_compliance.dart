/// Tool for evaluating AE implementation compliance with core principles.
class EvaluateAEComplianceTool {
  /// Evaluates implementation against AE core principles.
  Map<String, dynamic> execute(Map<String, dynamic> params) {
    final implementationDetails = params['implementation_details'] as String?;
    final contextType = params['context_type'] as String?;

    // Validate required parameters
    if (implementationDetails == null || implementationDetails.isEmpty) {
      return _errorResponse('Parameter "implementation_details" is required');
    }
    if (contextType == null || contextType.isEmpty) {
      return _errorResponse('Parameter "context_type" is required');
    }

    // Validate enum values
    if (!['library', 'project'].contains(contextType)) {
      return _errorResponse(
        'Invalid context_type. Must be "library" or "project"',
      );
    }

    final evaluation = _evaluatePrinciples(implementationDetails, contextType);

    return {
      'success': true,
      'context_type': contextType,
      'evaluation': evaluation,
      'message':
          'Evaluation completed. Review scores and recommendations below.',
    };
  }

  /// Evaluates implementation against core AE principles.
  Map<String, dynamic> _evaluatePrinciples(
    String implementation,
    String contextType,
  ) {
    final lowerImpl = implementation.toLowerCase();

    // Define evaluation criteria
    final criteria = [
      {
        'principle': 'Agent Empowerment',
        'weight': 20,
        'indicators': [
          'autonomous',
          'meta-rule',
          'ai agent',
          'without manual',
          'self-guided'
        ],
        'description':
            'Assesses if instructions enable AI agents to work autonomously',
      },
      {
        'principle': 'Modularity',
        'weight': 20,
        'indicators': [
          'step',
          'sequential',
          'modular',
          'reusable',
          'clear structure'
        ],
        'description':
            'Evaluates if instructions are structured in clear, reusable steps',
      },
      {
        'principle': 'Contextual Awareness',
        'weight': 20,
        'indicators': [
          'domain knowledge',
          'integration point',
          'context',
          'architecture',
          'analyze'
        ],
        'description':
            'Checks if sufficient domain knowledge is provided for understanding',
      },
      {
        'principle': 'Reversibility',
        'weight': 15,
        'indicators': [
          'uninstall',
          'remove',
          'cleanup',
          'restore',
          'original state'
        ],
        'description':
            'Verifies that operations can be cleanly reversed if applicable',
      },
      {
        'principle': 'Validation',
        'weight': 15,
        'indicators': ['check', 'verify', 'validate', 'test', 'ensure'],
        'description':
            'Confirms that validation steps are included for reliability',
      },
      {
        'principle': 'Documentation Quality',
        'weight': 10,
        'indicators': [
          'concise',
          'agent-readable',
          'clear',
          'explicit',
          'instruction'
        ],
        'description':
            'Assesses conciseness and agent-readability of documentation',
      },
    ];

    final scores = <Map<String, dynamic>>[];
    var totalWeightedScore = 0.0;
    var totalWeight = 0;

    for (final criterion in criteria) {
      final indicators = criterion['indicators'] as List<String>;
      final weight = criterion['weight'] as int;
      var matchCount = 0;

      // Count indicator matches
      for (final indicator in indicators) {
        if (lowerImpl.contains(indicator)) {
          matchCount++;
        }
      }

      // Calculate score (0-100)
      final score = (matchCount / indicators.length * 100).round();
      final weightedScore = score * weight / 100;
      totalWeightedScore += weightedScore;
      totalWeight += weight;

      scores.add({
        'principle': criterion['principle'],
        'score': score,
        'weight': weight,
        'weighted_score': weightedScore.round(),
        'description': criterion['description'],
        'assessment': _getAssessment(score),
      });
    }

    final overallScore = (totalWeightedScore / totalWeight * 100).round();

    return {
      'overall_score': overallScore,
      'overall_rating': _getOverallRating(overallScore),
      'principle_scores': scores,
      'recommendations': _generateRecommendations(scores, contextType),
      'note':
          'This is an automated heuristic evaluation. Manual review is recommended for accuracy.',
    };
  }

  String _getAssessment(int score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Fair';
    if (score >= 20) return 'Needs Improvement';
    return 'Critical - Requires Attention';
  }

  String _getOverallRating(int score) {
    if (score >= 80) return 'Highly Compliant';
    if (score >= 60) return 'Moderately Compliant';
    if (score >= 40) return 'Partially Compliant';
    return 'Non-Compliant';
  }

  List<String> _generateRecommendations(
    List<Map<String, dynamic>> scores,
    String contextType,
  ) {
    final recommendations = <String>[];

    for (final score in scores) {
      final principle = score['principle'] as String;
      final scoreValue = score['score'] as int;

      if (scoreValue < 60) {
        switch (principle) {
          case 'Agent Empowerment':
            recommendations.add(
              'Enhance agent autonomy: Include meta-rules and self-guided instructions that enable AI agents to make decisions independently.',
            );
            break;
          case 'Modularity':
            recommendations.add(
              'Improve modularity: Break down instructions into clear, sequential, reusable steps (Installation → Configuration → Integration → Usage).',
            );
            break;
          case 'Contextual Awareness':
            recommendations.add(
              'Add contextual awareness: Include domain knowledge, architecture details, and integration points to help agents understand the system.',
            );
            break;
          case 'Reversibility':
            recommendations.add(
              'Ensure reversibility: Provide clear uninstallation/cleanup procedures that restore the original state.',
            );
            break;
          case 'Validation':
            recommendations.add(
              'Include validation: Add checks, verification steps, and validation procedures to ensure reliability.',
            );
            break;
          case 'Documentation Quality':
            recommendations.add(
              'Improve documentation: Make instructions more concise, explicit, and agent-readable rather than verbose.',
            );
            break;
        }
      }
    }

    // Context-specific recommendations
    if (contextType == 'library') {
      recommendations.add(
        'Library context: Ensure instructions are language-agnostic and abstract enough to apply across different library types.',
      );
    } else {
      recommendations.add(
        'Project context: Ensure integration instructions consider existing project structure and dependencies.',
      );
    }

    if (recommendations.isEmpty) {
      recommendations.add(
        'Implementation shows good compliance with AE principles. Continue following these patterns.',
      );
    }

    return recommendations;
  }

  Map<String, dynamic> _errorResponse(String message) {
    return {
      'success': false,
      'error': message,
    };
  }
}
