import 'dart:convert';
import 'dart:io';

import '../ae_framework_config.dart';

/// Fetches files from GitHub repositories using raw.githubusercontent.com
/// without requiring authentication (public repos only).
class GitHubRawFetcher {
  final HttpClient _httpClient;

  GitHubRawFetcher() : _httpClient = HttpClient();

  /// Fetches a single file from a GitHub repository.
  ///
  /// [owner] - Repository owner (username or organization)
  /// [repo] - Repository name
  /// [path] - File path within the repository
  /// [branch] - Branch name (defaults to 'main')
  ///
  /// Returns the file content as a string.
  /// Throws [HttpException] if file not found or network error.
  Future<String> fetchFile(
    String owner,
    String repo,
    String path, {
    String? branch,
  }) async {
    branch ??= AEFrameworkConfig.defaultBranch;
    final url = buildRawUrl(owner, repo, path, branch);

    try {
      final uri = Uri.parse(url);
      final request = await _httpClient.getUrl(uri);
      final response = await request.close();

      if (response.statusCode == 200) {
        final content = await response.transform(utf8.decoder).join();
        return content;
      } else if (response.statusCode == 404) {
        // Try 'master' branch if 'main' fails
        if (branch == AEFrameworkConfig.defaultBranch) {
          return fetchFile(owner, repo, path, branch: 'master');
        }
        throw HttpException(
          'File not found: $path (tried branches: main, master)',
          uri: uri,
        );
      } else {
        throw HttpException(
          'Failed to fetch file: HTTP ${response.statusCode}',
          uri: uri,
        );
      }
    } catch (e) {
      if (e is HttpException) rethrow;
      throw HttpException('Network error: ${e.toString()}');
    }
  }

  /// Fetches multiple AE use files from a repository.
  ///
  /// [repoUrl] - Full GitHub repository URL (e.g., https://github.com/owner/repo)
  /// [aePath] - Path to ae_use folder (defaults to '/ae_use')
  ///
  /// Returns a map of filename to content for all found files.
  /// Only returns files that exist (doesn't error on missing files).
  Future<Map<String, String>> fetchAEUseFiles(
    String repoUrl, {
    String aePath = '/ae_use',
  }) async {
    final repoInfo = _parseGitHubUrl(repoUrl);
    final files = <String, String>{};
    final fileNames = AEFrameworkConfig.getRequiredAEFiles();

    // Normalize path (remove leading/trailing slashes)
    final normalizedPath = aePath.replaceAll(RegExp(r'^/+|/+$'), '');

    for (final fileName in fileNames) {
      try {
        final filePath =
            normalizedPath.isEmpty ? fileName : '$normalizedPath/$fileName';
        final content = await fetchFile(
          repoInfo['owner']!,
          repoInfo['repo']!,
          filePath,
          branch: repoInfo['branch'],
        );
        files[fileName] = content;
      } catch (e) {
        // Skip missing files, continue with others
        continue;
      }
    }

    return files;
  }

  /// Builds a raw GitHub URL for file access.
  ///
  /// [owner] - Repository owner
  /// [repo] - Repository name
  /// [path] - File path (should not start with /)
  /// [branch] - Branch name
  ///
  /// Returns the complete raw.githubusercontent.com URL.
  String buildRawUrl(String owner, String repo, String path, String branch) {
    return AEFrameworkConfig.buildGitHubRawUrl(owner, repo, path, branch);
  }

  /// Checks if a library exists in the registry by attempting to fetch its README.
  ///
  /// [libraryId] - Library identifier (e.g., 'dart_provider')
  /// [registryOwner] - Registry repository owner
  /// [registryRepo] - Registry repository name
  ///
  /// Returns true if the library folder exists in the registry.
  Future<bool> libraryExistsInRegistry(
    String libraryId, {
    String? registryOwner,
    String? registryRepo,
    String? branch,
  }) async {
    try {
      await fetchFile(
        registryOwner ?? AEFrameworkConfig.registryOwner,
        registryRepo ?? AEFrameworkConfig.registryRepo,
        '${AEFrameworkConfig.registryBasePath}/$libraryId/README.md',
        branch: branch,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Parses a GitHub URL to extract owner, repo, and optional branch.
  ///
  /// Supports formats:
  /// - https://github.com/owner/repo
  /// - https://github.com/owner/repo/tree/branch
  /// - https://github.com/owner/repo/blob/branch/path
  ///
  /// Returns a map with 'owner', 'repo', and optional 'branch'.
  Map<String, String> _parseGitHubUrl(String url) {
    final uri = Uri.parse(url);

    if (uri.host != 'github.com') {
      throw ArgumentError('Not a valid GitHub URL: $url');
    }

    final pathSegments = uri.pathSegments;
    if (pathSegments.length < 2) {
      throw ArgumentError('Invalid GitHub URL format: $url');
    }

    final owner = pathSegments[0];
    final repo = pathSegments[1].replaceAll('.git', '');
    String? branch;

    // Check if URL contains branch info
    if (pathSegments.length >= 4 &&
        (pathSegments[2] == 'tree' || pathSegments[2] == 'blob')) {
      branch = pathSegments[3];
    }

    return {
      'owner': owner,
      'repo': repo,
      if (branch != null) 'branch': branch,
    };
  }

  /// Closes the HTTP client and releases resources.
  void close() {
    _httpClient.close();
  }
}
