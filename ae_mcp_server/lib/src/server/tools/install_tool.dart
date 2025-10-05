/// Install library as AE tool
library install_tool;

import 'dart:io';

import '../../models/ae_context.dart';
import '../../utils/file_operations.dart';

/// Tool for installing a library as an Agentic Executable
class InstallTool {
  /// Install a library as AE
  static Future<AEOperationResult> installAE({
    required String libraryPath,
    required String targetProjectPath,
    Map<String, dynamic>? options,
  }) async {
    try {
      // Validate library path
      if (!await FileOperations.isDartProject(libraryPath)) {
        return AEOperationResult.failure(
          'Invalid library path: Not a Dart/Flutter project',
        );
      }

      // Validate target project path
      if (!await FileOperations.isDartProject(targetProjectPath)) {
        return AEOperationResult.failure(
          'Invalid target project path: Not a Dart/Flutter project',
        );
      }

      // Check if AE files exist in library
      final aeFilesExist = await FileOperations.aeFilesExist(libraryPath);
      if (!aeFilesExist) {
        return AEOperationResult.failure(
          'AE files do not exist for this library. Use bootstrap_ae first.',
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

      // Check if library is already installed
      final existingDependencies = await FileOperations.getProjectDependencies(
        targetProjectPath,
      );
      if (existingDependencies.contains(libraryName)) {
        return AEOperationResult.failure(
          'Library $libraryName is already installed in the target project.',
        );
      }

      // Execute installation steps
      await _addDependency(targetProjectPath, libraryName, libraryVersion);
      await _installDependencies(targetProjectPath);
      await _copyAEFiles(libraryPath, targetProjectPath);
      await _createUsageFile(libraryPath, targetProjectPath, libraryName);

      return AEOperationResult.success(
        'Successfully installed $libraryName as AE in target project',
        data: {
          'libraryName': libraryName,
          'libraryVersion': libraryVersion,
          'targetProject': targetProjectPath,
          'installedFiles': [
            'ae_install.md',
            'ae_uninstall.md',
            'ae_update.md',
            '${libraryName}_usage.mdc',
          ],
        },
      );
    } catch (e) {
      return AEOperationResult.failure(
        'Failed to install library as AE: ${e.toString()}',
        errors: [e.toString()],
      );
    }
  }

  /// Add dependency to target project
  static Future<void> _addDependency(
    String targetProjectPath,
    String libraryName,
    String libraryVersion,
  ) async {
    final pubspecFile = File('$targetProjectPath/pubspec.yaml');

    if (!await pubspecFile.exists()) {
      throw Exception('pubspec.yaml not found in target project');
    }

    final content = await pubspecFile.readAsString();
    final lines = content.split('\n');

    // Find dependencies section
    int dependenciesIndex = -1;
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].trim() == 'dependencies:') {
        dependenciesIndex = i;
        break;
      }
    }

    if (dependenciesIndex == -1) {
      throw Exception('Dependencies section not found in pubspec.yaml');
    }

    // Add the new dependency
    final newDependency = '  $libraryName: ^$libraryVersion';
    lines.insert(dependenciesIndex + 1, newDependency);

    // Write back to file
    await pubspecFile.writeAsString(lines.join('\n'));
  }

  /// Install dependencies using pub get
  static Future<void> _installDependencies(String targetProjectPath) async {
    // This would typically execute `flutter pub get` or `dart pub get`
    // For now, we'll just validate that the dependency was added
    final dependencies = await FileOperations.getProjectDependencies(
      targetProjectPath,
    );
    if (dependencies.isEmpty) {
      throw Exception('Failed to read dependencies after installation');
    }
  }

  /// Copy AE files from library to target project
  static Future<void> _copyAEFiles(
    String libraryPath,
    String targetProjectPath,
  ) async {
    await FileOperations.copyAEFiles(libraryPath, targetProjectPath);
  }

  /// Create usage file in target project
  static Future<void> _createUsageFile(
    String libraryPath,
    String targetProjectPath,
    String libraryName,
  ) async {
    final usageContent = await FileOperations.readAEFile(
      libraryPath,
      '${libraryName}_usage.mdc',
    );
    if (usageContent != null) {
      await FileOperations.writeAEFile(
        targetProjectPath,
        '${libraryName}_usage.mdc',
        usageContent,
      );
    }
  }

  /// Validate installation
  static Future<AEOperationResult> validateInstallation({
    required String targetProjectPath,
    required String libraryName,
  }) async {
    try {
      // Check if dependency was added
      final dependencies = await FileOperations.getProjectDependencies(
        targetProjectPath,
      );
      if (!dependencies.contains(libraryName)) {
        return AEOperationResult.failure(
          'Library $libraryName not found in project dependencies',
        );
      }

      // Check if AE files were copied
      final aeFilesExist = await FileOperations.aeFilesExist(targetProjectPath);
      if (!aeFilesExist) {
        return AEOperationResult.failure(
          'AE files not found in target project',
        );
      }

      // Check if usage file was created
      final usageFileExists = await File(
        '$targetProjectPath/ae_use/${libraryName}_usage.mdc',
      ).exists();
      if (!usageFileExists) {
        return AEOperationResult.failure(
          'Usage file not found in target project',
        );
      }

      return AEOperationResult.success(
        'Installation validation passed for $libraryName',
        data: {
          'libraryName': libraryName,
          'targetProject': targetProjectPath,
          'validationChecks': [
            'Dependency added',
            'AE files copied',
            'Usage file created',
          ],
        },
      );
    } catch (e) {
      return AEOperationResult.failure(
        'Installation validation failed: ${e.toString()}',
        errors: [e.toString()],
      );
    }
  }

  /// Get installation status
  static Future<AEOperationResult> getInstallationStatus({
    required String targetProjectPath,
    required String libraryName,
  }) async {
    try {
      final dependencies = await FileOperations.getProjectDependencies(
        targetProjectPath,
      );
      final isInstalled = dependencies.contains(libraryName);

      final aeFilesExist = await FileOperations.aeFilesExist(targetProjectPath);
      final usageFileExists = await File(
        '$targetProjectPath/ae_use/${libraryName}_usage.mdc',
      ).exists();

      return AEOperationResult.success(
        'Installation status retrieved',
        data: {
          'libraryName': libraryName,
          'targetProject': targetProjectPath,
          'isInstalled': isInstalled,
          'aeFilesExist': aeFilesExist,
          'usageFileExists': usageFileExists,
          'status': isInstalled ? 'installed' : 'not_installed',
        },
      );
    } catch (e) {
      return AEOperationResult.failure(
        'Failed to get installation status: ${e.toString()}',
        errors: [e.toString()],
      );
    }
  }
}
