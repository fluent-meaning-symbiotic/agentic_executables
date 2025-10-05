/// File operations utilities for AE framework
library file_operations;

import 'dart:io';

import 'package:path/path.dart' as path;

/// Utility class for file and directory operations
class FileOperations {
  /// Check if AE files exist in the specified directory
  static Future<bool> aeFilesExist(String directoryPath) async {
    final aeFiles = [
      'ae_install.md',
      'ae_uninstall.md',
      'ae_update.md',
      'ae_use.md',
    ];

    for (final file in aeFiles) {
      final filePath = path.join(directoryPath, 'ae_use', file);
      if (!await File(filePath).exists()) {
        return false;
      }
    }
    return true;
  }

  /// Get list of existing AE files in directory
  static Future<List<String>> getExistingAEFiles(String directoryPath) async {
    final aeFiles = [
      'ae_install.md',
      'ae_uninstall.md',
      'ae_update.md',
      'ae_use.md',
    ];
    final existingFiles = <String>[];

    for (final file in aeFiles) {
      final filePath = path.join(directoryPath, 'ae_use', file);
      if (await File(filePath).exists()) {
        existingFiles.add(file);
      }
    }
    return existingFiles;
  }

  /// Create AE directory structure
  static Future<void> createAEDirectory(String directoryPath) async {
    final aeDir = Directory(path.join(directoryPath, 'ae_use'));
    if (!await aeDir.exists()) {
      await aeDir.create(recursive: true);
    }
  }

  /// Write AE file content
  static Future<void> writeAEFile(
    String directoryPath,
    String fileName,
    String content,
  ) async {
    await createAEDirectory(directoryPath);
    final filePath = path.join(directoryPath, 'ae_use', fileName);
    final file = File(filePath);
    await file.writeAsString(content);
  }

  /// Read AE file content
  static Future<String?> readAEFile(
    String directoryPath,
    String fileName,
  ) async {
    final filePath = path.join(directoryPath, 'ae_use', fileName);
    final file = File(filePath);

    if (await file.exists()) {
      return await file.readAsString();
    }
    return null;
  }

  /// Delete AE file
  static Future<void> deleteAEFile(
    String directoryPath,
    String fileName,
  ) async {
    final filePath = path.join(directoryPath, 'ae_use', fileName);
    final file = File(filePath);

    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Copy AE files from source to destination
  static Future<void> copyAEFiles(
    String sourcePath,
    String destinationPath,
  ) async {
    final aeFiles = [
      'ae_install.md',
      'ae_uninstall.md',
      'ae_update.md',
      'ae_use.md',
    ];

    for (final file in aeFiles) {
      final sourceFile = File(path.join(sourcePath, 'ae_use', file));
      if (await sourceFile.exists()) {
        await createAEDirectory(destinationPath);
        final destFile = File(path.join(destinationPath, 'ae_use', file));
        await sourceFile.copy(destFile.path);
      }
    }
  }

  /// Get library information from pubspec.yaml
  static Future<Map<String, dynamic>?> getLibraryInfo(
    String libraryPath,
  ) async {
    final pubspecFile = File(path.join(libraryPath, 'pubspec.yaml'));

    if (!await pubspecFile.exists()) {
      return null;
    }

    try {
      final content = await pubspecFile.readAsString();
      // Simple YAML parsing for basic info
      final lines = content.split('\n');
      final info = <String, dynamic>{};

      for (final line in lines) {
        if (line.startsWith('name:')) {
          info['name'] = line.split(':')[1].trim();
        } else if (line.startsWith('version:')) {
          info['version'] = line.split(':')[1].trim();
        } else if (line.startsWith('description:')) {
          info['description'] = line.split(':')[1].trim();
        }
      }

      return info;
    } catch (e) {
      return null;
    }
  }

  /// Check if directory contains a Dart/Flutter project
  static Future<bool> isDartProject(String directoryPath) async {
    final pubspecFile = File(path.join(directoryPath, 'pubspec.yaml'));
    return await pubspecFile.exists();
  }

  /// Get project dependencies from pubspec.yaml
  static Future<List<String>> getProjectDependencies(String projectPath) async {
    final pubspecFile = File(path.join(projectPath, 'pubspec.yaml'));

    if (!await pubspecFile.exists()) {
      return [];
    }

    try {
      final content = await pubspecFile.readAsString();
      final lines = content.split('\n');
      final dependencies = <String>[];
      bool inDependencies = false;

      for (final line in lines) {
        if (line.trim() == 'dependencies:') {
          inDependencies = true;
          continue;
        }

        if (inDependencies) {
          if (line.trim().isEmpty || !line.startsWith('  ')) {
            break;
          }

          final dep = line.trim().split(':')[0];
          if (dep.isNotEmpty) {
            dependencies.add(dep);
          }
        }
      }

      return dependencies;
    } catch (e) {
      return [];
    }
  }
}
