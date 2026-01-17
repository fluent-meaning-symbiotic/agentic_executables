# Agentic Executables - Developer Experience FAQ

Practical guide for using the Agentic Executables framework. Memory Palace format for AI agent navigation.

## 🏠 MCP Server Hub

**Q: How do I install the MCP server?**

```bash
cd agentic_executables_mcp
./build.sh
./build/server
```

**Q: How do I configure the MCP server in Claude Desktop?**

```json
{
  "mcpServers": {
    "agentic_executables": {
      "command": "/absolute/path/to/agentic_executables_mcp/build/server"
    }
  }
}
```

**Q: What are the system requirements?**

- Dart SDK 3.0+ (for building from source) OR pre-built executable
- Network access for registry operations (GitHub API)

---

## 🔧 Tool Forge

**Q: How do I get started with the AE framework?**

```json
{
  "tool": "get_agentic_executable_definition",
  "arguments": {}
}
```

Returns: Framework overview, contexts, actions, tools, and principles.

**Q: How do I get instructions for creating AE files (library author)?**

```json
{
  "tool": "get_ae_instructions",
  "arguments": {
    "context_type": "library",
    "action": "bootstrap"
  }
}
```

Returns: `ae_bootstrap.md` + `ae_context.md` with guidance.

**Q: How do I get instructions for using a library (developer)?**

```json
{
  "tool": "get_ae_instructions",
  "arguments": {
    "context_type": "project",
    "action": "install"
  }
}
```

Returns: `ae_context.md` + `ae_use.md` with guidance.

**Q: How do I verify my AE implementation?**

```json
{
  "tool": "verify_ae_implementation",
  "arguments": {
    "context_type": "library",
    "action": "bootstrap",
    "files_modified": "[{\"path\": \"ae_install.md\", \"loc\": 180}]",
    "checklist_completed": "{\"modularity\": true, \"contextual_awareness\": true}"
  }
}
```

Returns: Verification checklist with pass/fail results.

**Q: How do I evaluate compliance of my AE files?**

```json
{
  "tool": "evaluate_ae_compliance",
  "arguments": {
    "context_type": "library",
    "action": "bootstrap",
    "files_created": "[{\"path\": \"ae_install.md\", \"loc\": 150}]",
    "sections_present": "[\"Installation\", \"Configuration\"]",
    "validation_steps_exists": "true"
  }
}
```

Returns: Compliance score. LOC scoring: <500 PASS, 500-800 WARNING, >800 FAIL.

**Q: What contexts and actions are available?**

**Contexts:** `"library"` (maintain AE files) | `"project"` (use AE in projects)

**Actions:** `"bootstrap"` (library only) | `"install"` | `"uninstall"` | `"update"` | `"use"`

---

## 🏭 Library Registry Factory

**Q: How do I fetch a library from the registry?**

```json
{
  "tool": "manage_ae_registry",
  "arguments": {
    "operation": "get_from_registry",
    "library_id": "python_requests",
    "action": "install"
  }
}
```

Returns: Content of `ae_install.md` directly from registry.

**Q: What library ID format should I use?**

Format: `<language>_<library_name>`

Examples: `python_requests` ✓ | `dart_provider` ✓ | `mylib` ✗ (missing language prefix)

**Q: How do I submit a library to the registry?**

```json
{
  "tool": "manage_ae_registry",
  "arguments": {
    "operation": "submit_to_registry",
    "library_url": "https://github.com/owner/repo",
    "library_id": "python_requests",
    "ae_use_files": "ae_use/ae_install.md,ae_use/ae_uninstall.md,ae_use/ae_update.md,ae_use/ae_use.md"
  }
}
```

Returns: PR instructions with file mappings and registry folder path.

**Q: What files are required for registry submission?**

Required: `ae_install.md`, `ae_uninstall.md`, `ae_update.md`, `ae_use.md`. Optional: `README.md`.

**Q: Where is the official registry located?**

GitHub: https://github.com/fluent-meaning-symbiotic/agentic_executables_registry

Registry path: `ae_use_registry/<library_id>/`

---

## 📦 AE File Workshop

**Q: How do I create AE files for my library?**

1. Call `get_ae_instructions(context="library", action="bootstrap")`
2. Create files in `ae_use/` directory: `ae_install.md`, `ae_uninstall.md`, `ae_update.md`, `ae_use.md`
3. Follow structure from bootstrap guide

**Q: What's the structure of an AE file?**

Markdown with: step-by-step instructions, code examples, validation steps, integration points, reversibility considerations, context for AI agents.

**Q: How do I structure ae_install.md?**

```markdown
# Installation
## Prerequisites
## Installation Steps
## Configuration
## Integration
## Validation
```

**Q: How do I structure ae_uninstall.md?**

```markdown
# Uninstallation
## Prerequisites
## Uninstallation Steps
## Validation
```

**Q: How do I structure ae_update.md?**

```markdown
# Update
## Prerequisites
## Update Steps
## Rollback
```

**Q: How do I structure ae_use.md?**

