import 'package:agentic_executables_mcp/src/tools/manage_ae_registry.dart';
import 'package:agentic_executables_mcp/src/utils/github_raw_fetcher.dart';
import 'package:agentic_executables_mcp/src/utils/registry_resolver.dart';
import 'package:test/test.dart';

void main() {
  group('ManageAERegistryTool', () {
    late ManageAERegistryTool tool;

    setUp(() {
      tool = ManageAERegistryTool();
    });

    tearDown(() {
      tool.close();
    });

    group('submit_to_registry', () {
      test('validates required parameters', () async {
        final result = await tool.execute({
          'operation': 'submit_to_registry',
        });

        expect(result['success'], false);
        expect(result['error'], contains('library_url'));
      });

      test('validates library_id format', () async {
        final result = await tool.execute({
          'operation': 'submit_to_registry',
          'library_url': 'https://github.com/owner/repo',
          'library_id': 'invalidformat',
          'ae_use_files': 'ae_use/ae_install.md',
        });

        expect(result['success'], false);
        expect(result['error'], contains('Invalid library_id format'));
      });

      test('generates PR instructions for new library', () async {
        final result = await tool.execute({
          'operation': 'submit_to_registry',
          'library_url': 'https://github.com/xsoulspace/dart_lints',
          'library_id': 'dart_xsoulspace_lints',
          'ae_use_files': [
            'ae_use/ae_install.md',
            'ae_use/ae_uninstall.md',
            'ae_use/ae_update.md',
            'ae_use/ae_use.md',
          ],
        });

        expect(result['success'], true);
        expect(result['library_id'], 'dart_xsoulspace_lints');
        expect(
          result['registry_folder'],
          'ae_use_registry/dart_xsoulspace_lints',
        );
        expect(result['pr_instructions'], isNotEmpty);
        expect(result['files_to_copy'], hasLength(5)); // 4 ae files + README
        expect(result['status'], anyOf('new', 'update'));
      });

      test('handles comma-separated file list', () async {
        final result = await tool.execute({
          'operation': 'submit_to_registry',
          'library_url': 'https://github.com/owner/repo',
          'library_id': 'python_requests',
          'ae_use_files': 'ae_use/ae_install.md,ae_use/ae_uninstall.md',
        });

        expect(result['success'], true);
        expect(result['files_to_copy'], hasLength(3)); // 2 ae files + README
      });

      test('includes generated README in files_to_copy', () async {
        final result = await tool.execute({
          'operation': 'submit_to_registry',
          'library_url': 'https://github.com/owner/repo',
          'library_id': 'dart_provider',
          'ae_use_files': ['ae_use/ae_install.md'],
        });

        expect(result['success'], true);
        final files = result['files_to_copy'] as List;
        final readme = files.firstWhere(
          (final f) => f['target'].toString().endsWith('README.md'),
        );
        expect(readme['source'], 'generated');
        expect(readme['content'], isNotEmpty);
        expect(readme['content'], contains('dart_provider'));
      });
    });

    group('get_from_registry', () {
      test('validates required parameters', () async {
        final result = await tool.execute({
          'operation': 'get_from_registry',
        });

        expect(result['success'], false);
        expect(result['error'], contains('library_id'));
      });

      test('validates library_id format', () async {
        final result = await tool.execute({
          'operation': 'get_from_registry',
          'library_id': 'invalid',
          'action': 'install',
        });

        expect(result['success'], false);
        expect(result['error'], contains('Invalid library_id format'));
      });

      test('validates action parameter', () async {
        final result = await tool.execute({
          'operation': 'get_from_registry',
          'library_id': 'dart_provider',
          'action': 'invalid_action',
        });

        expect(result['success'], false);
        expect(result['error'], contains('Invalid action'));
      });

      test('checks if library exists before fetching', () async {
        final result = await tool.execute({
          'operation': 'get_from_registry',
          'library_id': 'nonexistent_library',
          'action': 'install',
        });

        expect(result['success'], false);
        expect(result['error'], contains('not found in registry'));
      });

      // Note: This test requires network access to the actual registry
      test(
        'fetches existing library from registry',
        () async {
          final result = await tool.execute({
            'operation': 'get_from_registry',
            'library_id': 'dart_xsoulspace_lints',
            'action': 'install',
          });

          // This will only pass if dart_xsoulspace_lints is actually in the registry
          if (result['success'] == true) {
            expect(result['library_id'], 'dart_xsoulspace_lints');
            expect(result['action'], 'install');
            expect(result['content'], isNotEmpty);
            expect(result['source_url'], contains('ae_install.md'));
          } else {
            // If not in registry yet, that's also valid
            expect(result['error'], contains('not found in registry'));
          }
        },
        skip: 'Requires network access and library to exist in registry',
      );
    });

    group('bootstrap_local_registry', () {
      test('validates required parameters', () async {
        final result = await tool.execute({
          'operation': 'bootstrap_local_registry',
        });

        expect(result['success'], false);
        expect(result['error'], contains('ae_use_path'));
      });

      test('generates bootstrap instructions', () async {
        final result = await tool.execute({
          'operation': 'bootstrap_local_registry',
          'ae_use_path': '/workspace/packages/my_lib/ae_use',
        });

        expect(result['success'], true);
        expect(result['ae_use_path'], '/workspace/packages/my_lib/ae_use');
        expect(result['instructions'], isNotEmpty);
        expect(result['instructions'], contains('ae_use_registry'));
        expect(result['suggested_library_id'], isNotEmpty);
      });

      test('suggests library_id from path', () async {
        final result = await tool.execute({
          'operation': 'bootstrap_local_registry',
          'ae_use_path': '/workspace/packages/cool_package/ae_use',
        });

        expect(result['success'], true);
        expect(result['suggested_library_id'], contains('cool_package'));
      });
    });

    group('invalid operation', () {
      test('returns error for unknown operation', () async {
        final result = await tool.execute({
          'operation': 'unknown_operation',
        });

        expect(result['success'], false);
        expect(result['error'], contains('Invalid operation'));
      });

      test('returns error for missing operation', () async {
        final result = await tool.execute({});

        expect(result['success'], false);
        expect(result['error'], contains('operation'));
      });
    });
  });

  group('GitHubRawFetcher', () {
    late GitHubRawFetcher fetcher;

    setUp(() {
      fetcher = GitHubRawFetcher();
    });

    tearDown(() {
      fetcher.close();
    });

    test('builds correct raw URL', () {
      final url = fetcher.buildRawUrl('owner', 'repo', 'path/file.md', 'main');
      expect(
        url,
        'https://raw.githubusercontent.com/owner/repo/main/path/file.md',
      );
    });

    test('handles leading slash in path', () {
      final url = fetcher.buildRawUrl('owner', 'repo', '/path/file.md', 'main');
      expect(
        url,
        'https://raw.githubusercontent.com/owner/repo/main/path/file.md',
      );
    });

    test(
      'fetches file from public repository',
      () async {
        // Test with a known public file
        try {
          final content = await fetcher.fetchFile(
            'xsoulspace',
            'agentic_executables',
            'README.md',
          );
          expect(content, isNotEmpty);
        } catch (e) {
          // If the file doesn't exist yet or network issue, skip
          // Skipping network test
        }
      },
      skip: 'Requires network access',
    );

    test(
      'tries master branch if main fails',
      () async {
        // This test verifies the fallback behavior
        // Most modern repos use 'main', but some still use 'master'
        try {
          await fetcher.fetchFile('owner', 'repo', 'nonexistent.md');
          fail('Should throw exception for nonexistent file');
        } catch (e) {
          expect(e.toString(), contains('File not found'));
          expect(e.toString(), contains('tried branches'));
        }
      },
      skip: 'Requires network access',
    );
  });

  group('RegistryResolver', () {
    late RegistryResolver resolver;
    late GitHubRawFetcher fetcher;

    setUp(() {
      fetcher = GitHubRawFetcher();
      resolver = RegistryResolver(fetcher);
    });

    tearDown(() {
      fetcher.close();
    });

    group('library ID validation', () {
      test('validates correct library IDs', () {
        expect(resolver.isValidLibraryId('dart_provider'), true);
        expect(resolver.isValidLibraryId('python_requests'), true);
        expect(resolver.isValidLibraryId('javascript_react'), true);
        expect(resolver.isValidLibraryId('dart_xsoulspace_lints'), true);
      });

      test('rejects invalid library IDs', () {
        expect(resolver.isValidLibraryId('invalid'), false);
        expect(resolver.isValidLibraryId('dart_'), false);
        expect(resolver.isValidLibraryId('_provider'), false);
        expect(resolver.isValidLibraryId('dart-provider'), false);
        expect(resolver.isValidLibraryId('DART_PROVIDER'), false);
      });
    });

    group('language and name extraction', () {
      test('extracts language from library ID', () {
        expect(resolver.extractLanguage('dart_provider'), 'dart');
        expect(resolver.extractLanguage('python_requests'), 'python');
        expect(resolver.extractLanguage('javascript_react'), 'javascript');
      });

      test('extracts library name from library ID', () {
        expect(resolver.extractLibraryName('dart_provider'), 'provider');
        expect(resolver.extractLibraryName('python_requests'), 'requests');
        expect(
          resolver.extractLibraryName('dart_xsoulspace_lints'),
          'xsoulspace_lints',
        );
      });

      test('returns null for invalid library IDs', () {
        expect(resolver.extractLanguage('invalid'), null);
        expect(resolver.extractLibraryName('invalid'), null);
      });
    });

    group('action to filename mapping', () {
      test('maps actions to correct filenames', () {
        expect(resolver.actionToFilename('install'), 'ae_install.md');
        expect(resolver.actionToFilename('uninstall'), 'ae_uninstall.md');
        expect(resolver.actionToFilename('update'), 'ae_update.md');
        expect(resolver.actionToFilename('use'), 'ae_use.md');
      });

      test('handles case insensitive actions', () {
        expect(resolver.actionToFilename('INSTALL'), 'ae_install.md');
        expect(resolver.actionToFilename('Install'), 'ae_install.md');
      });

      test('throws for invalid actions', () {
        expect(() => resolver.actionToFilename('invalid'), throwsArgumentError);
      });
    });

    group('registry path resolution', () {
      test('builds correct registry paths', () {
        expect(
          resolver.getRegistryPath('dart_provider', 'install'),
          'ae_use_registry/dart_provider/ae_install.md',
        );
        expect(
          resolver.getRegistryPath('python_requests', 'uninstall'),
          'ae_use_registry/python_requests/ae_uninstall.md',
        );
      });

      test('builds correct registry folder paths', () {
        expect(
          resolver.getRegistryFolder('dart_provider'),
          'ae_use_registry/dart_provider',
        );
      });

      test('throws for invalid library IDs', () {
        expect(
          () => resolver.getRegistryPath('invalid', 'install'),
          throwsArgumentError,
        );
        expect(
          () => resolver.getRegistryFolder('invalid'),
          throwsArgumentError,
        );
      });
    });

    group('action validation', () {
      test('validates correct actions', () {
        expect(resolver.isValidAction('install'), true);
        expect(resolver.isValidAction('uninstall'), true);
        expect(resolver.isValidAction('update'), true);
        expect(resolver.isValidAction('use'), true);
      });

      test('rejects invalid actions', () {
        expect(resolver.isValidAction('invalid'), false);
        expect(resolver.isValidAction('bootstrap'), false);
      });

      test('returns list of valid actions', () {
        final actions = resolver.getValidActions();
        expect(actions, hasLength(4));
        expect(actions, contains('install'));
        expect(actions, contains('uninstall'));
        expect(actions, contains('update'));
        expect(actions, contains('use'));
      });
    });

    group('library ID suggestion', () {
      test('suggests correct library IDs', () {
        expect(
          resolver.suggestLibraryId('dart', 'provider'),
          'dart_provider',
        );
        expect(
          resolver.suggestLibraryId('Python', 'requests'),
          'python_requests',
        );
      });

      test('normalizes language and library names', () {
        expect(
          resolver.suggestLibraryId('Dart', 'MyProvider'),
          'dart_myprovider',
        );
        expect(
          resolver.suggestLibraryId('JavaScript', 'react-native'),
          'javascript_react_native',
        );
      });
    });

    test('returns required files list', () {
      final files = resolver.getRequiredFiles();
      expect(files, hasLength(4));
      expect(files, contains('ae_install.md'));
      expect(files, contains('ae_uninstall.md'));
      expect(files, contains('ae_update.md'));
      expect(files, contains('ae_use.md'));
    });
  });
}
