/// Uninstall library as AE tool
library uninstall_tool;

import 'dart:io';

import '../../models/ae_context.dart';
import '../../utils/file_operations.dart';

/// Tool for uninstalling a library as an Agentic Executable
class UninstallTool {
  /// Uninstall a library as AE
  static Future<AEOperationResult> uninstallAE({
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

      // Get library information
      final libraryInfo = await FileOperations.getLibraryInfo(libraryPath);
      if (libraryInfo == null) {
        return AEOperationResult.failure(
          'Could not read library information from pubspec.yaml',
        );
      }

      final libraryName = libraryInfo['name'] as String;

      // Check if library is installed
      final existingDependencies = await FileOperations.getProjectDependencies(
        targetProjectPath,
      );
      if (!existingDependencies.contains(libraryName)) {
        return AEOperationResult.failure(
          'Library $libraryName is not installed in the target project.',
        );
      }

      // Execute uninstallation steps
      await _removeDependency(targetProjectPath, libraryName);
      await _cleanDependencies(targetProjectPath, libraryName);
      await _removeAEFiles(targetProjectPath, libraryName);
      await _removeUsageFile(targetProjectPath, libraryName);

      return AEOperationResult.success(
        'Successfully uninstalled $libraryName as AE from target project',
        data: {
          'libraryName': libraryName,
          'targetProject': targetProjectPath,
          'removedFiles': [
            'ae_install.md',
            'ae_uninstall.md',
            'ae_update.md',
            '${libraryName}_usage.mdc',
          ],
        },
      );
    } catch (e) {
      return AEOperationResult.failure(
        'Failed to uninstall library as AE: ${e.toString()}',
        errors: [e.toString()],
      );
    }
  }

  /// Remove dependency from target project
  static Future<void> _removeDependency(
    String targetProjectPath,
    String libraryName,
  ) async {
    final pubspecFile = File('$targetProjectPath/pubspec.yaml');

    if (!await pubspecFile.exists()) {
      throw Exception('pubspec.yaml not found in target project');
    }

    final content = await pubspecFile.readAsString();
    final lines = content.split('\n');

    // Find and remove the dependency line
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].trim().startsWith('$libraryName:')) {
        lines.removeAt(i);
        break;
      }
    }

    // Write back to file
    await pubspecFile.writeAsString(lines.join('\n'));
  }

  /// Clean dependencies using pub get
  static Future<void> _cleanDependencies(
      String targetProjectPath, String libraryName) async {
    // This would typically execute `flutter pub get` or `dart pub get`
    // For now, we'll just validate that the dependency was removed
    final dependencies = await FileOperations.getProjectDependencies(
      targetProjectPath,
    );
    if (dependencies.contains(libraryName)) {
      throw Exception('Failed to remove dependency from pubspec.yaml');
    }
  }

  /// Remove AE files from target project
  static Future<void> _removeAEFiles(
    String targetProjectPath,
    String libraryName,
  ) async {
    final aeFiles = [
      'ae_install.md',
      'ae_uninstall.md',
      'ae_update.md',
      'ae_use.md',
    ];

    for (final file in aeFiles) {
      await FileOperations.deleteAEFile(targetProjectPath, file);
    }
  }

  /// Remove usage file from target project
  static Future<void> _removeUsageFile(
    String targetProjectPath,
    String libraryName,
  ) async {
    await FileOperations.deleteAEFile(
      targetProjectPath,
      '${libraryName}_usage.mdc',
    );
  }

  /// Validate uninstallation
  static Future<AEOperationResult> validateUninstallation({
    required String targetProjectPath,
    required String libraryName,
  }) async {
    try {
      // Check if dependency was removed
      final dependencies = await FileOperations.getProjectDependencies(
        targetProjectPath,
      );
      if (dependencies.contains(libraryName)) {
        return AEOperationResult.failure(
          'Library $libraryName still found in project dependencies',
        );
      }

      // Check if AE files were removed
      final aeFilesExist = await FileOperations.aeFilesExist(targetProjectPath);
      if (aeFilesExist) {
        return AEOperationResult.failure(
          'AE files still exist in target project',
        );
      }

      // Check if usage file was removed
      final usageFileExists = await File(
        '$targetProjectPath/ae_use/${libraryName}_usage.mdc',
      ).exists();
      if (usageFileExists) {
        return AEOperationResult.failure(
          'Usage file still exists in target project',
        );
      }

      return AEOperationResult.success(
        'Uninstallation validation passed for $libraryName',
        data: {
          'libraryName': libraryName,
          'targetProject': targetProjectPath,
          'validationChecks': [
            'Dependency removed',
            'AE files removed',
            'Usage file removed',
          ],
        },
      );
    } catch (e) {
      return AEOperationResult.failure(
        'Uninstallation validation failed: ${e.toString()}',
        errors: [e.toString()],
      );
    }
  }

  /// Get uninstallation status
  static Future<AEOperationResult> getUninstallationStatus({
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
        'Uninstallation status retrieved',
        data: {
          'libraryName': libraryName,
          'targetProject': targetProjectPath,
          'isInstalled': isInstalled,
          'aeFilesExist': aeFilesExist,
          'usageFileExists': usageFileExists,
          'status': isInstalled ? 'installed' : 'uninstalled',
        },
      );
    } catch (e) {
      return AEOperationResult.failure(
        'Failed to get uninstallation status: ${e.toString()}',
        errors: [e.toString()],
      );
    }
  }

  /// Clean up all traces of the library
  static Future<AEOperationResult> deepClean({
    required String targetProjectPath,
    required String libraryName,
  }) async {
    try {
      // Remove all files related to the library
      final filesToRemove = [
        'ae_use/ae_install.md',
        'ae_use/ae_uninstall.md',
        'ae_use/ae_update.md',
        'ae_use/ae_use.md',
        'ae_use/${libraryName}_usage.mdc',
      ];

      for (final fileName in filesToRemove) {
        final filePath = '$targetProjectPath/$fileName';
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
        }
      }

      // Remove ae_use directory if empty
      final aeUseDir = Directory('$targetProjectPath/ae_use');
      if (await aeUseDir.exists()) {
        final contents = await aeUseDir.list().toList();
        if (contents.isEmpty) {
          await aeUseDir.delete();
        }
      }

      return AEOperationResult.success(
        'Deep clean completed for $libraryName',
        data: {
          'libraryName': libraryName,
          'targetProject': targetProjectPath,
          'removedFiles': filesToRemove,
        },
      );
    } catch (e) {
      return AEOperationResult.failure(
        'Deep clean failed: ${e.toString()}',
        errors: [e.toString()],
      );
    }
  }
}
