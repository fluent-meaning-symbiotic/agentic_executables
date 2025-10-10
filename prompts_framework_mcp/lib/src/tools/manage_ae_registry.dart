import '../ae_framework_config.dart';
import '../utils/github_raw_fetcher.dart';
import '../utils/registry_resolver.dart';

/// Tool for managing the AE registry - submit libraries and fetch library files.
class ManageAERegistryTool {
  ManageAERegistryTool()
      : _fetcher = GitHubRawFetcher(),
        _resolver = RegistryResolver(GitHubRawFetcher());
  final GitHubRawFetcher _fetcher;
  final RegistryResolver _resolver;

  /// Executes the tool based on the operation type.
  Future<Map<String, dynamic>> execute(
      final Map<String, dynamic> params) async {
    final operation = params['operation'] as String?;

    if (operation == null || operation.isEmpty) {
      return _errorResponse('Parameter "operation" is required');
    }

    if (!AEFrameworkConfig.isValidRegistryOperation(operation)) {
      return _errorResponse(
        AEFrameworkConfig.getInvalidRegistryOperationError(),
      );
    }

    switch (operation) {
      case 'submit_to_registry':
        return _handleSubmit(params);
      case 'get_from_registry':
        return _handleGet(params);
      case 'bootstrap_local_registry':
        return _handleBootstrapLocal(params);
      default:
        return _errorResponse(
          AEFrameworkConfig.getInvalidRegistryOperationError(),
        );
    }
  }

  /// Handles submit_to_registry operation for library authors.
  ///
  /// Generates PR instructions and file mappings for submitting a library
  /// to the registry.
  Future<Map<String, dynamic>> _handleSubmit(
    final Map<String, dynamic> params,
  ) async {
    final libraryUrl = params['library_url'] as String?;
    final libraryId = params['library_id'] as String?;
    final aeUseFiles = params['ae_use_files'];

    // Validate required parameters
    if (libraryUrl == null || libraryUrl.isEmpty) {
      return _errorResponse('Parameter "library_url" is required');
    }
    if (libraryId == null || libraryId.isEmpty) {
      return _errorResponse('Parameter "library_id" is required');
    }
    if (aeUseFiles == null) {
      return _errorResponse('Parameter "ae_use_files" is required');
    }

    // Validate library ID format
    if (!_resolver.isValidLibraryId(libraryId)) {
      return _errorResponse(
        AEFrameworkConfig.getInvalidLibraryIdError(libraryId),
      );
    }

    // Parse ae_use_files (could be List or JSON string)
    List<String> filesList;
    if (aeUseFiles is String) {
      try {
        final parsed =
            aeUseFiles.split(',').map((final e) => e.trim()).toList();
        filesList = parsed;
      } catch (e) {
        return _errorResponse('Invalid ae_use_files format: $e');
      }
    } else if (aeUseFiles is List) {
      filesList = aeUseFiles.map((final e) => e.toString()).toList();
    } else {
      return _errorResponse(
        'ae_use_files must be a list or comma-separated string',
      );
    }

    // Check if library already exists in registry
    bool libraryExists;
    try {
      libraryExists = await _resolver.libraryExistsInRegistry(libraryId);
    } catch (e) {
      libraryExists = false; // Assume doesn't exist if check fails
    }

    final status = libraryExists ? 'update' : 'new';
    final registryFolder = _resolver.getRegistryFolder(libraryId);

    // Build files_to_copy list
    final filesToCopy = <Map<String, String>>[];
    for (final sourceFile in filesList) {
      final fileName = sourceFile.split('/').last;
      filesToCopy.add({
        'source': sourceFile,
        'target': '$registryFolder/$fileName',
      });
    }

    // Add generated README.md
    final readmeContent = _generateReadmeContent(libraryUrl, libraryId);
    filesToCopy.add({
      'source': 'generated',
      'target': '$registryFolder/README.md',
      'content': readmeContent,
    });

    // Generate PR instructions
    final prInstructions = _generatePRInstructions(
      libraryId: libraryId,
      libraryUrl: libraryUrl,
      registryFolder: registryFolder,
      status: status,
    );

    return {
      'success': true,
      'library_id': libraryId,
      'registry_folder': registryFolder,
      'registry_repo_url': AEFrameworkConfig.getRegistryUrl(),
      'pr_instructions': prInstructions,
      'files_to_copy': filesToCopy,
      'status': status,
      'message': status == 'new'
          ? 'Library ready for registration'
          : 'Library exists - ready for update',
    };
  }

