# AE Bootstrap Context

This document guides AI agents in analyzing, creating, and maintaining Agentic Executable (AE) files for a library. Refer to `ae_context.md` for common terms, principles, and working principles.

## Bootstrap Workflow

1. **Locate AE Files**: Search for existing AE files in the default path `root/ae_use` (e.g., `ae_install.md`, `ae_uninstall.md`, `ae_update.md`, `ae_use.md`).
2. **Analyze Codespace**: Review the current codebase, library architecture, dependencies, and structure to identify components and changes (aligning with `ae_context.md` definitions like Installation, Configuration, Integration).
3. **Conditional Action**:
   - **If AE Files Exist**: Compare with the current codespace to detect differences (e.g., new features, version updates). Update files to reflect changes, ensuring alignment with `ae_context.md` principles like Modularity, Reversibility, and Validation.
   - **If AE Files Do Not Exist**: Analyze the codespace to generate AE files from scratch, creating modular instructions for installation, uninstallation, updates, and usage.
4. **Generate/Update Content**:
   - **ae_install.md**: Create installation, configuration, and integration instructions. Analyze the library's documentation, codebase, and dependencies to identify abstract steps for setup. Include high-level patterns such as:
     - Identify and install required dependencies (e.g., packages, modules, or libraries).
     - Configure settings or environment variables based on library requirements.
     - Integrate library components into the project structure (e.g., initialize objects, set up entry points).
     - Bridge to application layers (e.g., connect to UI, services, or state management).
     - Implement cleanup or disposal mechanisms for resources.
   - **ae_uninstall.md**: Create uninstallation instructions. Infer reverse steps from `ae_install.md`, such as:
     - Identify and remove integrated components.
     - Clean up configurations, dependencies, and resources.
     - Reverse integrations (e.g., disconnect from UI or services).
     - Ensure full reversibility to restore the original state.
   - **ae_update.md**: Create update instructions for version transitions. Include abstract steps like:
     - Compare current and target library versions.
     - Backup existing configurations and data.
     - Apply migration or upgrade procedures (e.g., update dependencies, handle breaking changes).
     - Re-integrate updated components.
     - Validate post-update functionality and provide rollback options.
   - **Usage File (e.g., {library_name}\_usage.mdc)**: Create a usage rule adapted to the library name. Analyze the library's documentation for common use cases and anti-patterns. During generation:
     - Prompt the user for the target AI agent and placement path.
     - Include abstract patterns for:
       - Accessing and utilizing library features in the application.
       - Best practices and common pitfalls specific to the library.
     - Provide tailored examples for typical scenarios.
       Incorporate minimal, library-specific code snippets, maintenance notes, and ensure alignment with `ae_context.md` for clarity and agent-readability.
5. **Validate and Test**: Simulate agent execution to verify instructions, check for errors, and ensure seamless integration or removal.

## Agent Guidelines for Bootstrap

- **Analysis and Adaptation**: Follow the workflow sequentially; scan the codespace for context and adapt to library specifics while adhering to AE principles from `ae_context.md`.
- **Creation/Update**: Prioritize creating or updating files based on existence checks, focusing on modularity and reversibility.
- **Error Handling**: Resolve issues in analysis or file generation, suggesting modifications to align with project needs.
- **Optimization**: Keep instructions concise and efficient; cross-reference `ae_context.md` for terms and ensure files support workflows like those in `ae_use.md`.

This enables agents to autonomously analyze and maintain AE files, facilitating seamless library management.
