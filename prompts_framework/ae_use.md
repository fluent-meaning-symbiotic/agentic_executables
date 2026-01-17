<!--
version: 2.0.0
repository: https://github.com/fluent-meaning-symbiotic/agentic_executables
registry: https://github.com/fluent-meaning-symbiotic/agentic_executables_registry
license: MIT
author: Arenukvern and contributors
format: quick_reference
-->

# AE Use - Developer Quick Reference

How AI agents use AE files in projects. Refer to `ae_context.md` for principles.

## 🚀 Quick Start

**Q: I need to install a library. What do I do?**

1. Fetch `ae_install.md` from registry
2. Review fetched instructions
3. Execute steps sequentially
4. Validate installation

**Example tool call:**
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

Returns: Full `ae_install.md` content to execute.

---

## 📋 Action Mapping

**Q: What action maps to which file?**

| User Need | AE File | Tool Action | Purpose |
|-----------|---------|-------------|---------|
| Install library | `ae_install.md` | `"install"` | Setup, configure, integrate |
| Use library | `ae_use.md` | `"use"` | Usage patterns, best practices |
| Update library | `ae_update.md` | `"update"` | Version migration, rollback |
| Uninstall library | `ae_uninstall.md` | `"uninstall"` | Remove, cleanup, reverse |

**Q: How do I fetch an AE file?**

Use `manage_ae_registry` tool with appropriate action:

```json
{
  "tool": "manage_ae_registry",
  "arguments": {
    "operation": "get_from_registry",
    "library_id": "<language>_<library_name>",
    "action": "<install|use|update|uninstall>"
  }
}
```

**Library ID format**: `<language>_<library_name>`
- Examples: `python_requests`, `dart_provider`, `js_react`

---

## 🔄 Standard Workflow

**Q: What's the typical agent workflow for any action?**

### Universal Pattern (for all actions)

```markdown
1. **Assess Need**
   - Parse user request: "Install requests library"
   - Identify action: Installation
   - Identify library: python_requests

2. **Fetch Instructions**
   - Call: manage_ae_registry(operation="get_from_registry", library_id, action)
   - Receive: Full AE file content (ae_install.md, ae_use.md, etc.)
   - Review: Scan Prerequisites, understand structure

3. **Execute Steps**
   - Follow prerequisites (check versions, tools)
   - Run sequential steps (install, configure, integrate)
   - Apply validations after each major step
   - Handle errors (see 🚨 Error Handling section)

4. **Verify Success**
   - Execute validation steps from AE file
   - Confirm expected outcomes
   - Document completion

5. **Report to User**
   - Summarize what was done
   - Show validation results
   - Note any deviations or issues
```

---

## 🎯 Context-Aware Execution

**Q: How do I adapt instructions to project context?**

### Minimal Adaptation Principle

Execute instructions **as written** unless project-specific requirements conflict.

**When to adapt:**
- Project structure differs (e.g., `src/api/` vs `lib/services/`)
- Naming conventions differ (e.g., `camelCase` vs `snake_case`)
- Framework requirements differ (e.g., Next.js vs vanilla React)

**How to adapt:**
1. Identify the **intent** of the instruction
2. Apply equivalent action in project context
3. Document deviation in completion report

**Example:**

```markdown
# AE instruction says:
"Create src/api/client.py with APIClient class"

# Project uses:
- src/services/ (not src/api/)
- TypeScript (not Python)
- api_client.ts (not client.py)

# Adaptation:
Create src/services/api_client.ts with APIClient class
Same functionality, adapted structure

# Report to user:
"Adapted installation to project structure: 
 Created APIClient in src/services/api_client.ts 
 (project uses TypeScript and services/ directory)"
```