  /// Handles get_from_registry operation for developers.
  ///
  /// Fetches AE files directly from the registry and returns content.
  Future<Map<String, dynamic>> _handleGet(
      final Map<String, dynamic> params) async {
    final libraryId = params['library_id'] as String?;
    final action = params['action'] as String?;

    // Validate required parameters
    if (libraryId == null || libraryId.isEmpty) {
      return _errorResponse('Parameter "library_id" is required');
    }
    if (action == null || action.isEmpty) {
      return _errorResponse('Parameter "action" is required');
    }

    // Validate library ID format
    if (!_resolver.isValidLibraryId(libraryId)) {
      return _errorResponse(
        AEFrameworkConfig.getInvalidLibraryIdError(libraryId),
      );
    }

    // Validate action
    if (!_resolver.isValidAction(action)) {
      return _errorResponse(
        AEFrameworkConfig.getInvalidRegistryActionError(),
      );
    }

    // Check if library exists
    final exists = await _resolver.libraryExistsInRegistry(libraryId);
    if (!exists) {
      return _errorResponse(
        'Library "$libraryId" not found in registry. '
        'Please ask the library author to submit it to the registry.',
      );
    }

    // Fetch the file
    try {
      final content = await _resolver.fetchRegistryFile(libraryId, action);
      final sourceUrl = _resolver.buildRegistryUrl(libraryId, action);

      return {
        'success': true,
        'library_id': libraryId,
        'action': action,
        'content': content,
        'source_url': sourceUrl,
        'message': 'File retrieved successfully from registry',
      };
    } catch (e) {
      return _errorResponse(
        'Failed to fetch ${_resolver.actionToFilename(action)} for $libraryId: $e',
      );
    }
  }

  /// Handles bootstrap_local_registry operation for monorepos.
  ///
  /// Provides instructions for setting up a local registry structure.
  Future<Map<String, dynamic>> _handleBootstrapLocal(
    final Map<String, dynamic> params,
  ) async {
    final aeUsePath = params['ae_use_path'] as String?;

    if (aeUsePath == null || aeUsePath.isEmpty) {
      return _errorResponse('Parameter "ae_use_path" is required');
    }

    // Extract library name from path if possible
    final pathSegments = aeUsePath.split('/');
    String suggestedName = 'my_library';

    // Try to find a meaningful name from path
    if (pathSegments.length >= 2) {
      final possibleName = pathSegments[pathSegments.length - 2];
      if (possibleName.isNotEmpty && possibleName != 'ae_use') {
        suggestedName = possibleName;
      }
    }

    final instructions = '''
# Bootstrap Local Registry

To set up a local registry structure for your monorepo:

## 1. Create Registry Folder Structure

In your monorepo root, create:
```
ae_use_registry/
├── README.md
└── <language>_<library_name>/
    ├── README.md
    ├── ae_install.md
    ├── ae_uninstall.md
    ├── ae_update.md
    └── ae_use.md
```

## 2. Copy AE Use Files

Copy files from: $aeUsePath
To: ae_use_registry/<language>_<library_name>/

## 3. Create Library README

In ae_use_registry/<language>_<library_name>/README.md, include:
- Library name and description
- Repository URL (for monorepo, use main repo URL)
- Authors/maintainers
- License

## 4. Configure MCP Tool

Update the MCP tool configuration to point to your local registry:
- Set registryOwner to your organization
- Set registryRepo to your monorepo name
- Set registryBranch to your default branch

## 5. Test Access

Use the get_from_registry operation to verify files are accessible.

## Notes

- For monorepos, multiple libraries can share the same registry
- Use consistent naming: <language>_<library_name>
- Keep registry structure flat (one level under ae_use_registry)
- Document dependencies between libraries in each README
''';

    return {
      'success': true,
      'ae_use_path': aeUsePath,
      'instructions': instructions,
      'suggested_library_id': 'dart_$suggestedName',
      'message': 'Local registry bootstrap instructions generated',
    };
  }

