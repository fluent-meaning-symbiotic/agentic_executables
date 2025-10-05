/// Improve AE bootstrap tool for enhancing existing AE files
library improve_tool;

import '../../models/ae_context.dart';
import '../../utils/file_operations.dart';

/// Tool for improving existing AE bootstrap files
class ImproveTool {
  /// Improve existing AE bootstrap files
  static Future<AEOperationResult> improveAEBootstrap({
    required String libraryPath,
    required List<String> improvementGoals,
    Map<String, dynamic>? options,
  }) async {
    try {
      // Validate library path
      if (!await FileOperations.isDartProject(libraryPath)) {
        return AEOperationResult.failure(
          'Invalid library path: Not a Dart/Flutter project',
        );
      }

      // Check if AE files exist
      final aeFilesExist = await FileOperations.aeFilesExist(libraryPath);
      if (!aeFilesExist) {
        return AEOperationResult.failure(
          'AE files do not exist for this library. Use bootstrap_ae instead.',
        );
      }

      // Get library information
      final libraryInfo = await FileOperations.getLibraryInfo(libraryPath);
      if (libraryInfo == null) {
        return AEOperationResult.failure(
          'Could not read library information from pubspec.yaml',
        );
      }

      final libraryName = libraryInfo['name'] as String;
      final libraryVersion = libraryInfo['version'] as String? ?? '1.0.0';

      // Get existing AE files
      final existingFiles = await FileOperations.getExistingAEFiles(
        libraryPath,
      );

      // Improve each existing file
      final improvements = <String, String>{};

      for (final file in existingFiles) {
        final currentContent = await FileOperations.readAEFile(
          libraryPath,
          file,
        );
        if (currentContent != null) {
          final improvedContent = await _improveFileContent(
            file,
            currentContent,
            libraryName,
            libraryVersion,
            improvementGoals,
          );
          improvements[file] = improvedContent;
        }
      }

      // Write improved files
      for (final entry in improvements.entries) {
        await FileOperations.writeAEFile(libraryPath, entry.key, entry.value);
      }

      return AEOperationResult.success(
        'Successfully improved AE bootstrap files for $libraryName',
        data: {
          'libraryName': libraryName,
          'libraryVersion': libraryVersion,
          'improvedFiles': improvements.keys.toList(),
          'improvementGoals': improvementGoals,
        },
      );
    } catch (e) {
      return AEOperationResult.failure(
        'Failed to improve AE bootstrap files: ${e.toString()}',
        errors: [e.toString()],
      );
    }
  }

  /// Improve specific file content based on goals
  static Future<String> _improveFileContent(
    String fileName,
    String currentContent,
    String libraryName,
    String libraryVersion,
    List<String> improvementGoals,
  ) async {
    String improvedContent = currentContent;

    // Apply improvements based on goals
    for (final goal in improvementGoals) {
      switch (goal.toLowerCase()) {
        case 'add_examples':
          improvedContent = await _addExamples(
            improvedContent,
            fileName,
            libraryName,
          );
          break;
        case 'improve_documentation':
          improvedContent = await _improveDocumentation(
            improvedContent,
            fileName,
            libraryName,
          );
          break;
        case 'add_troubleshooting':
          improvedContent = await _addTroubleshooting(
            improvedContent,
            fileName,
            libraryName,
          );
          break;
        case 'add_validation':
          improvedContent = await _addValidation(
            improvedContent,
            fileName,
            libraryName,
          );
          break;
        case 'improve_structure':
          improvedContent = await _improveStructure(
            improvedContent,
            fileName,
            libraryName,
          );
          break;
        case 'add_best_practices':
          improvedContent = await _addBestPractices(
            improvedContent,
            fileName,
            libraryName,
          );
          break;
        case 'add_security_notes':
          improvedContent = await _addSecurityNotes(
            improvedContent,
            fileName,
            libraryName,
          );
          break;
        case 'add_performance_tips':
          improvedContent = await _addPerformanceTips(
            improvedContent,
            fileName,
            libraryName,
          );
          break;
        default:
          // Generic improvement
          improvedContent = await _genericImprovement(
            improvedContent,
            fileName,
            libraryName,
            goal,
          );
      }
    }

    return improvedContent;
  }

