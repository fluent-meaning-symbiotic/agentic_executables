# Agentic Executables (AE) Context

## Definitions

- **Agentic Executable (AE)**: A library or package treated as an executable program, managed by AI agents for installation, configuration, usage, and uninstallation.
- **Installation**: Process of adding the AE to a project via CLI or package manager.
- **Configuration**: Adjusting AE settings to fit project requirements.
- **Integration**: Incorporating AE code and logic into the existing codebase.
- **Usage**: Applying AE capabilities in the project as needed.
- **Uninstallation**: Removing the AE and reversing integrations safely.

## Core Principles

- **Agent Empowerment**: Equip AI agents with meta-rules to autonomously maintain, install, configure, integrate, use, and uninstall AEs based on project needs.
- **Modularity**: Structure AE instructions in clear, reusable steps: Installation → Configuration → Integration → Usage → Uninstallation.
- **Contextual Awareness**: Ensure AE documentation provides sufficient domain knowledge for agents to understand integration points without manual intervention.
- **Reversibility**: Design uninstallation to cleanly remove all traces of the AE, restoring the original state.
- **Validation**: Include checks for installation, configuration, and usage to ensure reliability and allow for corrections.
- **Documentation Focus**: Prioritize concise, agent-readable instructions over verbose human-oriented docs.

## Working principles:

1. maintain the library executables (basically - meta instructions).
   1.1 The basic terms & domain knowledge (what is AE and how it works) - `ae_context.md`
   GOAL: To maintain `ae_bootstrap` and `ae_usage` files
   USER: Maintainer of the library
   1.2 The drop file to maintain the library executables - `ae_bootstrap.md`.
   GOAL: To create ae files structure and maintain it.
   USER: Maintainer of the library
   1.3 The drop file to use ae files in library - `ae_usage.md`
   GOAL: To use ae files of this library.
   USER: User (in other words - developer who uses this library)
2. ability to install / uninstall / update (basically, one time to use rules). Created via `ae_bootstrap.md` file.
   2.1 Installation, Configuration, Integration files - `ae_install.md`
   GOAL: To install, configure and integrate the library.
   USER: User
   2.2 Uninstallation file - `ae_uninstall.md`
   GOAL: To uninstall the library.
   USER: User
   2.3 Update file - `ae_update.md`
   GOAL: To update the library from old version to new one.
   USER: User
3. ability to use the library frequently / or depending of its usage needs. Created via `ae_use.md` file.
   3.1 Usage file - the rule, adapted to the library name. For example, for library name `go_router` and Cursor AI usage it can be a rule in the path `go_router_usage.mdc`. During installation to User Codebase , AI Agent needs to ask User what AI Agent should be used, and place / name it according to it. For example, if User wants to use Cursor AI, AI Agent should place this rule to the path `.cursor/rules/go_router_usage.mdc`.
   GOAL: To use the library frequently / or depending of its usage needs.
   USER: User