  /// Generates README.md content for a library entry.
  String _generateReadmeContent(
      final String libraryUrl, final String libraryId) {
    final language = _resolver.extractLanguage(libraryId);
    final libraryName = _resolver.extractLibraryName(libraryId);

    return '''# $libraryId

**Repository:** $libraryUrl  
**Authors:** [To be extracted from repository]  
**License:** [To be extracted from repository]

## Description

$language library: $libraryName

## Related Links

- [Repository]($libraryUrl)
- [Issue Tracker]($libraryUrl/issues)

---

*This README was automatically generated. Please update with accurate information.*
''';
  }

  /// Generates PR submission instructions.
  String _generatePRInstructions({
    required final String libraryId,
    required final String libraryUrl,
    required final String registryFolder,
    required final String status,
  }) {
    final action = status == 'new' ? 'Add' : 'Update';

    return '''
# $action $libraryId to AE Registry

## Steps to Submit Pull Request

### 1. Fork and Clone Registry Repository

If not already cloned:
```bash
# Clone the registry repository
git clone https://github.com/${_resolver.registryOwner}/${_resolver.registryRepo}.git
cd ${_resolver.registryRepo}

# Or if already cloned, ensure it's up to date
git checkout ${_resolver.registryBranch}
git pull origin ${_resolver.registryBranch}
```

### 2. Create Feature Branch

```bash
git checkout -b $action-$libraryId
```

### 3. Create Registry Folder

```bash
mkdir -p $registryFolder
```

### 4. Copy AE Use Files

Copy the files as specified in the files_to_copy list from your library to the registry folder.

For generated files (like README.md), use the content provided in the 'content' field.

### 5. Update Main Registry README (if new library)

${status == 'new' ? 'Add your library to the examples in ae_use_registry/README.md' : 'No changes needed to main README for updates'}

### 6. Commit Changes

```bash
git add $registryFolder
git commit -m "$action $libraryId AE files

Source: $libraryUrl
Status: $status
"
```

### 7. Push to Your Fork

```bash
git push origin $action-$libraryId
```

### 8. Create Pull Request

1. Go to https://github.com/${_resolver.registryOwner}/${_resolver.registryRepo}
2. Click "New Pull Request"
3. Select your branch: $action-$libraryId
4. Title: "$action $libraryId to AE Registry"
5. Description:
   - Library: $libraryId
   - Source: $libraryUrl
   - Action: $status
   - Files included: ae_install.md, ae_uninstall.md, ae_update.md, ae_use.md, README.md
6. Submit PR

## Validation Before Submitting

- [ ] All required files present (ae_install.md, ae_uninstall.md, ae_update.md, ae_use.md, README.md)
- [ ] README.md contains: repository URL, authors, license
- [ ] Each AE file follows framework principles
- [ ] Library ID follows naming convention: <language>_<library_name>
- [ ] Files are concise (prefer < 500 LOC per file)
- [ ] Validation steps included in ae_install.md

## After PR is Merged

Users can access your library with:
```
Operation: get_from_registry
Library ID: $libraryId
Action: install|uninstall|update|use
```
''';
  }

  /// Creates an error response.
  Map<String, dynamic> _errorResponse(final String message) => {
        'success': false,
        'error': message,
      };

  /// Closes resources.
  void close() {
    _fetcher.close();
  }
}
