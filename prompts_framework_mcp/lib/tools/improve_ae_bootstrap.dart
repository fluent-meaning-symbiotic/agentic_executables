import 'dart:io';

import 'package:path/path.dart' as p;

class ImproveAeResult {
  ImproveAeResult({required this.updatedFiles, required this.diffPreview});
  final List<String> updatedFiles;
  final String diffPreview;
}

Future<ImproveAeResult> improveAeBootstrap({
  required String rootPath,
  List<String>? targets,
  String? styleGuidelines,
  bool useClientSampling = true,
}) async {
  final paths =
      targets?.toList() ??
      <String>[
        p.join(rootPath, 'ae_use', 'ae_install.md'),
        p.join(rootPath, 'ae_use', 'ae_uninstall.md'),
        p.join(rootPath, 'ae_use', 'ae_update.md'),
      ];

  final updated = <String>[];
  final diffBuf = StringBuffer();
  for (final path in paths) {
    final f = File(path);
    if (!f.existsSync()) continue;
    final original = await f.readAsString();
    final improved = _polish(original, styleGuidelines: styleGuidelines);
    if (improved != original) {
      await f.writeAsString(improved);
      updated.add(p.normalize(path));
      diffBuf.writeln('--- ${p.normalize(path)}');
      diffBuf.writeln('+++ ${p.normalize(path)}');
      diffBuf.writeln('@@ -1 +1 @@');
      diffBuf.writeln('...');
    }
  }

  return ImproveAeResult(
    updatedFiles: updated,
    diffPreview: diffBuf.toString(),
  );
}

String _polish(String content, {String? styleGuidelines}) {
  var c = content;
  // Normalize headings capitalization and spacing
  c = c.replaceAll('# ae ', '# AE ');
  // Ensure trailing newline
  if (!c.endsWith('\n')) c = '$c\n';
  // Apply simple guideline hint
  if (styleGuidelines != null && styleGuidelines.isNotEmpty) {
    c = '<!-- style: ${styleGuidelines} -->\n$c';
  }
  return c;
}
