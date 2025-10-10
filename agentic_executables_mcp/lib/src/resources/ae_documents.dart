import 'dart:io';

import 'package:path/path.dart' as path;

/// Manages loading and caching of Agentic Executable (AE) documentation files.
class AEDocuments {
  AEDocuments(this._resourcesPath);
  final Map<String, String> _cache = {};
  final String _resourcesPath;

  /// Loads document content from file, using cache if available.
  Future<String> getDocument(final String filename) async {
    if (_cache.containsKey(filename)) {
      return _cache[filename]!;
    }

    final filePath = path.join(_resourcesPath, filename);
    final file = File(filePath);

    if (!await file.exists()) {
      throw FileSystemException('Document not found: $filename', filePath);
    }

    final content = await file.readAsString();
    _cache[filename] = content;
    return content;
  }

  /// Gets multiple documents at once.
  Future<Map<String, String>> getDocuments(final List<String> filenames) async {
    final results = <String, String>{};
    for (final filename in filenames) {
      results[filename] = await getDocument(filename);
    }
    return results;
  }

  /// Clears the cache (useful for testing or memory management).
  void clearCache() {
    _cache.clear();
  }

  /// Checks if a document exists.
  Future<bool> documentExists(final String filename) async {
    final filePath = path.join(_resourcesPath, filename);
    return File(filePath).exists();
  }
}
