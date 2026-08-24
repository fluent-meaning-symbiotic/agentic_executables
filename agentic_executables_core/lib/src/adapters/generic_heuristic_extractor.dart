import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../models/artifact_pack.dart';
import '../models/heuristic_artifact.dart';
import '../ports/heuristic_extractor.dart';

/// Language-agnostic fallback extractor.
///
/// Handles any directory that is not recognized by a language-specific
/// extractor: hashes all text source files it finds, builds an index.md
/// from the README excerpt and a structural summary (directory tree,
/// file counts by extension). This is what makes distillation
/// code-agnostic — the delegation path needs no language-specific parse;
/// the host agent reads whatever the structural summary points at.
class GenericHeuristicExtractor implements HeuristicExtractor {
  const GenericHeuristicExtractor();

  @override
  String get languageId => 'generic';

  static const _ignoredDirs = {
    '.git',
    '.dart_tool',
    '.build',
    'node_modules',
    'build',
    'dist',
    'target',
    'vendor',
    '.venv',
    '__pycache__',
  };

  /// Upper bound on hashed files so ingesting a huge monorepo stays cheap.
  static const _maxFiles = 500;

  static const _textExtensions = [
    '.dart',
    '.rs',
    '.kt',
    '.swift',
    '.go',
    '.py',
    '.js',
    '.ts',
    '.tsx',
    '.jsx',
    '.java',
    '.c',
    '.h',
    '.cc',
    '.cpp',
    '.hpp',
    '.cs',
    '.rb',
    '.php',
    '.zig',
    '.lua',
    '.ex',
    '.exs',
    '.clj',
    '.hs',
    '.ml',
    '.scala',
    '.sh',
    '.md',
    '.txt',
    '.toml',
    '.yaml',
    '.yml',
    '.json',
    '.xml',
    '.gradle',
  ];

  @override
  Future<bool> canHandle(final Directory sourceDir) async =>
      await sourceDir.exists();

  @override
  Future<HeuristicArtifact> extract(final Directory sourceDir) async {
    final name = p.basename(sourceDir.path);
    final files = await _collectFiles(sourceDir);

    final hashedFiles = <ArtifactSourceFile>[];
    final extCounts = <String, int>{};
    for (final file in files) {
      final relative =
          p.relative(file.path, from: sourceDir.path).replaceAll(r'\', '/');
      final bytes = await file.readAsBytes();
      hashedFiles.add(ArtifactSourceFile(
        path: relative,
        sha256: sha256.convert(bytes).toString(),
      ));
      final ext = p.extension(file.path).toLowerCase();
      extCounts[ext] = (extCounts[ext] ?? 0) + 1;
    }

    final readmeExcerpt = await _readReadmeExcerpt(sourceDir);
    final license = await _detectLicense(sourceDir);
    final indexMd = _buildIndexMd(
      name: name,
      readmeExcerpt: readmeExcerpt,
      fileCount: hashedFiles.length,
      truncated: files.length >= _maxFiles,
      extCounts: extCounts,
    );

    final meta = ArtifactMeta(
      kind: ArtifactKind.local,
      title: name,
      source: ArtifactSource(
        type: ArtifactSourceType.path,
        path: sourceDir.path,
        files: hashedFiles,
      ),
      scannedAt: DateTime.now().toUtc(),
      license: license,
      authors: const [],
      referencesCanonical: const [],
      extractor: 'generic_v1',
      distill: const ArtifactDistill(engine: 'heuristic'),
    );

    return HeuristicArtifact(
      name: name,
      languageId: languageId,
      meta: meta,
      indexMd: indexMd,
    );
  }

  Future<List<File>> _collectFiles(final Directory sourceDir) async {
    final files = <File>[];
    await for (final entity
        in sourceDir.list(recursive: true, followLinks: false)) {
      if (files.length >= _maxFiles) break;
      if (entity is! File) continue;
      if (!_isTextSource(entity)) continue;
      if (_pathHasIgnoredDir(entity.path, sourceDir.path)) continue;
      files.add(entity);
    }
    return files;
  }

  bool _isTextSource(final File entity) {
    final ext = p.extension(entity.path).toLowerCase();
    return _textExtensions.contains(ext);
  }

  bool _pathHasIgnoredDir(final String filePath, final String rootPath) {
    final relative = p.relative(filePath, from: rootPath);
    return relative.split(p.separator).any(_ignoredDirs.contains);
  }

  Future<String?> _readReadmeExcerpt(final Directory sourceDir) async {
    for (final candidate in const ['README.md', 'readme.md', 'README']) {
      final file = File(p.join(sourceDir.path, candidate));
      if (await file.exists()) {
        final raw = await file.readAsString();
        final excerpt = raw.length > 4000
            ? '${raw.substring(0, 4000)}\n\n... (truncated)'
            : raw;
        return excerpt;
      }
    }
    return null;
  }

  Future<ArtifactLicense?> _detectLicense(final Directory sourceDir) async {
    for (final candidate in const ['LICENSE', 'LICENSE.md', 'LICENCE']) {
      final file = File(p.join(sourceDir.path, candidate));
      if (await file.exists()) {
        final content = await file.readAsString();
        for (final entry in const [
          ('MIT', 'MIT'),
          ('Apache License', 'Apache-2.0'),
          ('BSD', 'BSD-3-Clause'),
          ('ISC', 'ISC'),
          ('Mozilla Public License', 'MPL-2.0'),
          ('GPL', 'GPL'),
        ]) {
          if (content.contains(entry.$1)) {
            return ArtifactLicense(spdx: entry.$2, detectedFrom: candidate);
          }
        }
        return ArtifactLicense(spdx: 'unknown', detectedFrom: candidate);
      }
    }
    return null;
  }

  String _buildIndexMd({
    required final String name,
    required final String? readmeExcerpt,
    required final int fileCount,
    required final bool truncated,
    required final Map<String, int> extCounts,
  }) {
    final buffer = StringBuffer()
      ..writeln('# $name')
      ..writeln()
      ..writeln('> Extracted with the generic (language-agnostic) extractor. '
          'No language-specific parse was available; the delegation task '
          'carries the file list and this summary for the host agent.')
      ..writeln()
      ..writeln('## Source summary')
      ..writeln()
      ..writeln('- Source files indexed: $fileCount'
          '${truncated ? ' (truncated at $_maxFiles)' : ''}');
    if (extCounts.isNotEmpty) {
      final sorted = extCounts.entries.toList()
        ..sort((final a, final b) => b.value.compareTo(a.value));
      buffer.write('- By extension: ');
      buffer
          .writeln(sorted.map((final e) => '${e.key} ×${e.value}').join(', '));
    }
    buffer.writeln();
    if (readmeExcerpt != null) {
      buffer
        ..writeln('## README excerpt')
        ..writeln()
        ..writeln(readmeExcerpt)
        ..writeln();
    } else {
      buffer
        ..writeln('## README')
        ..writeln()
        ..writeln('_No README found._')
        ..writeln();
    }
    return buffer.toString();
  }
}
