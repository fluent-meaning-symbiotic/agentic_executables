/// Bootstrap AE tool for creating AE files for libraries
library bootstrap_tool;

import '../../models/ae_context.dart';
import '../../utils/file_operations.dart';

/// Tool for bootstrapping AE files for a library
class BootstrapTool {
  /// Bootstrap AE files for a library
  static Future<AEOperationResult> bootstrapAE({
    required String libraryPath,
    required String targetAIAgent,
    Map<String, dynamic>? options,
  }) async {
    try {
      // Validate library path
      if (!await FileOperations.isDartProject(libraryPath)) {
        return AEOperationResult.failure(
          'Invalid library path: Not a Dart/Flutter project',
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

      // Check if AE files already exist
      final aeFilesExist = await FileOperations.aeFilesExist(libraryPath);
      if (aeFilesExist) {
        return AEOperationResult.failure(
          'AE files already exist for this library. Use improve_ae_bootstrap instead.',
        );
      }

      // Generate AE files
      await _generateInstallFile(libraryPath, libraryName, libraryVersion);
      await _generateUninstallFile(libraryPath, libraryName, libraryVersion);
      await _generateUpdateFile(libraryPath, libraryName, libraryVersion);
      await _generateUsageFile(libraryPath, libraryName, targetAIAgent);

      return AEOperationResult.success(
        'Successfully bootstrapped AE files for $libraryName',
        data: {
          'libraryName': libraryName,
          'libraryVersion': libraryVersion,
          'generatedFiles': [
            'ae_install.md',
            'ae_uninstall.md',
            'ae_update.md',
            '${libraryName}_usage.mdc',
          ],
        },
      );
    } catch (e) {
      return AEOperationResult.failure(
        'Failed to bootstrap AE files: ${e.toString()}',
        errors: [e.toString()],
      );
    }
  }

  /// Generate ae_install.md file
  static Future<void> _generateInstallFile(
    String libraryPath,
    String libraryName,
    String libraryVersion,
  ) async {
    final content = '''# $libraryName Installation Guide

## Overview
This document provides installation instructions for $libraryName v$libraryVersion as an Agentic Executable (AE).

## Prerequisites
- Dart SDK >= 3.0.0
- Flutter SDK (if using Flutter)
- Target AI Agent: Cursor AI

## Installation Steps

### 1. Add Dependency
Add $libraryName to your project's pubspec.yaml:

\`\`\`yaml
dependencies:
  $libraryName: ^$libraryVersion
\`\`\`

### 2. Install Dependencies
Run the following command to install the package:

\`\`\`bash
flutter pub get
# or
dart pub get
\`\`\`

### 3. Import and Initialize
Add the necessary imports to your Dart files:

\`\`\`dart
import 'package:$libraryName/$libraryName.dart';
\`\`\`

### 4. Configuration
Configure the library according to your project needs:

\`\`\`dart
// Add configuration code here
\`\`\`

### 5. Integration
Integrate the library into your application:

\`\`\`dart
// Add integration code here
\`\`\`

## Validation
After installation, verify the setup by:

1. Running your application
2. Checking for any compilation errors
3. Testing basic functionality

## Troubleshooting
Common issues and solutions:

- **Compilation errors**: Check Dart SDK version compatibility
- **Import errors**: Verify package name and import paths
- **Runtime errors**: Check configuration and initialization

## Next Steps
- Review the usage guide: \`${libraryName}_usage.mdc\`
- Check for updates: \`ae_update.md\`
- Uninstall if needed: \`ae_uninstall.md\`
''';

    await FileOperations.writeAEFile(libraryPath, 'ae_install.md', content);
  }

  /// Generate ae_uninstall.md file
  static Future<void> _generateUninstallFile(
    String libraryPath,
    String libraryName,
    String libraryVersion,
  ) async {
    final content = '''# $libraryName Uninstallation Guide

## Overview
This document provides uninstallation instructions for $libraryName v$libraryVersion to restore your project to its original state.

## Uninstallation Steps

### 1. Remove Dependencies
Remove $libraryName from your project's pubspec.yaml:

\`\`\`yaml
dependencies:
  # Remove this line:
  # $libraryName: ^$libraryVersion
\`\`\`

### 2. Clean Dependencies
Run the following command to clean up dependencies:

\`\`\`bash
flutter pub get
# or
dart pub get
\`\`\`

### 3. Remove Imports
Remove all imports of $libraryName from your Dart files:

\`\`\`dart
// Remove this line:
// import 'package:$libraryName/$libraryName.dart';
\`\`\`

### 4. Remove Configuration
Remove any configuration code related to $libraryName:

\`\`\`dart
// Remove configuration code
\`\`\`

### 5. Remove Integration
Remove any integration code related to $libraryName:

\`\`\`dart
// Remove integration code
\`\`\`

### 6. Clean Up Resources
Remove any files, assets, or resources added by $libraryName.

## Validation
After uninstallation, verify the cleanup by:

1. Running your application
2. Checking for any compilation errors
3. Ensuring no references to $libraryName remain

## Troubleshooting
Common issues and solutions:

- **Compilation errors**: Check for remaining imports or references
- **Runtime errors**: Verify all code has been removed
- **Dependency conflicts**: Clean and rebuild the project

## Reinstallation
If you need to reinstall $libraryName later, use the installation guide: \`ae_install.md\`
''';

    await FileOperations.writeAEFile(libraryPath, 'ae_uninstall.md', content);
  }

  /// Generate ae_update.md file
  static Future<void> _generateUpdateFile(
    String libraryPath,
    String libraryName,
    String libraryVersion,
  ) async {
    final content = '''# $libraryName Update Guide

## Overview
This document provides update instructions for $libraryName from one version to another.

## Update Process

### 1. Backup Current State
Before updating, backup your current configuration and data:

\`\`\`bash
# Create a backup of your project
cp -r your_project your_project_backup
\`\`\`

### 2. Check Current Version
Verify your current version in pubspec.yaml:

\`\`\`yaml
dependencies:
  $libraryName: ^$libraryVersion  # Current version
\`\`\`

### 3. Update Dependency
Update the version in pubspec.yaml:

\`\`\`yaml
dependencies:
  $libraryName: ^NEW_VERSION  # New version
\`\`\`

### 4. Install Updated Dependencies
Run the following command to install the updated package:

\`\`\`bash
flutter pub get
# or
dart pub get
\`\`\`

### 5. Handle Breaking Changes
Review the changelog for breaking changes and update your code accordingly:

\`\`\`dart
// Update code to handle breaking changes
\`\`\`

### 6. Update Configuration
Update any configuration that may have changed:

\`\`\`dart
// Update configuration code
\`\`\`

### 7. Test Integration
Test your application to ensure everything works correctly:

\`\`\`bash
flutter test
# or
dart test
\`\`\`

## Validation
After updating, verify the update by:

1. Running your application
2. Checking for any compilation errors
3. Testing all functionality
4. Comparing behavior with previous version

## Troubleshooting
Common issues and solutions:

- **Compilation errors**: Check for breaking changes in the changelog
- **Runtime errors**: Verify configuration updates
- **Dependency conflicts**: Clean and rebuild the project

## Rollback
If the update causes issues, you can rollback:

1. Restore from backup
2. Revert pubspec.yaml changes
3. Run \`flutter pub get\` or \`dart pub get\`

## Next Steps
- Review the usage guide: \`${libraryName}_usage.mdc\`
- Check for further updates
- Report any issues to the library maintainers
''';

    await FileOperations.writeAEFile(libraryPath, 'ae_update.md', content);
  }

  /// Generate usage file for specific AI agent
  static Future<void> _generateUsageFile(
    String libraryPath,
    String libraryName,
    String targetAIAgent,
  ) async {
    final content = '''# $libraryName Usage Guide

## Overview
This document provides usage guidelines for $libraryName with $targetAIAgent.

## Basic Usage

### Import
\`\`\`dart
import 'package:$libraryName/$libraryName.dart';
\`\`\`

### Initialization
\`\`\`dart
// Initialize the library
final instance = ${libraryName}Instance();
\`\`\`

### Common Patterns
\`\`\`dart
// Add common usage patterns here
\`\`\`

## Best Practices

1. **Error Handling**: Always wrap library calls in try-catch blocks
2. **Resource Management**: Properly dispose of resources when done
3. **Configuration**: Use environment-specific configurations
4. **Testing**: Write unit tests for library integration

## Common Pitfalls

1. **Memory Leaks**: Ensure proper disposal of resources
2. **Configuration Errors**: Double-check configuration parameters
3. **Version Compatibility**: Verify compatibility with your Dart/Flutter version

## Examples

### Example 1: Basic Usage
\`\`\`dart
// Add basic usage example
\`\`\`

### Example 2: Advanced Usage
\`\`\`dart
// Add advanced usage example
\`\`\`

## Troubleshooting

### Common Issues
1. **Import Errors**: Check package name and import paths
2. **Runtime Errors**: Verify initialization and configuration
3. **Performance Issues**: Check for memory leaks and inefficient usage

### Debug Tips
1. Enable debug logging
2. Use Flutter Inspector for UI debugging
3. Check console output for error messages

## Integration with $targetAIAgent

This library is optimized for use with $targetAIAgent. Follow these guidelines:

1. Use the AI agent's recommended patterns
2. Leverage AI-assisted code generation
3. Follow the agent's coding standards

## Maintenance

- Keep the library updated to the latest version
- Monitor for security updates
- Review usage patterns regularly
- Optimize performance as needed

## Support

- Documentation: [Library Documentation](https://pub.dev/packages/$libraryName)
- Issues: [GitHub Issues](https://github.com/your-org/$libraryName/issues)
- Community: [Discord/Slack Channel](https://your-community-link)
''';

    await FileOperations.writeAEFile(
      libraryPath,
      '${libraryName}_usage.mdc',
      content,
    );
  }
}
