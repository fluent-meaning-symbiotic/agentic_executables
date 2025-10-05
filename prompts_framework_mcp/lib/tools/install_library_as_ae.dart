import 'dart:io';

import 'package:path/path.dart' as p;

class InstallAeResult {
  InstallAeResult({required this.installedFiles, required this.validation});
  final List<String> installedFiles;
  final ValidationReport validation;
}

class ValidationReport {
  ValidationReport({required this.passed, required this.messages});
  final bool passed;
  final List<String> messages;
}

Future<InstallAeResult> installLibraryAsAe({
  required String projectPath,
  String? aeSourceDir,
  String placement = 'ae_use',
  String? customPlacementDir,
  bool validate = true,
}) async {
  final sourceDir = Directory(aeSourceDir ?? p.join(projectPath, 'ae_use'));
  if (!sourceDir.existsSync()) {
    return InstallAeResult(
      installedFiles: const [],
      validation: ValidationReport(
        passed: false,
        messages: ['Source directory not found: ${sourceDir.path}'],
      ),
    );
  }

  final placementDir = Directory(
    placement == 'custom'
        ? (customPlacementDir ?? p.join(projectPath, 'ae_use'))
        : p.join(projectPath, placement),
  );
  if (!placementDir.existsSync()) {
    placementDir.createSync(recursive: true);
  }

  final installed = <String>[];
  for (final entity in sourceDir.listSync(recursive: false)) {
    if (entity is! File) continue;
    final basename = p.basename(entity.path);
    if (!basename.endsWith('.md') && !basename.endsWith('.mdc')) continue;
    final dest = File(p.join(placementDir.path, basename));
    dest.writeAsBytesSync(entity.readAsBytesSync());
    installed.add(p.normalize(dest.path));
  }

  // Write manifest
  final manifest = File(p.join(placementDir.path, '.ae_manifest.yaml'));
  if (!manifest.existsSync()) {
    manifest.writeAsStringSync(
      'installed:\n${installed.map((e) => '  - \"$e\"').join('\n')}\n',
    );
  }

  final messages = <String>[];
  var passed = true;
  if (validate) {
    for (final expected in ['ae_install.md', 'ae_uninstall.md']) {
      final f = File(p.join(placementDir.path, expected));
      if (!f.existsSync()) {
        passed = false;
        messages.add('Missing required file: ${f.path}');
      }
    }
  }

  return InstallAeResult(
    installedFiles: installed,
    validation: ValidationReport(passed: passed, messages: messages),
  );
}
