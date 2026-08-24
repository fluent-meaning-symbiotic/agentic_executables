import 'dart:io';

import '../ports/process_runner.dart';
import 'process_runner_io.dart';

/// Shallow-clones a public git repository into a temporary directory.
///
/// Used by `ae canonical distill --repo <url>` to make any public
/// repository eligible as a distillation source without a language-
/// specific extractor: the clone is ingested via the generic extractor
/// and distilled through the normal delegation path.
class RepoCloner {
  const RepoCloner({ProcessRunner? processRunner})
      : _processRunner = processRunner ?? const ProcessRunnerIo();

  final ProcessRunner _processRunner;

  /// Clone [url] (depth 1) and return the temp directory. Caller owns
  /// cleanup via [cleanup].
  Future<Directory> clone(final String url) async {
    final tempDir = await Directory.systemTemp.createTemp('ae_repo_');
    final result = await _processRunner.run(
      executable: 'git',
      arguments: [
        'clone',
        '--depth',
        '1',
        '--single-branch',
        url,
        tempDir.path,
      ],
      timeout: const Duration(minutes: 5),
    );
    if (result.exitCode != 0) {
      await tempDir.delete(recursive: true).catchError((_) => tempDir);
      throw ProcessException(
        'git',
        ['clone', '--depth', '1', url],
        'Git clone failed for $url: ${result.stderr.trim()}',
        result.exitCode,
      );
    }
    return tempDir;
  }

  Future<void> cleanup(final Directory dir) =>
      dir.delete(recursive: true).catchError((_) => dir);
}
