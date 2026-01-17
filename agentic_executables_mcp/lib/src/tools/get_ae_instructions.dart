import '../ae_framework_config.dart';
import '../ae_types.dart';
import '../resources/ae_documents.dart';

/// Tool for retrieving AE instructions based on context and action.
class GetAEInstructionsTool {
  GetAEInstructionsTool(this.documents);
  final AEDocuments documents;

  /// Gets the appropriate instruction documents based on context and action.
  Future<Map<String, dynamic>> execute(
      final Map<String, dynamic> params) async {
    final contextTypeStr = params['context_type'] as String?;
    final actionStr = params['action'] as String?;

    // Validate required parameters
    if (contextTypeStr == null || contextTypeStr.isEmpty) {
      return _errorResponse('Parameter "context_type" is required');
    }
    if (actionStr == null || actionStr.isEmpty) {
      return _errorResponse('Parameter "action" is required');
    }

    // Parse to type-safe enums with validation
    final AEContextType contextType;
    final AEAction action;

    try {
      contextType = AEContextType.fromString(contextTypeStr);
    } catch (e) {
      return _errorResponse(AEFrameworkConfig.getInvalidContextError());
    }

    try {
      action = AEAction.fromString(actionStr);
    } catch (e) {
      return _errorResponse(AEFrameworkConfig.getInvalidActionError());
    }

    try {
      // Create type-safe context-action pair (validates combination)
      final contextAction = AEContextAction(contextType, action);
      
      // Get document files for this context-action pair
      final filesToLoad = contextAction.getDocumentFiles();
      
      final docs = await documents.getDocuments(filesToLoad);

      return {
        'success': true,
        'context_type': contextType.value,
        'action': action.value,
        'documents': docs,
        'message': 'Instructions retrieved successfully',
      };
    } catch (e) {
      return _errorResponse('Failed to load documents: $e');
    }
  }

  Map<String, dynamic> _errorResponse(final String message) => {
        'success': false,
        'error': message,
      };
}
