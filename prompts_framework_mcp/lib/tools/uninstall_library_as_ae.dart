import 'dart:io';

import 'package:path/path.dart' as p;

class UninstallAeResult {
  UninstallAeResult({required this.removedFiles, required this.leftovers});
  final List<String> removedFiles;
  final List<String> leftovers;
}

Future<UninstallAeResult> uninstallLibraryAsAe({
  required String projectPath,
  String placement = 'ae_use',
  String? customPlacementDir,
  bool dryRun = false,
}) async {
  final placementDir = Directory(
    placement == 'custom'
        ? (customPlacementDir ?? p.join(projectPath, 'ae_use'))
        : p.join(projectPath, placement),
  );

  final removed = <String>[];
  final leftovers = <String>[];
  if (!placementDir.existsSync()) {
    return UninstallAeResult(removedFiles: removed, leftovers: leftovers);
  }

  final manifest = File(p.join(placementDir.path, '.ae_manifest.yaml'));
  List<String> targets = <String>[];
  if (manifest.existsSync()) {
    final lines = manifest.readAsLinesSync();
    for (final line in lines) {
      final t = line.trim();
      if (t.startsWith('-')) {
        final pathStr = t.substring(1).trim().replaceAll('"', '');
        if (pathStr.isNotEmpty) targets.add(pathStr);
      }
    }
  } else {
    for (final f in ['ae_install.md', 'ae_uninstall.md', 'ae_update.md']) {
      targets.add(p.join(placementDir.path, f));
    }
  }

  for (final t in targets) {
    final f = File(t);
    if (f.existsSync()) {
      if (!dryRun) f.deleteSync();
      removed.add(p.normalize(t));
    } else {
      leftovers.add('Missing at uninstall: ${p.normalize(t)}');
    }
  }

  if (manifest.existsSync() && !dryRun) {
    manifest.deleteSync();
  }

  return UninstallAeResult(removedFiles: removed, leftovers: leftovers);
}
