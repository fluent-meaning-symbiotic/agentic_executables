<!--
version: 1.1.0
repository: https://github.com/fluent-meaning-symbiotic/agentic_executables
registry: https://github.com/fluent-meaning-symbiotic/agentic_executables_registry
license: MIT
author: Arenukvern and contributors
-->

# AE Use Context

This document outlines how AI agents can use an Agentic Executable (AE) for libraries. Refer to `ae_context.md` for common terms, principles, and working principles.

## Workflow

1. **Receive Context**: Agents receive this file (`ae_use.md`) and assess project needs based on AE principles from `ae_context.md`.
2. **Assess Needs**: Determine the required action (e.g., Installation, Configuration, Integration, Usage, Uninstallation, or Update) by analyzing the project context.
3. **Fetch Related Files**: Access modular files (e.g., `ae_install.md` for setup, `ae_uninstall.md` for removal, `ae_update.md` for updates) from the default path `root/ae_use` to execute steps sequentially.
4. **Execute and Validate**: Follow instructions from the fetched files, perform checks (e.g., via Validation principles), and handle errors as per `ae_context.md`.
5. **Adapt and Optimize**: Modify integrations minimally for project fit, ensuring Reversibility and Modularity.

## Actions

- **Installation**: Use `ae_install.md` to handle dependency setup, configuration, and integration. Adapt to library specifics for seamless addition.
- **Usage**: Apply library features as per the usage file (e.g., `{library_name}_usage.mdc`), focusing on common patterns and best practices.
- **Uninstallation**: Follow `ae_uninstall.md` to remove components, clean up resources, and ensure reversibility.
- **Update**: Reference `ae_update.md` for version transitions, including migration and validation.

## Guidelines

- **Execution**: Process workflows step-by-step, adapting to real-time project needs and library requirements.
- **Error Handling**: Identify and resolve issues, suggesting efficient fixes based on AE principles.
- **Integration**: Apply AE capabilities with concise, adaptable changes.
- **Maintenance**: Reference `ae_context.md` for ongoing updates, cross-file dependencies, and alignment with bootstrap processes.

This enables agents to autonomously manage AE usage, focusing on seamless integration and maintenance.