```markdown
# Usage
## Basic Usage
## Advanced Usage
## Best Practices
## Anti-patterns
```

**Q: What principles should I follow?**

- **Agent Empowerment**: Provide context for autonomous execution
- **Modularity**: Clear, reusable steps
- **Contextual Awareness**: Include domain knowledge
- **Reversibility**: Clean uninstallation
- **Validation**: Verification steps
- **Documentation Focus**: Concise, agent-readable

**Q: How long should AE files be?**

Target: <500 lines. Scoring: <500 PASS, 500-800 WARNING, >800 FAIL.

---

## 🚀 Bootstrap Station

**Q: I'm a library author. Where do I start?**

1. Install MCP server (see 🏠 MCP Server Hub)
2. Call `get_agentic_executable_definition`
3. Call `get_ae_instructions(context="library", action="bootstrap")`
4. Create AE files following bootstrap guide
5. Verify with `verify_ae_implementation`
6. Evaluate with `evaluate_ae_compliance`
7. Submit with `manage_ae_registry(operation="submit_to_registry")`

**Q: How do I update existing AE files?**

1. Modify AE files locally
2. Call `verify_ae_implementation` with updated files
3. Call `evaluate_ae_compliance` to check quality
4. Submit updated files using `manage_ae_registry(submit_to_registry)`

---

## 💻 Developer Workstation

**Q: I'm a developer. How do I use a library with AE support?**

1. Install MCP server (see 🏠 MCP Server Hub)
2. Call `manage_ae_registry(operation="get_from_registry", library_id, action="install")`
3. Review returned `ae_install.md`
4. Have AI agent execute instructions
5. Verify with `verify_ae_implementation`

**Q: How do I uninstall a library installed via AE?**

```json
{
  "tool": "manage_ae_registry",
  "arguments": {
    "operation": "get_from_registry",
    "library_id": "python_requests",
    "action": "uninstall"
  }
}
```

Then execute returned `ae_uninstall.md` instructions.

**Q: How do I update a library installed via AE?**

```json
{
  "tool": "manage_ae_registry",
  "arguments": {
    "operation": "get_from_registry",
    "library_id": "python_requests",
    "action": "update"
  }
}
```

**Q: How do I use a library in my code?**

```json
{
  "tool": "manage_ae_registry",
  "arguments": {
    "operation": "get_from_registry",
    "library_id": "python_requests",
    "action": "use"
  }
}
```

Returns `ae_use.md` with usage patterns.

---

## ✅ Validation Lab

**Q: What does verification check?**

Modularity, contextual awareness, agent empowerment, validation, integration, reversibility, and more (see tool response for full checklist).

**Q: What does compliance evaluation score?**

File structure (required sections), LOC (<500 PASS, 500-800 WARNING, >800 FAIL), validation steps, integration points, reversibility, meta-rules.

**Q: How do I interpret verification results?**

Pass/fail for each checklist item, overall verification status, recommendations for improvement. Address any FAIL items before submitting.

**Q: How do I interpret compliance scores?**

Overall Score: PASS / WARNING / FAIL. LOC Score: <500 PASS, 500-800 WARNING, >800 FAIL. Principle Scores: Individual scores. Recommendations: Actionable feedback.

---

## 🎯 Common Patterns

**Q: How do I handle dependencies in ae_install.md?**

```markdown
## Installation
### Step 1: Install Dependencies
```bash
pip install requests
```
### Step 2: Verify Dependencies
```python
import requests
print(requests.__version__)
```
```

**Q: How do I handle configuration files?**

```markdown
## Configuration
### Step 1: Create Config File
Create `config.yaml`:
```yaml
api_key: YOUR_API_KEY
```
```

**Q: How do I ensure reversibility?**

```markdown
## Uninstallation
### Step 1: Remove Code
Delete integration code from `src/api/client.py`
### Step 2: Remove Dependencies
```bash
pip uninstall library-name
```
### Step 3: Validation
Verify library is no longer importable.
```

---

## 🚨 Troubleshooting

**Q: MCP server won't start**

Check: Executable path correct, execute permissions (`chmod +x build/server`), resources directory exists.

**Q: Registry fetch fails**

Check: Library ID format correct (`<language>_<library_name>`), library exists in registry, network connectivity.

**Q: Tool returns error**

Check: Required parameters provided, parameter values match enum values (context: "library" or "project"), JSON strings properly formatted.

**Q: Verification always fails**

Common issues: Missing required sections, checklist items not completed, files not properly structured. Review `ae_context.md` principles.

**Q: Compliance score is always low**

Common issues: Files too long (condense), missing validation steps (add), missing integration points (document), missing reversibility (add cleanup).

---

## 📚 Reference

**Q: Where can I find example AE files?**

Registry: https://github.com/fluent-meaning-symbiotic/agentic_executables_registry/tree/main/ae_use

Local examples: `ae_use_registry/` directory

**Q: Where is the framework documentation?**

- Framework core: `prompts_framework/`
- MCP server: `agentic_executables_mcp/README.md`
- Bootstrap guide: `prompts_framework/ae_bootstrap.md`