  /// Add examples to file content
  static Future<String> _addExamples(
    String content,
    String fileName,
    String libraryName,
  ) async {
    if (fileName == 'ae_install.md') {
      final examples = '''

## Advanced Examples

### Example 1: Custom Configuration
\`\`\`dart
// Custom configuration example
final config = ${libraryName}Config(
  // Add configuration parameters
);
\`\`\`

### Example 2: Error Handling
\`\`\`dart
try {
  // Library usage with error handling
  final result = await ${libraryName}Instance().performAction();
} catch (e) {
  // Handle errors gracefully
  print('Error: \$e');
}
\`\`\`

### Example 3: Integration with State Management
\`\`\`dart
// Example with Provider/Riverpod
class ${libraryName}Provider extends ChangeNotifier {
  late final ${libraryName}Instance _instance;
  
  ${libraryName}Provider() {
    _instance = ${libraryName}Instance();
  }
  
  // Add provider methods
}
\`\`\`
''';
      return content + examples;
    }
    return content;
  }

  /// Improve documentation quality
  static Future<String> _improveDocumentation(
    String content,
    String fileName,
    String libraryName,
  ) async {
    // Add more detailed explanations and better formatting
    String improved = content;

    // Improve markdown formatting
    improved = improved.replaceAll(RegExp(r'^# ', multiLine: true), '## ');
    improved = improved.replaceAll(RegExp(r'^## ', multiLine: true), '### ');

    // Add table of contents for longer files
    if (improved.length > 2000) {
      final toc = '''
## Table of Contents
- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Installation Steps](#installation-steps)
- [Configuration](#configuration)
- [Integration](#integration)
- [Validation](#validation)
- [Troubleshooting](#troubleshooting)

''';
      improved = toc + improved;
    }

    return improved;
  }

  /// Add troubleshooting section
  static Future<String> _addTroubleshooting(
    String content,
    String fileName,
    String libraryName,
  ) async {
    if (!content.toLowerCase().contains('troubleshooting')) {
      final troubleshooting = '''

## Troubleshooting

### Common Issues and Solutions

#### Issue 1: Compilation Errors
**Problem**: The library fails to compile
**Solution**: 
- Check Dart SDK version compatibility
- Verify import paths
- Clean and rebuild the project

#### Issue 2: Runtime Errors
**Problem**: The library throws runtime exceptions
**Solution**:
- Check initialization order
- Verify configuration parameters
- Enable debug logging

#### Issue 3: Performance Issues
**Problem**: The library causes performance degradation
**Solution**:
- Check for memory leaks
- Optimize usage patterns
- Consider caching strategies

### Debug Mode
Enable debug mode for detailed logging:

\`\`\`dart
// Enable debug mode
${libraryName}Instance.enableDebugMode();
\`\`\`

### Getting Help
- Check the [documentation](https://pub.dev/packages/$libraryName)
- Search [GitHub issues](https://github.com/your-org/$libraryName/issues)
- Join the [community Discord](https://discord.gg/your-community)
''';
      return content + troubleshooting;
    }
    return content;
  }

  /// Add validation section
  static Future<String> _addValidation(
    String content,
    String fileName,
    String libraryName,
  ) async {
    if (!content.toLowerCase().contains('validation')) {
      final validation = '''

## Validation

### Pre-Installation Checks
Before installing, verify:
- [ ] Dart SDK version compatibility
- [ ] Project structure compatibility
- [ ] Dependencies compatibility

### Post-Installation Validation
After installation, verify:
- [ ] Compilation succeeds
- [ ] Basic functionality works
- [ ] No runtime errors
- [ ] Performance is acceptable

### Automated Testing
Add automated tests to validate installation:

\`\`\`dart
import 'package:test/test.dart';
import 'package:$libraryName/$libraryName.dart';

void main() {
  test('${libraryName} installation validation', () {
    // Test basic functionality
    expect(() => ${libraryName}Instance(), returnsNormally);
  });
}
\`\`\`
''';
      return content + validation;
    }
    return content;
  }

