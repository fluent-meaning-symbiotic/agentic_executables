import '../ae_framework_config.dart';
import '../resources/ae_documents.dart';

/// Tool for retrieving AE instructions based on context and action.
class GetAEInstructionsTool {
  GetAEInstructionsTool(this.documents);
  final AEDocuments documents;

  /// Gets the appropriate instruction documents based on context and action.
  Future<Map<String, dynamic>> execute(
      final Map<String, dynamic> params) async {
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
    if (!AEFrameworkConfig.isValidContext(contextType)) {
      return _errorResponse(AEFrameworkConfig.getInvalidContextError());
    }
    if (!AEFrameworkConfig.isValidAction(action)) {
      return _errorResponse(AEFrameworkConfig.getInvalidActionError());
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
      return _errorResponse('Failed to load documents: $e');
    }
  }

  /// Determines which files to load based on context and action.
  List<String> _determineFiles(final String contextType, final String action) {
    final files = <String>['ae_context.md']; // Always include context

    if (contextType == 'library') {
      switch (action) {
        case 'bootstrap':
          files.addAll(['ae_bootstrap.md']);
        case 'update':
          files.addAll(['ae_bootstrap.md']); // Bootstrap contains update logic
        case 'install':
        case 'uninstall':
        case 'use':
          files.addAll(
            ['ae_bootstrap.md'],
          ); // Library maintainer needs bootstrap
      }
    } else {
      // project context
      switch (action) {
        case 'install':
          files.addAll(['ae_use.md']); // ae_install.md may not exist yet
        case 'uninstall':
          files.add('ae_use.md'); // References ae_uninstall.md
        case 'update':
          files.add('ae_use.md'); // References ae_update.md
        case 'use':
          files.add('ae_use.md');
        case 'bootstrap':
          files
              .add('ae_use.md'); // Project shouldn't bootstrap, but provide use
      }
    }

    return files;
  }

  Map<String, dynamic> _errorResponse(final String message) => {
        'success': false,
        'error': message,
      };
}
