/// Example usage of AE MCP Server
import 'package:ae_mcp_server/ae_mcp_server.dart';

/// Example demonstrating how to use the AE MCP Server tools
void main() async {
  // Example library and project paths
  const libraryPath = '/path/to/example_library';
  const targetProjectPath = '/path/to/target_project';
  const targetAIAgent = 'Cursor AI';

  print('AE MCP Server Example Usage');
  print('==========================');

  // Example 1: Bootstrap AE files for a library
  print('\n1. Bootstrapping AE files...');
  try {
    final bootstrapResult = await BootstrapTool.bootstrapAE(
      libraryPath: libraryPath,
      targetAIAgent: targetAIAgent,
      options: {'includeExamples': true, 'addSecurityNotes': true},
    );

    if (bootstrapResult.success) {
      print('✅ Bootstrap successful: ${bootstrapResult.message}');
      print('Generated files: ${bootstrapResult.data?['generatedFiles']}');
    } else {
      print('❌ Bootstrap failed: ${bootstrapResult.message}');
      if (bootstrapResult.errors != null) {
        print('Errors: ${bootstrapResult.errors}');
      }
    }
  } catch (e) {
    print('❌ Bootstrap error: $e');
  }

  // Example 2: Improve existing AE files
  print('\n2. Improving AE files...');
  try {
    final improveResult = await ImproveTool.improveAEBootstrap(
      libraryPath: libraryPath,
      improvementGoals: [
        'add_examples',
        'improve_documentation',
        'add_troubleshooting',
        'add_best_practices',
      ],
      options: {
        'targetAudience': 'developers',
        'includeAdvancedExamples': true,
      },
    );

    if (improveResult.success) {
      print('✅ Improvement successful: ${improveResult.message}');
      print('Improved files: ${improveResult.data?['improvedFiles']}');
    } else {
      print('❌ Improvement failed: ${improveResult.message}');
      if (improveResult.errors != null) {
        print('Errors: ${improveResult.errors}');
      }
    }
  } catch (e) {
    print('❌ Improvement error: $e');
  }

  // Example 3: Install library as AE
  print('\n3. Installing library as AE...');
  try {
    final installResult = await InstallTool.installAE(
      libraryPath: libraryPath,
      targetProjectPath: targetProjectPath,
      options: {'skipDependencyCheck': false, 'backupExisting': true},
    );

    if (installResult.success) {
      print('✅ Installation successful: ${installResult.message}');
      print('Installed files: ${installResult.data?['installedFiles']}');
    } else {
      print('❌ Installation failed: ${installResult.message}');
      if (installResult.errors != null) {
        print('Errors: ${installResult.errors}');
      }
    }
  } catch (e) {
    print('❌ Installation error: $e');
  }

  // Example 4: Validate installation
  print('\n4. Validating installation...');
  try {
    final validationResult = await InstallTool.validateInstallation(
      targetProjectPath: targetProjectPath,
      libraryName: 'example_library',
    );

    if (validationResult.success) {
      print('✅ Validation successful: ${validationResult.message}');
      print('Validation checks: ${validationResult.data?['validationChecks']}');
    } else {
      print('❌ Validation failed: ${validationResult.message}');
      if (validationResult.errors != null) {
        print('Errors: ${validationResult.errors}');
      }
    }
  } catch (e) {
    print('❌ Validation error: $e');
  }

  // Example 5: Get installation status
  print('\n5. Getting installation status...');
  try {
    final statusResult = await InstallTool.getInstallationStatus(
      targetProjectPath: targetProjectPath,
      libraryName: 'example_library',
    );

    if (statusResult.success) {
      print('✅ Status retrieved: ${statusResult.message}');
      print('Status: ${statusResult.data?['status']}');
      print('AE files exist: ${statusResult.data?['aeFilesExist']}');
      print('Usage file exists: ${statusResult.data?['usageFileExists']}');
    } else {
      print('❌ Status retrieval failed: ${statusResult.message}');
      if (statusResult.errors != null) {
        print('Errors: ${statusResult.errors}');
      }
    }
  } catch (e) {
    print('❌ Status error: $e');
  }

  // Example 6: Uninstall library as AE
  print('\n6. Uninstalling library as AE...');
  try {
    final uninstallResult = await UninstallTool.uninstallAE(
      libraryPath: libraryPath,
      targetProjectPath: targetProjectPath,
      options: {'deepClean': true, 'backupBeforeRemoval': true},
    );

    if (uninstallResult.success) {
      print('✅ Uninstallation successful: ${uninstallResult.message}');
      print('Removed files: ${uninstallResult.data?['removedFiles']}');
    } else {
      print('❌ Uninstallation failed: ${uninstallResult.message}');
      if (uninstallResult.errors != null) {
        print('Errors: ${uninstallResult.errors}');
      }
    }
  } catch (e) {
    print('❌ Uninstallation error: $e');
  }

  // Example 7: Validate uninstallation
  print('\n7. Validating uninstallation...');
  try {
    final validationResult = await UninstallTool.validateUninstallation(
      targetProjectPath: targetProjectPath,
      libraryName: 'example_library',
    );

    if (validationResult.success) {
      print(
        '✅ Uninstallation validation successful: ${validationResult.message}',
      );
      print('Validation checks: ${validationResult.data?['validationChecks']}');
    } else {
      print('❌ Uninstallation validation failed: ${validationResult.message}');
      if (validationResult.errors != null) {
        print('Errors: ${validationResult.errors}');
      }
    }
  } catch (e) {
    print('❌ Uninstallation validation error: $e');
  }

  // Example 8: Deep clean
  print('\n8. Performing deep clean...');
  try {
    final deepCleanResult = await UninstallTool.deepClean(
      targetProjectPath: targetProjectPath,
      libraryName: 'example_library',
    );

    if (deepCleanResult.success) {
      print('✅ Deep clean successful: ${deepCleanResult.message}');
      print('Removed files: ${deepCleanResult.data?['removedFiles']}');
    } else {
      print('❌ Deep clean failed: ${deepCleanResult.message}');
      if (deepCleanResult.errors != null) {
        print('Errors: ${deepCleanResult.errors}');
      }
    }
  } catch (e) {
    print('❌ Deep clean error: $e');
  }

  print('\nExample completed!');
}
