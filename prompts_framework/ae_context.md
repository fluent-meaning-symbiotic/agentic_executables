<!--
version: 2.0.0
repository: https://github.com/fluent-meaning-symbiotic/agentic_executables
registry: https://github.com/fluent-meaning-symbiotic/agentic_executables_registry
license: MIT
author: Arenukvern and contributors
format: memory_palace_faq
-->

# Agentic Executables (AE) Context - Quick Reference

Memory Palace format for AI agent navigation.

## 🏛️ Foundation Hall - Core Definitions

**Q: What is an Agentic Executable (AE)?**

A: A library or package treated as an executable program, managed by AI agents for installation, configuration, usage, and uninstallation.

**Q: What are the 5 key lifecycle stages?**

- **Installation**: Process of adding the AE to a project via CLI or package manager
- **Configuration**: Adjusting AE settings to fit project requirements
- **Integration**: Incorporating AE code and logic into the existing codebase
- **Usage**: Applying AE capabilities in the project as needed
- **Uninstallation**: Removing the AE and reversing integrations safely

---

## 🎯 Principles Chamber - Core Guidelines

**Q: What are the 6 Core Principles?**

1. **Agent Empowerment**: Equip AI agents with meta-rules to autonomously maintain, install, configure, integrate, use, and uninstall AEs based on project needs
2. **Modularity**: Structure AE instructions in clear, reusable steps: Installation → Configuration → Integration → Usage → Uninstallation
3. **Contextual Awareness**: Ensure AE documentation provides sufficient domain knowledge for agents to understand integration points without manual intervention
4. **Reversibility**: Design uninstallation to cleanly remove all traces of the AE, restoring the original state
5. **Validation**: Include checks for installation, configuration, and usage to ensure reliability and allow for corrections
6. **Documentation Focus**: Prioritize concise, agent-readable instructions over verbose human-oriented docs

**Q: Why these principles?**

- **Agent Empowerment**: Enables autonomous decisions in context without constant human guidance
- **Modularity**: Reduces cognitive load, enables reuse across different projects
- **Contextual Awareness**: Prevents "missing context" failures where agents lack domain knowledge
- **Reversibility**: Critical for experimentation safety - agents can cleanly undo changes
- **Validation**: Catches errors early, builds trust in automation
- **Documentation Focus**: Optimizes for AI parsing speed and comprehension

---

## 🗺️ Navigation Nexus - File Mapping

**Q: What AE files exist and who uses them?**

| File | Context | User | Goal |
|------|---------|------|------|
| `ae_context.md` | Both | Both | Shared vocabulary & principles |
| `ae_bootstrap.md` | Library | Maintainer | Create/update AE files |
| `ae_use.md` | Project | Developer | Use AE files in projects |
| `ae_install.md` | Project | Developer | Install library |
| `ae_uninstall.md` | Project | Developer | Uninstall library |
| `ae_update.md` | Project | Developer | Update library version |
| `{lib}_usage.mdc` | Project | Developer | Frequent usage patterns |

**Q: What are the two contexts?**

- **Library context**: Maintaining AE files (author/maintainer perspective)
  - Goal: Create and maintain `ae_bootstrap` and `ae_use` files
  - User: Library maintainer
- **Project context**: Using AE files (developer perspective)
  - Goal: Install, configure, integrate, use, and uninstall libraries
  - User: Developer who uses the library

**Q: What are the working principles?**

1. **Maintain library executables** (meta-instructions):
   - 1.1 Basic terms & domain knowledge → `ae_context.md`
   - 1.2 Drop file to maintain executables → `ae_bootstrap.md`
   - 1.3 Drop file to use AE files → `ae_use.md`

2. **One-time operations** (created via `ae_bootstrap.md`):
   - 2.1 Installation, Configuration, Integration → `ae_install.md`
   - 2.2 Uninstallation → `ae_uninstall.md`
   - 2.3 Update from old to new version → `ae_update.md`

3. **Frequent operations** (created via `ae_use.md`):
   - 3.1 Usage file → Rule adapted to library name (e.g., `go_router_usage.mdc`)
   - Placement: Agent asks user for AI agent type and places accordingly (e.g., `.cursor/rules/` for Cursor AI)

---

## 🧬 Pattern Library - Common Structures

**Q: How do I structure ae_install.md?**

```markdown
# Installation
## Prerequisites
- List required tools/versions
## Installation Steps
1. Install dependencies
2. Configure settings
3. Integrate components
## Configuration
- Environment variables
- Config files
## Integration
- Code placement
- Entry points
## Validation
- Verify installation
- Test integration
```

**Q: How do I ensure reversibility in ae_uninstall.md?**

```markdown
# Uninstallation
## Prerequisites
- Backup data if needed
## Uninstallation Steps
1. Remove integrated code (reverse of ae_install integration)
2. Clean up configurations
3. Remove dependencies
## Validation
- Verify complete removal
- Ensure project still builds
```

**Q: What makes good ae_update.md?**

```markdown
# Update
## Prerequisites
- Backup current version
- Review breaking changes
## Update Steps
1. Compare current vs target version
2. Apply migration procedures
3. Handle breaking changes
4. Re-integrate updated components
## Rollback
- How to revert to previous version
## Validation
- Test updated functionality
```

---

## 📏 Quality Standards

**Q: What LOC limits should I follow?**

- **Target**: <500 lines per file
- **Warning**: 500-800 lines (acceptable but condense if possible)
- **Fail**: >800 lines (too long for efficient agent processing)

**Q: What metadata is required?**

```markdown
<!--
version: 1.0.0
repository: https://github.com/owner/repo
license: MIT
author: Name and contributors
-->
```

**Q: Why version in metadata?**

Enables version validation, compatibility checks, and document discovery. Agents can verify they're using the correct version of AE files.

---

## 🎨 Best Practices

**Q: How do I write agent-friendly instructions?**

**DO:**
- Use imperative voice: "Install dependencies"
- Provide concrete examples: `pip install requests`
- Include validation: "Verify by running `import requests`"
- Structure with headings: `## Installation Steps`

**DON'T:**
- Use passive voice: "Dependencies should be installed"
- Be vague: "Set up the library"
- Skip validation: No way to verify success
- Wall of text: No structure

**Q: How do I handle library-specific complexity?**

If library has complex setup:
1. Break into smaller modules (separate files if needed)
2. Use nested checklists
3. Provide decision trees: "If using feature X → do Y"
4. Include troubleshooting section

**Q: How do I maintain consistency across libraries?**

Follow template structures from this document's Pattern Library section. All AE files should follow the same organizational patterns.
