/// Tool for retrieving the core Agentic Executable definition.
class GetAgenticExecutableDefinitionTool {
  /// Returns the core AE definition and framework overview.
  Map<String, dynamic> execute(final Map<String, dynamic> params) => {
        'success': true,
        'definition': {
          'name': 'Agentic Executables (AE)',
          'description':
              'Libraries/packages managed by AI agents as executable programs for installation, configuration, usage, and uninstallation.',
        },
        'contexts': {
          'library': {
            'description': 'Maintain AE files within the library itself',
            'use_case': 'For library maintainers creating AE documentation',
          },
          'project': {
            'description': 'Use AE in projects that depend on the library',
            'use_case': 'For developers integrating libraries as AE',
          },
        },
        'actions': [
          {
            'name': 'bootstrap',
            'description': 'Create/maintain AE files in a library',
            'applicable_contexts': ['library'],
          },
          {
            'name': 'install',
            'description': 'Add AE to a project',
            'applicable_contexts': ['library', 'project'],
          },
          {
            'name': 'uninstall',
            'description': 'Remove AE from a project',
            'applicable_contexts': ['library', 'project'],
          },
          {
            'name': 'update',
            'description': 'Update AE to a newer version',
            'applicable_contexts': ['library', 'project'],
          },
          {
            'name': 'use',
            'description': 'Apply AE capabilities in the project',
            'applicable_contexts': ['library', 'project'],
          },
        ],
        'tools': [
          {
            'name': 'get_ae_instructions',
            'description':
                'Retrieve contextual documentation for context+action combination',
            'use_case':
                'Get detailed instructions for a specific context and action',
          },
          {
            'name': 'verify_ae_implementation',
            'description':
                'Generate verification checklist based on AE principles',
            'use_case': 'Verify implementation quality after making changes',
          },
          {
            'name': 'evaluate_ae_compliance',
            'description':
                'Score implementation compliance with detailed feedback',
            'use_case':
                'Get quantitative scoring and recommendations for improvements',
          },
          {
            'name': 'get_agentic_executable_definition',
            'description': 'Retrieve core AE definition and framework overview',
            'use_case':
                'Understand what AE is and which tools are available (this tool)',
          },
        ],
        'usage_guide': {
          'library_maintainers':
              'Call get_ae_instructions(context="library", action="bootstrap"|"update") to create/maintain AE files.',
          'project_developers':
              'Call get_ae_instructions(context="project", action="install"|"uninstall"|"update"|"use") to integrate libraries as AE.',
          'workflow':
              'After implementation: Call verify_ae_implementation for checklist, then evaluate_ae_compliance for scoring.',
        },
        'core_principles': [
          {
            'name': 'Agent Empowerment',
            'description':
                'Equip AI agents with meta-rules to autonomously maintain, install, configure, integrate, use, and uninstall AEs based on project needs.',
          },
          {
            'name': 'Modularity',
            'description':
                'Structure AE instructions in clear, reusable steps: Installation → Configuration → Integration → Usage → Uninstallation.',
          },
          {
            'name': 'Contextual Awareness',
            'description':
                'Ensure AE documentation provides sufficient domain knowledge for agents to understand integration points without manual intervention.',
          },
          {
            'name': 'Reversibility',
            'description':
                'Design uninstallation to cleanly remove all traces of the AE, restoring the original state.',
          },
          {
            'name': 'Validation',
            'description':
                'Include checks for installation, configuration, and usage to ensure reliability and allow for corrections.',
          },
          {
            'name': 'Documentation Focus',
            'description':
                'Prioritize concise, agent-readable instructions over verbose human-oriented docs.',
          },
        ],
        'message':
            'This server provides strategic guidance; full documentation comes from tool responses.',
      };
}
