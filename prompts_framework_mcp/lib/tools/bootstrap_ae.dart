import 'dart:io';

import 'package:path/path.dart' as p;

class BootstrapAeResult {
  BootstrapAeResult({required this.createdFiles, required this.warnings});
  final List<String> createdFiles;
  final List<String> warnings;
}

Future<BootstrapAeResult> bootstrapAe({
  required String rootPath,
  required String libraryName,
  String outputDir = 'ae_use',
  bool overwrite = false,
}) async {
  final templatesDir = p.join(
    Directory.current.path,
    'prompts_framework_mcp',
    'templates',
  );
  final outDir = Directory(p.join(rootPath, outputDir));
  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }

  final templateFiles = <String>[
    'ae_install.md.hbs',
    'ae_uninstall.md.hbs',
    'ae_update.md.hbs',
    'library_usage.mdc.hbs',
    '.ae_manifest.yaml.hbs',
  ];

  final created = <String>[];
  final warnings = <String>[];

  for (final fileName in templateFiles) {
    final src = File(p.join(templatesDir, fileName));
    if (!src.existsSync()) {
      warnings.add('Missing template: $fileName');
      continue;
    }
    var content = await src.readAsString();
    content = content.replaceAll('{{library_name}}', libraryName);

    final targetName = fileName.replaceAll('.hbs', '');
    final dest = File(p.join(outDir.path, targetName));
    if (dest.existsSync() && !overwrite) {
      warnings.add('Exists, skipped: ${dest.path}');
      continue;
    }
    await dest.writeAsString(content);
    created.add(p.normalize(dest.path));
  }

  return BootstrapAeResult(createdFiles: created, warnings: warnings);
}
