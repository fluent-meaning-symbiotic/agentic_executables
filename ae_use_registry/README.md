# Agentic Executables (AE) Registry

This registry contains curated AE documentation for popular libraries, enabling AI agents to install, configure, and manage them as executable programs.

## Purpose

The AE Registry serves as a centralized repository of library-specific AE files, allowing:

- **Library authors** to publish standardized installation/usage instructions
- **Developers** to quickly integrate libraries through AI agents
- **AI agents** to access consistent, structured guidance for library management

## Naming Convention

Library entries must follow this format: `<language>_<library_name>`

Examples:

- `dart_xsoulspace_lints` - Dart linting package
- `python_requests` - Python HTTP library
- `javascript_react` - React JavaScript library

## Required Files

Each library entry must contain:

1. **README.md** - Library metadata (repository URL, authors, license)
2. **ae_install.md** - Installation instructions for AI agents
3. **ae_uninstall.md** - Uninstallation and cleanup instructions
4. **ae_update.md** - Update and migration instructions
5. **ae_use.md** - Usage patterns and best practices

## File Format Requirements

All AE files should:

- Be concise and actionable (prefer < 500 LOC)
- Include validation steps
- Define clear integration points
- Provide reversibility instructions
- Follow AE framework principles (modularity, contextual awareness, agent empowerment)

## Contributing

### For Library Authors

1. Create ae_use folder in your library repository with all required files
2. Use an AI agent with the `manage_ae_registry` MCP tool:
   ```
   Operation: submit_to_registry
   Inputs: library_url, library_id, ae_use_files
   ```
3. Follow the returned PR instructions to submit your library
4. Maintainers will review and merge your submission

### For Updates

Use the same process - the tool will detect existing entries and guide you through the update flow.

## Structure Example

```
ae_use_registry/
├── README.md (this file)
├── dart_xsoulspace_lints/
│   ├── README.md
│   ├── ae_install.md
│   ├── ae_uninstall.md
│   ├── ae_update.md
│   └── ae_use.md
└── python_requests/
    ├── README.md
    ├── ae_install.md
    ├── ae_uninstall.md
    ├── ae_update.md
    └── ae_use.md
```

## Quality Guidelines

- **Conciseness**: Prefer focused, specific instructions over comprehensive documentation
- **Validation**: Always include verification steps
- **Reversibility**: Provide clear uninstall/rollback procedures
- **Best Practices**: Incorporate language/ecosystem conventions
- **Anti-patterns**: Warn about common pitfalls

## License

Each library entry maintains its own license information in its README.md file.