  /// Improve file structure
  static Future<String> _improveStructure(
    String content,
    String fileName,
    String libraryName,
  ) async {
    // Reorganize content for better readability
    final sections = content.split('\n## ');
    if (sections.length > 1) {
      final header = sections[0];
      final bodySections = sections.skip(1).toList();

      // Sort sections by importance
      final sortedSections = _sortSectionsByImportance(bodySections);

      return header + '\n## ' + sortedSections.join('\n## ');
    }
    return content;
  }

  /// Add best practices section
  static Future<String> _addBestPractices(
    String content,
    String fileName,
    String libraryName,
  ) async {
    if (!content.toLowerCase().contains('best practices')) {
      final bestPractices = '''

## Best Practices

### Code Organization
- Keep library usage in dedicated service classes
- Use dependency injection for better testability
- Follow the single responsibility principle

### Error Handling
- Always wrap library calls in try-catch blocks
- Log errors appropriately
- Provide meaningful error messages to users

### Resource Management
- Dispose of resources properly
- Use weak references where appropriate
- Monitor memory usage

### Testing
- Write unit tests for library integration
- Use mock objects for testing
- Test error scenarios

### Performance
- Cache frequently used data
- Use lazy loading where appropriate
- Monitor performance metrics
''';
      return content + bestPractices;
    }
    return content;
  }

  /// Add security notes
  static Future<String> _addSecurityNotes(
    String content,
    String fileName,
    String libraryName,
  ) async {
    if (!content.toLowerCase().contains('security')) {
      final securityNotes = '''

## Security Considerations

### Data Protection
- Never store sensitive data in plain text
- Use encryption for sensitive information
- Validate all input data

### Network Security
- Use HTTPS for all network communications
- Validate SSL certificates
- Implement proper authentication

### Access Control
- Implement proper user authentication
- Use role-based access control
- Log security events

### Best Practices
- Keep the library updated to the latest version
- Monitor for security advisories
- Use secure coding practices
''';
      return content + securityNotes;
    }
    return content;
  }

  /// Add performance tips
  static Future<String> _addPerformanceTips(
    String content,
    String fileName,
    String libraryName,
  ) async {
    if (!content.toLowerCase().contains('performance')) {
      final performanceTips = '''

## Performance Tips

### Optimization Strategies
- Use lazy loading for large datasets
- Implement caching for expensive operations
- Optimize database queries

### Memory Management
- Dispose of objects when no longer needed
- Use object pooling for frequently created objects
- Monitor memory usage

### CPU Optimization
- Use asynchronous operations for I/O
- Implement background processing
- Optimize algorithms

### Monitoring
- Use performance profiling tools
- Monitor key performance indicators
- Set up alerts for performance degradation
''';
      return content + performanceTips;
    }
    return content;
  }

  /// Generic improvement based on goal
  static Future<String> _genericImprovement(
    String content,
    String fileName,
    String libraryName,
    String goal,
  ) async {
    // Add a generic improvement section
    final improvement = '''

## $goal

This section has been enhanced to better support $goal for $libraryName.

### Key Improvements
- Enhanced documentation clarity
- Added practical examples
- Improved error handling guidance
- Better integration patterns

### Usage Notes
- Follow the guidelines in this section
- Adapt examples to your specific use case
- Monitor for updates and improvements
''';
    return content + improvement;
  }

  /// Sort sections by importance
  static List<String> _sortSectionsByImportance(List<String> sections) {
    final importanceOrder = [
      'overview',
      'prerequisites',
      'installation',
      'configuration',
      'integration',
      'usage',
      'examples',
      'validation',
      'troubleshooting',
      'best practices',
      'security',
      'performance',
    ];

    sections.sort((a, b) {
      final aTitle = a.split('\n')[0].toLowerCase();
      final bTitle = b.split('\n')[0].toLowerCase();

      final aIndex = importanceOrder.indexWhere(
        (item) => aTitle.contains(item),
      );
      final bIndex = importanceOrder.indexWhere(
        (item) => bTitle.contains(item),
      );

      if (aIndex == -1 && bIndex == -1) return 0;
      if (aIndex == -1) return 1;
      if (bIndex == -1) return -1;

      return aIndex.compareTo(bIndex);
    });

    return sections;
  }
}
