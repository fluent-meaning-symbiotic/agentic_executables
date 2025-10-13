# Contributing to the AE Registry

> **⚠️ Important Notice**
>
> This guide applies to submitting libraries to the **official external registry** at:  
> **https://github.com/fluent-meaning-symbiotic/agentic_executables_registry**
>
> The local `ae_use_registry/` folder in this repository is for demo/examples only.  
> All production library submissions should go to the official registry.

---

This guide explains how to contribute library ae_use files to the registry using AI agents and the `manage_ae_registry` MCP tool.

## For Library Authors

### Prerequisites

1. Create ae_use folder in your library repository with all required files:

   - `ae_install.md` - Installation instructions
   - `ae_uninstall.md` - Uninstallation and cleanup
   - `ae_update.md` - Update and migration guide
   - `ae_use.md` - Usage patterns and best practices

2. Test your ae_use files locally to ensure they work correctly

### Submission Process

#### Step 1: Prepare Your Library

Ask your AI agent to use the MCP tool:

```
Operation: submit_to_registry
Library URL: https://github.com/your-org/your-library
Library ID: <language>_<library_name>
AE Use Files: ae_use/ae_install.md,ae_use/ae_uninstall.md,ae_use/ae_update.md,ae_use/ae_use.md
```

**Library ID Format:**

- Must be: `<language>_<library_name>`
- Examples: `dart_provider`, `python_requests`, `javascript_react`
- For complex names: `dart_xsoulspace_lints`, `python_beautiful_soup`

#### Step 2: Follow Returned Instructions

The MCP tool will return:

- PR instructions (step-by-step git commands)
- Files to copy (with source and target paths)
- Generated README.md content
- Status (new or update)

#### Step 3: Submit Pull Request

Your AI agent will:

1. Clone/update the registry repository
2. Create a feature branch
3. Copy your ae_use files to the registry
4. Generate a library-specific README.md
5. Commit and push changes
6. Create a pull request

#### Step 4: Wait for Review

Maintainers will review:

- File completeness (all 4 ae files + README)
- Library ID naming convention
- File quality and conciseness
- Adherence to AE principles

## For Developers

### Using Libraries from Registry

Ask your AI agent to fetch library files:

```
Operation: get_from_registry
Library ID: dart_provider
Action: install (or uninstall, update, use)
```

The tool returns the complete file content directly - no manual fetching needed!

### Available Libraries

See individual folders in `ae_use_registry/` for all available libraries.

Each library folder contains:

- `README.md` - Library metadata (repo, authors, license)
- `ae_install.md` - Installation guide
- `ae_uninstall.md` - Uninstallation guide
- `ae_update.md` - Update guide
- `ae_use.md` - Usage patterns

## For Monorepo Maintainers

If you're managing multiple internal libraries in a monorepo, you can set up a local registry:

```
Operation: bootstrap_local_registry
AE Use Path: /path/to/your/library/ae_use
```

This generates instructions for creating your own ae_use_registry structure.

## Quality Guidelines

### File Requirements

1. **Conciseness**: Keep files under 500 lines when possible
2. **Validation**: Include verification steps in ae_install.md
3. **Reversibility**: Provide clear rollback instructions in ae_uninstall.md
4. **Integration Points**: Document what files are modified
5. **Best Practices**: Include common patterns in ae_use.md

### Content Structure

Each file should include:

- Clear context and prerequisites
- Step-by-step instructions
- Validation/verification steps
- Common issues and solutions
- Integration points

### AE Principles

Follow these principles:

- **Agent Empowerment**: Write for AI agents, not humans
- **Modularity**: Break down complex tasks
- **Contextual Awareness**: Provide environment context
- **Reversibility**: Always include cleanup/rollback
- **Validation**: Include verification steps

## Example Libraries

See these examples for reference:

- `dart_xsoulspace_lints/` - Dart linting package
- `python_requests/` - Python HTTP library

## Registry Maintenance

### Updating Existing Libraries

Use the same submission process with status="update":

- Same library_id
- Updated ae_use files
- Tool detects existing entry automatically

### Library Removal

To remove a library from the registry:

1. Open an issue explaining why
2. Maintainers will review and process removal

## Questions?

- Open an issue in the repository
- Check existing library examples
- Review the main README.md

## Recognition

All contributors are credited in their library's README.md file with:

- Repository link
- Author names
- License information

Thank you for contributing to the AE ecosystem!