**When NOT to adapt:**
- Core logic changes (don't modify algorithm)
- Validation steps (always execute as written)
- Dependency versions (respect specified versions)
- Security configurations (never weaken security)

---

## ✅ Validation Pattern

**Q: How do I validate after each action?**

### Installation Validation (from ae_install.md)

```markdown
**Standard 3-step pattern:**

1. **Package Check** - Verify installation
```python
import requests
print(f"Installed: {requests.__version__}")
```

2. **Version Check** - Verify correct version
```python
assert requests.__version__ >= "2.28.0"
print("✓ Version correct")
```

3. **Integration Check** - Verify functionality
```python
from src.api.client import APIClient
client = APIClient()
response = client.get('https://httpbin.org/get')
assert response.status_code == 200
print("✓ Integration successful")
client.close()
```
```

### Uninstallation Validation (from ae_uninstall.md)

```markdown
**Verify removal:**

```python
try:
    import requests
    print("✗ Uninstallation failed - library still importable")
except ImportError:
    print("✓ Uninstallation successful")
```

**Verify project still builds:**
```bash
# Run project tests
pytest
# Or build project
python setup.py build
```
```

### Update Validation (from ae_update.md)

```markdown
**Verify version:**
```python
import requests
assert requests.__version__ == "2.31.0"
print("✓ Update successful")
```

**Verify functionality:**
```python
# Test existing features still work
from src.api.client import APIClient
client = APIClient()
response = client.get('https://httpbin.org/get')
assert response.status_code == 200
print("✓ Functionality preserved")
client.close()
```
```

**Q: What if validation fails?**

1. **Read error message** - Understand what failed
2. **Check prerequisites** - Were all requirements met?
3. **Review execution** - Were all steps completed?
4. **Consult troubleshooting** - Check AE file Troubleshooting section
5. **Escalate to user** - Report issue with details

---

## 🚨 Error Handling

**Q: What if instructions fail during execution?**

### Error Response Pattern

```markdown
1. **Capture Error**
   - Full error message
   - Step that failed
   - Context (OS, versions, etc.)

2. **Diagnose**
   - Check prerequisites met
   - Check project structure matches expectations
   - Check versions compatible
   - Consult AE file Troubleshooting section (if present)

3. **Attempt Resolution**
   - If known issue → Apply documented solution
   - If project mismatch → Apply minimal adaptation
   - If missing prerequisite → Install prerequisite first

4. **Escalate if Unresolvable**
   - Report to user with:
     * What failed
     * Why it failed (diagnosis)
     * What was attempted
     * Suggested next steps
```

### Common Error Categories

**Category 1: Prerequisites Not Met**
```markdown
Error: "Python 3.7 required, found 3.6"
Solution: Inform user to upgrade Python
```

**Category 2: Project Structure Mismatch**
```markdown
Error: "src/api/ directory not found"
Solution: Adapt to project structure (e.g., use src/services/)
Document adaptation in report
```

**Category 3: Dependency Conflict**
```markdown
Error: "requests 2.28.0 conflicts with urllib3 2.0.0"
Solution: Check ae_install.md Prerequisites for compatibility
Suggest dependency resolution
```

**Category 4: Permission Error**
```markdown
Error: "Permission denied writing to /usr/local/"
Solution: Suggest using virtual environment or user install
```

**Q: What if AE file instructions are outdated?**

```markdown
**Indicators:**
- Library version in AE file doesn't match latest
- APIs mentioned don't exist in current library
- Dependencies changed

**Response:**
1. Note version mismatch in execution report
2. Attempt reasonable adaptation (if safe)
3. Suggest to user:
   - Check library changelog for breaking changes
   - Notify library maintainer to update AE files
   - Consider using older library version that matches AE file
```

---

## 🔍 Action-Specific Guidance

### Installation (`action="install"`)

**Q: What should I focus on during installation?**

```markdown
**Checklist:**
- [ ] Prerequisites satisfied (tools, versions)
- [ ] Dependencies installed successfully
- [ ] Configuration applied (env vars, config files)
- [ ] Code integrated at correct locations
- [ ] Cleanup/disposal mechanisms in place
- [ ] All validation steps pass

**Common issues:**
- Missing prerequisites → Install first
- Configuration not applied → Double-check env vars, file paths
- Integration unclear → Use project structure as guide
```

### Usage (`action="use"`)

**Q: What should I focus on when using library?**

```markdown
**Checklist:**
- [ ] Basic usage pattern understood
- [ ] Advanced features available if needed
- [ ] Best practices applied
- [ ] Anti-patterns avoided

**Reference ae_use.md for:**
- Code examples (copy-paste patterns)
- Best practices (what to do)
- Anti-patterns (what to avoid)
- Common pitfalls (how to prevent errors)
```

### Update (`action="update"`)

**Q: What should I focus on during updates?**

```markdown
**Checklist:**
- [ ] Current version backed up
- [ ] Breaking changes reviewed
- [ ] Migration steps applied
- [ ] Deprecated APIs updated
- [ ] Tests pass after update
- [ ] Rollback plan available

**Common issues:**
- Breaking changes → Follow migration guide in ae_update.md
- Tests fail → Review changed APIs, update integration
- Rollback needed → Execute rollback plan from ae_update.md
```

### Uninstallation (`action="uninstall"`)

**Q: What should I focus on during uninstallation?**

```markdown
**Checklist:**
- [ ] All integrated code removed
- [ ] Configuration cleaned up
- [ ] Dependencies removed (if safe)
- [ ] Project still builds/runs
- [ ] No orphaned references

**Common issues:**
- Shared dependencies → Don't remove if used by other libraries
- Orphaned references → Search codebase for library imports
- Project breaks → Verify all integration points removed
```

---

## 📚 Quick Reference

**Q: What's the TL;DR for developers?**

```markdown
Developer Quick Flow:

1. Fetch AE file: manage_ae_registry(library_id, action)
2. Execute: Follow steps sequentially
3. Validate: Run validation steps from AE file
4. Adapt minimally: Only when project context requires
5. Report: Summarize completion + validation results
```

**Q: Where can I find library AE files?**

- Registry: https://github.com/fluent-meaning-symbiotic/agentic_executables_registry
- Via tool: `manage_ae_registry(operation="get_from_registry")`

**Q: What if library doesn't have AE files?**

```markdown
**Options:**
1. Check registry first (may exist but not advertised)
2. Install manually using library's official docs
3. Consider creating AE files (see ae_bootstrap.md)
4. Request library maintainer create AE files
```

**Q: How do I verify AE file quality?**

Use validation tools:
- `verify_ae_implementation`: Checklist validation
- `evaluate_ae_compliance`: Quality scoring

---

## 🎓 Best Practices for Agents

**Q: What makes excellent AE file execution?**

**DO:**
- ✓ Read entire AE file before starting
- ✓ Execute steps in order (don't skip)
- ✓ Run all validations
- ✓ Document adaptations clearly
- ✓ Report completion with details

**DON'T:**
- ✗ Skip prerequisites
- ✗ Modify core logic without understanding
- ✗ Ignore validation failures
- ✗ Make assumptions about project structure
- ✗ Proceed if unsure (ask user first)

**Q: How do I handle ambiguity?**

```markdown
**If instruction is unclear:**
1. Check ae_context.md for definitions
2. Review code examples in AE file
3. Look at similar steps for patterns
4. If still unclear → Ask user for clarification

**If project context is unclear:**
1. Analyze project structure
2. Look for similar patterns in codebase
3. Apply minimal adaptation
4. Document reasoning in report
```

---

## 🧠 Memory Aids

**Q: How do I remember these workflows?**

**Spatial Memory (Memory Palace):**
- 🚀 **Launch Pad** = Quick Start (fetch → execute → validate)
- 📋 **Control Center** = Action Mapping (install/use/update/uninstall)
- 🔄 **Assembly Line** = Standard Workflow (assess → fetch → execute → verify → report)
- 🎯 **Target Range** = Context Adaptation (minimal changes, document deviations)
- ✅ **Quality Check** = Validation (3-step pattern)
- 🚨 **Emergency Room** = Error Handling (capture → diagnose → resolve → escalate)

**Pattern Recognition:**
- All AE files follow same structure (Prerequisites → Steps → Validation)
- All actions follow same workflow (fetch → execute → validate → report)
- All validations follow 3-step pattern (check → verify → test)

**Q: What's the one thing to remember?**

**The AE Golden Rule:**
> "Execute as written, adapt minimally, validate thoroughly, report clearly."
