# Agentic Executables (AE) for xsoulspace_ui_foundation

This directory contains Agentic Executable (AE) documentation for the `xsoulspace_ui_foundation` library, enabling AI agents to autonomously manage the library lifecycle.

## Files Overview

### Meta Files (for Library Maintainers)

1. **ae_context.md**

   - Basic terms and domain knowledge
   - Core principles and working principles
   - Defines what AE is and how it works
   - Target User: Library Maintainer

2. **ae_bootstrap.md**
   - Guides AI agents in creating and maintaining AE files
   - Workflow for analyzing and updating AE documentation
   - Guidelines for file generation
   - Target User: Library Maintainer

### User Files (for Library Users/Developers)

3. **ae_install.md** (~290 lines)

   - Installation, configuration, and integration instructions
   - Step-by-step setup guide
   - Validation and troubleshooting
   - Covers: dependencies, imports, extensions, pagination, interfaces
   - Target User: Developer installing the library

4. **ae_uninstall.md** (~280 lines)

   - Safe removal and cleanup procedures
   - Code migration patterns for alternatives
   - Rollback procedures
   - Complete reversibility guidance
   - Target User: Developer removing the library

5. **ae_update.md** (~350 lines)

   - Version update procedures
   - Migration guides for breaking changes
   - Backup and rollback strategies
   - Version-specific instructions
   - Target User: Developer updating the library

6. **ae_use.md** (~420 lines)
   - Usage patterns and best practices
   - AI agent rule generation
   - Common use cases and anti-patterns
   - Code examples for all major features
   - Target User: Developer (via AI Agent)

## Structure Summary

```
ae_use/
├── README.md              # This file
├── ae_context.md          # AE definitions and principles
├── ae_bootstrap.md        # Maintenance guide for AE files
├── ae_install.md          # Installation guide
├── ae_uninstall.md        # Uninstallation guide
├── ae_update.md           # Update and migration guide
└── ae_use.md              # Usage rule generation
```

## Total Documentation

- **Total Files**: 7 (including this README)
- **Total Lines of Code**: ~1,449 lines
- **Documentation Coverage**: Complete lifecycle (install → use → update → uninstall)

## For Library Maintainers

### Maintaining AE Files

When the library is updated:

1. Review changes in the codebase
2. Check `ae_bootstrap.md` for maintenance workflow
3. Update affected files:
   - New features → Update `ae_install.md` and `ae_use.md`
   - Breaking changes → Update `ae_update.md` with migration guide
   - Deprecations → Document in `ae_update.md`
   - API changes → Update all relevant files

### Updating Workflow

1. Read `ae_bootstrap.md` for guidelines
2. Compare current codebase with existing AE files
3. Update files to reflect changes
4. Maintain consistency across all documents
5. Follow AE principles: modularity, reversibility, validation

## For Library Users

### Using AE Files

AI agents can use these files to:

1. **Install**: Follow `ae_install.md` for setup
2. **Use**: Generate usage rules from `ae_use.md`
3. **Update**: Follow `ae_update.md` for version migrations
4. **Uninstall**: Follow `ae_uninstall.md` for cleanup

### Example AI Agent Commands

- "Install xsoulspace_ui_foundation using AE"
- "Create usage rule for xsoulspace_ui_foundation"
- "Update xsoulspace_ui_foundation to version 0.3.0"
- "Uninstall xsoulspace_ui_foundation cleanly"

## Key Features Documented

1. **Extension Methods**

   - BuildContext extensions (theme, size, navigation)
   - Widget extensions (padding, opacity, layout)
   - DateTime extensions (formatting, comparison)

2. **Pagination Utilities**

   - BasePagingController pattern
   - HashPagingController for deduplication
   - Request builder pattern
   - Integration with infinite_scroll_pagination

3. **Interfaces**

   - Loadable interface for async initialization
   - Implementation patterns

4. **Utilities**
   - Device runtime type detection
   - Keyboard control
   - UI helpers

## Compliance

✅ Installation instructions with validation
✅ Configuration and integration guides
✅ Uninstallation with full reversibility
✅ Update procedures with migration guides
✅ Usage patterns with best practices
✅ Troubleshooting and rollback procedures
✅ Meta-rules for AI agents
✅ Concise documentation (<500 LOC per file)

## Version

- **AE Version**: 1.0.0
- **Library Version**: 0.2.3+
- **Repository**: https://github.com/xsoulspace/dart_flutter_packages
- **License**: MIT

## Contributing

When contributing to xsoulspace_ui_foundation:

1. Update AE files to reflect code changes
2. Follow AE principles from `ae_context.md`
3. Maintain documentation conciseness
4. Test AI agent compatibility
5. Update version numbers

## References

- **AE Framework**: https://github.com/fluent-meaning-symbiotic/agentic_executables
- **Library Repo**: https://github.com/xsoulspace/dart_flutter_packages
- **AE Principles**: See `ae_context.md`
- **Bootstrap Guide**: See `ae_bootstrap.md`

---

_Generated via AE Bootstrap for xsoulspace_ui_foundation_
