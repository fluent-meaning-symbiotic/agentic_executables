import '../resources/ae_documents.dart';

/// Tool for retrieving AE instructions based on context and action.
class GetAEInstructionsTool {
  final AEDocuments documents;

  GetAEInstructionsTool(this.documents);

  /// Gets the appropriate instruction documents based on context and action.
  Future<Map<String, dynamic>> execute(Map<String, dynamic> params) async {
    final contextType = params['context_type'] as String?;
    final action = params['action'] as String?;

    // Validate required parameters
    if (contextType == null || contextType.isEmpty) {
      return _errorResponse('Parameter "context_type" is required');
    }
    if (action == null || action.isEmpty) {
      return _errorResponse('Parameter "action" is required');
    }

    // Validate enum values
    if (!['library', 'project'].contains(contextType)) {
      return _errorResponse(
        'Invalid context_type. Must be "library" or "project"',
      );
    }
    if (!['bootstrap', 'install', 'uninstall', 'update', 'use']
        .contains(action)) {
      return _errorResponse(
        'Invalid action. Must be one of: bootstrap, install, uninstall, update, use',
      );
    }

    try {
      final filesToLoad = _determineFiles(contextType, action);
      final docs = await documents.getDocuments(filesToLoad);

      return {
        'success': true,
        'context_type': contextType,
        'action': action,
        'documents': docs,
        'message': 'Instructions retrieved successfully',
      };
    } catch (e) {
      return _errorResponse('Failed to load documents: ${e.toString()}');
    }
  }

  /// Determines which files to load based on context and action.
  List<String> _determineFiles(String contextType, String action) {
    final files = <String>['ae_context.md']; // Always include context

    if (contextType == 'library') {
      switch (action) {
        case 'bootstrap':
          files.addAll(['ae_bootstrap.md']);
          break;
        case 'update':
          files.addAll(['ae_bootstrap.md']); // Bootstrap contains update logic
          break;
        case 'install':
        case 'uninstall':
        case 'use':
          files.addAll(
              ['ae_bootstrap.md']); // Library maintainer needs bootstrap
          break;
      }
    } else {
      // project context
      switch (action) {
        case 'install':
          files.addAll(['ae_use.md']); // ae_install.md may not exist yet
          break;
        case 'uninstall':
          files.add('ae_use.md'); // References ae_uninstall.md
          break;
        case 'update':
          files.add('ae_use.md'); // References ae_update.md
          break;
        case 'use':
          files.add('ae_use.md');
          break;
        case 'bootstrap':
          files
              .add('ae_use.md'); // Project shouldn't bootstrap, but provide use
          break;
      }
    }

    return files;
  }

  Map<String, dynamic> _errorResponse(String message) {
    return {
      'success': false,
      'error': message,
    };
  }
}
