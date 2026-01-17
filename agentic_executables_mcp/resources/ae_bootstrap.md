<!--
version: 2.0.0
repository: https://github.com/fluent-meaning-symbiotic/agentic_executables
registry: https://github.com/fluent-meaning-symbiotic/agentic_executables_registry
license: MIT
author: Arenukvern and contributors
format: workflow_faq
-->

# AE Bootstrap - Library Maintainer Guide

Guides AI agents in creating/maintaining AE files. Refer to `ae_context.md` for principles.

## 🎬 Quick Start

**Q: I'm maintaining a library. What do I do first?**

1. Read `ae_context.md` for core principles and definitions
2. Locate existing AE files in `root/ae_use/` or `ae_use_registry/<library_id>/`
3. If files exist → Follow Update Workflow (see 🔄 section)
4. If no files → Follow Create Workflow (see 🏗️ section)

**Q: What files will I create/maintain?**

Required files:
- `ae_install.md` - Installation, configuration, integration instructions
- `ae_uninstall.md` - Uninstallation and cleanup instructions
- `ae_update.md` - Version update and migration instructions
- `ae_use.md` - Usage patterns and best practices
- `README.md` (optional) - Human-readable overview

---

## 🔍 Discovery Phase

**Q: Where do AE files live?**

Default locations:
- **Library source**: `<library_root>/ae_use/`
- **Registry**: `ae_use_registry/<library_id>/`

Example: For library `python_requests` → `ae_use_registry/python_requests/`

**Q: What files should I look for?**

```bash
# Check if AE files exist
ls ae_use/
# Expected: ae_install.md, ae_uninstall.md, ae_update.md, ae_use.md
```

**Q: How do I analyze the codebase?**

Review systematically:

1. **Library Architecture**
   - Module structure (packages, classes, functions)
   - Entry points (main APIs, initialization)
   - Configuration mechanisms (env vars, config files, CLI flags)

2. **Dependencies**
   - Required packages and versions
   - System requirements (OS, tools)
   - Optional dependencies for features

3. **Integration Points**
   - Where library code typically goes in projects
   - Initialization/setup patterns
   - Common usage patterns
   - Resource cleanup needs (connections, files, memory)

4. **Configuration Requirements**
   - API keys, credentials
   - Settings files (YAML, JSON, etc.)
   - Environment variables

5. **Common Usage Patterns**
   - Basic use cases
   - Advanced scenarios
   - Best practices
   - Anti-patterns to avoid

---

## 🏗️ Creation Workflow

**Q: How do I generate ae_install.md?**

Follow this step-by-step analysis pattern:

### Step 1: Identify Dependencies

```markdown
**Example Analysis:**
Library: requests (Python HTTP library)

Dependencies:
- Python >= 3.7
- pip package manager
- Optional: urllib3, certifi (auto-installed)

**In ae_install.md:**
## Prerequisites
- Python 3.7 or higher
- pip package manager

## Installation Steps
### Step 1: Install Dependencies
```bash
pip install requests>=2.28.0
```
```

### Step 2: Find Configuration Points

```markdown
**Example Analysis:**
Library: requests

Configuration:
- No config file required for basic usage
- Optional: SSL certificates path via env var
- Optional: Proxy settings

**In ae_install.md:**
## Configuration
### Optional: SSL Configuration
```bash
export REQUESTS_CA_BUNDLE=/path/to/certfile
```

### Optional: Proxy Configuration
```bash
export HTTP_PROXY=http://proxy.example.com:8080
export HTTPS_PROXY=https://proxy.example.com:8080
```
```

### Step 3: Map Integration Points

```markdown
**Example Analysis:**
Library: requests

Integration Points:
- Import in API client modules
- Create session objects for connection pooling
- Configure retry strategies
- Set default headers

**In ae_install.md:**
## Integration
### Step 1: Create API Client Module
Create `src/api/client.py`:
```python
import requests

class APIClient:
    def __init__(self):
        self.session = requests.Session()
        self.session.headers.update({'User-Agent': 'MyApp/1.0'})
    
    def get(self, url):
        return self.session.get(url)
    
    def close(self):
        self.session.close()
```

### Step 2: Initialize in Application
In `src/main.py`:
```python
from src.api.client import APIClient

api_client = APIClient()
# Use api_client throughout application
```
```

### Step 4: Bridge to Application

```markdown
**Example Analysis:**
Library: requests

Application Bridges:
- Service layer integration
- Error handling patterns
- Logging integration

**In ae_install.md:**
## Integration (continued)
### Step 3: Integrate with Services
In `src/services/data_service.py`:
```python
from src.api.client import APIClient

class DataService:
    def __init__(self, api_client: APIClient):
        self.api = api_client
    
    def fetch_data(self):
        response = self.api.get('https://api.example.com/data')
        response.raise_for_status()
        return response.json()
```
```

### Step 5: Define Cleanup

```markdown
**Example Analysis:**
Library: requests

Cleanup Needs:
- Close session to release connections
- Clear connection pool

**In ae_install.md:**
## Integration (continued)
### Step 4: Implement Cleanup
In `src/main.py`:
```python
import atexit

api_client = APIClient()
atexit.register(api_client.close)

# Or in application shutdown:
def shutdown():
    api_client.close()
```
```

### Step 6: Write Validation Steps

```markdown
**In ae_install.md:**
## Validation
### Verify Installation
```python
import requests
print(f"Requests version: {requests.__version__}")
assert requests.__version__ >= "2.28.0"
```

### Verify Integration
```python
from src.api.client import APIClient

client = APIClient()
response = client.get('https://httpbin.org/get')
assert response.status_code == 200
print("✓ Integration successful")
client.close()
```
```

**Q: What high-level patterns should ae_install.md include?**

Abstract structure for all libraries:

1. **Prerequisites** - Required tools, versions, system requirements
2. **Installation** - Dependency installation commands
3. **Configuration** - Settings, env vars, config files
4. **Integration** - Code placement, initialization, entry points
5. **Bridge to Application** - Connect to UI, services, state management
6. **Cleanup** - Resource disposal mechanisms
7. **Validation** - Verification steps

---

## 🔄 Generating ae_uninstall.md

**Q: How do I generate ae_uninstall.md from ae_install.md?**

Reverse the integration steps:

```markdown
# From ae_install.md → ae_uninstall.md Mapping:

Installation Step               → Uninstallation Step
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. Install dependencies         → 5. Remove dependencies
2. Configure settings           → 4. Remove configurations
3. Integrate code               → 3. Remove integrated code
4. Bridge to application        → 2. Disconnect from application
5. Setup cleanup handlers       → 1. Execute cleanup handlers

# Validation: Verify library is no longer importable/usable
```

**Q: What's a concrete example?**

```markdown
# ae_install.md had:
## Integration
### Step 1: Create API Client Module
Create `src/api/client.py` with APIClient class

### Step 2: Initialize in Application
Add to `src/main.py`: `api_client = APIClient()`

# ae_uninstall.md should have:
## Uninstallation Steps
### Step 1: Remove Integration from Application
In `src/main.py`:
- Remove line: `from src.api.client import APIClient`
- Remove line: `api_client = APIClient()`
- Remove cleanup handler: `atexit.register(api_client.close)`

### Step 2: Remove API Client Module
Delete file: `src/api/client.py`

### Step 3: Remove Service Integrations
In `src/services/data_service.py`:
- Remove imports: `from src.api.client import APIClient`
- Remove or refactor methods that use APIClient

### Step 4: Remove Configuration
Remove environment variables:
```bash
unset REQUESTS_CA_BUNDLE
unset HTTP_PROXY
unset HTTPS_PROXY
```

### Step 5: Uninstall Dependencies
```bash
pip uninstall requests -y
```

## Validation
```python
try:
    import requests
    print("✗ Uninstallation failed - library still importable")
except ImportError:
    print("✓ Uninstallation successful")
```
```

---

## 🔀 Generating ae_update.md

**Q: How do I generate ae_update.md?**

Focus on version transitions and breaking changes:

```markdown
## Structure:
1. **Prerequisites** - Backup strategy, version compatibility check
2. **Version Comparison** - Current vs target, breaking changes
3. **Update Procedure** - Migration steps, dependency updates
4. **Re-integration** - Apply new patterns, update API calls
5. **Rollback Plan** - How to revert if issues occur
6. **Validation** - Test updated functionality

## Example:
# Update from requests 2.28.0 → 2.31.0

## Prerequisites
### Check Current Version
```python
import requests
print(f"Current version: {requests.__version__}")
```

### Backup Configuration
```bash
cp src/api/client.py src/api/client.py.backup
```

## Version Comparison
**Current**: 2.28.0
**Target**: 2.31.0
**Breaking Changes**: None (patch release)
**New Features**: Improved JSON handling, better SSL support

## Update Steps
### Step 1: Update Dependency
```bash
pip install --upgrade requests==2.31.0
```

### Step 2: Review Integration
Check `src/api/client.py` for deprecated patterns (none in this case)

### Step 3: Optional - Use New Features
```python
# Enhanced JSON handling (new in 2.31.0)
response = self.session.get(url)
data = response.json()  # Now with better error messages
```

## Rollback Plan
If issues occur:
```bash
pip install requests==2.28.0
cp src/api/client.py.backup src/api/client.py
```

## Validation
```python
import requests
assert requests.__version__ == "2.31.0"
print("✓ Update successful")

# Test integration
from src.api.client import APIClient
client = APIClient()
response = client.get('https://httpbin.org/get')
assert response.status_code == 200
client.close()
```
```

**Q: What abstract steps should ae_update.md include?**

1. Compare current and target library versions
2. Backup existing configurations and data
3. Apply migration or upgrade procedures
4. Handle breaking changes (API updates, removed features)
5. Re-integrate updated components with new patterns
6. Validate post-update functionality
7. Provide rollback options if issues occur

---

## 📝 Generating ae_use.md (Usage File)

**Q: How do I create ae_use.md?**

**Goal**: Create a usage rule for the library that AI agents can reference frequently.

**Process**:

1. **Analyze Documentation** for common patterns
2. **Identify Use Cases** (basic → advanced)
3. **Extract Best Practices**
4. **Document Anti-patterns**
5. **Provide Code Examples**

**Structure**:

```markdown
# <Library Name> Usage Guide

## Basic Usage
### Simple HTTP GET Request
```python
import requests

response = requests.get('https://api.example.com/data')
if response.status_code == 200:
    data = response.json()
```

## Advanced Usage
### Session with Retry Strategy
```python
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

session = requests.Session()
retry = Retry(total=3, backoff_factor=0.3)
adapter = HTTPAdapter(max_retries=retry)
session.mount('http://', adapter)
session.mount('https://', adapter)

response = session.get('https://api.example.com/data')
```

## Best Practices
- Use Session objects for connection pooling
- Set timeouts on all requests: `requests.get(url, timeout=5)`
- Handle exceptions: `requests.exceptions.RequestException`
- Close sessions: `session.close()` or use context manager

## Anti-patterns
- ✗ No timeout (can hang indefinitely)
- ✗ Ignoring status codes
- ✗ Not handling exceptions
- ✗ Making many requests without Session (slow)
```

**Q: Should I create a usage rule file (e.g., `{library_name}_usage.mdc`)?**

**During ae_use.md creation**: Include guidance that agents should prompt user for placement path.

Example note in ae_use.md:

```markdown
## Usage Rule Integration
This library's usage patterns can be integrated as an AI agent rule.

**For Cursor AI users:**
- Copy this content to `.cursor/rules/requests_usage.mdc`
- AI agent will reference patterns during development

**For other AI agents:**
- Prompt user for preferred rule location
- Adapt filename to agent conventions
```

---

## 🔄 Update Workflow

**Q: How do I update existing AE files?**

### Step 1: Diff Analysis

```markdown
**Process:**
1. Review library changes since last AE update:
   - New features added
   - APIs deprecated or removed
   - Configuration options changed
   - Dependencies updated

2. Check library changelog/release notes

3. Compare current codebase vs documentation in AE files
```

### Step 2: Update Affected Files

```markdown
**Decision Matrix:**

Change Type                → Files to Update
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
New feature                → ae_install.md (integration)
                           → ae_use.md (usage patterns)

Deprecated API             → ae_use.md (update examples)
                           → ae_update.md (migration steps)

New dependency             → ae_install.md (prerequisites)
                           → ae_uninstall.md (removal steps)

Config option changed      → ae_install.md (configuration)

Breaking change            → ae_update.md (migration guide)
                           → ae_use.md (new patterns)
```

### Step 3: Update File Sections

```markdown
**Example:**
Library added new async support (breaking feature)

**Update ae_install.md:**
Add to Integration section:
```python
# New: Async support
import asyncio
from library import AsyncClient

async def fetch_data():
    async with AsyncClient() as client:
        return await client.get('https://api.example.com')
```

**Update ae_use.md:**
Add to Advanced Usage section:
```markdown
## Async Usage (v2.0+)
```python
import asyncio
from library import AsyncClient

async def main():
    async with AsyncClient() as client:
        response = await client.get(url)
        return response.json()

data = asyncio.run(main())
```

**Update ae_update.md:**
Add migration from v1 to v2:
```markdown
## Migrating to Async API (v1.x → v2.0)
### Old (v1.x):
```python
from library import Client
client = Client()
response = client.get(url)
```

### New (v2.0):
```python
import asyncio
from library import AsyncClient

async def fetch():
    async with AsyncClient() as client:
        return await client.get(url)

response = asyncio.run(fetch())
```
```

### Step 4: Validate Changes

```markdown
**Validation Checklist:**
- [ ] All 6 core principles still addressed (see ae_context.md)
- [ ] File LOC still <500 (or justified if larger)
- [ ] Metadata updated (increment version)
- [ ] New validation steps added for new features
- [ ] Reversibility maintained (install/uninstall still inverses)
- [ ] Integration points updated
- [ ] Code examples tested

**Tools:**
- Use `verify_ae_implementation` tool
- Use `evaluate_ae_compliance` tool
```

### Step 5: Update Metadata

```markdown
**In all updated files:**
<!--
version: 1.1.0  ← Increment from 1.0.0
repository: https://github.com/owner/repo
license: MIT
author: Name and contributors
last_updated: 2026-01-18  ← Add date
-->
```

---

## ✅ Validation Phase

**Q: How do I validate AE files before publishing?**

### Manual Checklist

```markdown
## Core Principles (from ae_context.md)
- [ ] Agent Empowerment: Sufficient context for autonomous execution?
- [ ] Modularity: Clear, reusable steps?
- [ ] Contextual Awareness: Domain knowledge included?
- [ ] Reversibility: Clean uninstall tested?
- [ ] Validation: Verification steps in each file?
- [ ] Documentation Focus: Concise, agent-readable?

## File Structure
- [ ] ae_install.md has: Prerequisites, Installation, Configuration, Integration, Validation
- [ ] ae_uninstall.md has: Prerequisites, Uninstallation Steps, Validation
- [ ] ae_update.md has: Prerequisites, Update Steps, Rollback, Validation
- [ ] ae_use.md has: Basic Usage, Advanced Usage, Best Practices, Anti-patterns

## Quality Standards
- [ ] File LOC <500 (or <800 with justification)
- [ ] Metadata complete (version, repo, license, author)
- [ ] Code examples provided
- [ ] Validation steps executable
- [ ] Integration points clear

## Testing
- [ ] Simulate agent execution mentally
- [ ] Check reversibility: install → uninstall → original state
- [ ] Verify all code examples are syntactically valid
```

### Automated Validation

**Q: What tools help with validation?**

1. **verify_ae_implementation**: Generates checklist, pass/fail results

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

2. **evaluate_ae_compliance**: Scores compliance, provides recommendations

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

Returns: Overall score (PASS/WARNING/FAIL), LOC scoring, principle scores, actionable recommendations.

---

## 🎨 Best Practices

**Q: How do I write agent-friendly instructions?**

**DO:**
- ✓ Use imperative voice: "Install dependencies"
- ✓ Provide concrete examples: `pip install requests`
- ✓ Include validation: "Verify by running `import requests`"
- ✓ Structure with headings: `## Installation Steps`
- ✓ Use code blocks with language tags
- ✓ Number sequential steps clearly
- ✓ Explain WHY for complex decisions

**DON'T:**
- ✗ Use passive voice: "Dependencies should be installed"
- ✗ Be vague: "Set up the library"
- ✗ Skip validation: No way to verify success
- ✗ Wall of text without structure
- ✗ Assume context agents don't have
- ✗ Use ambiguous pronouns: "it", "that", "this"

**Q: How do I handle library-specific complexity?**

**Strategy 1: Modular Breakdown**

If library has >5 integration points:
```markdown
## Integration
### Core Integration
(Essential setup - must do)

### Optional Integrations
#### Feature A Integration
(If using feature A)

#### Feature B Integration
(If using feature B)
```

**Strategy 2: Decision Trees**

If library has multiple setup paths:
```markdown
## Configuration
### Determine Configuration Approach

**If using cloud deployment:**
1. Set env vars: `API_KEY`, `API_SECRET`
2. Use cloud config service

**If using local development:**
1. Create `.env` file
2. Use local config file: `config.yaml`

**If using Docker:**
1. Use Docker secrets
2. Mount config volume
```

**Strategy 3: Nested Checklists**

For complex validation:
```markdown
## Validation
### Prerequisites Check
- [ ] Python version >= 3.7
- [ ] pip installed
- [ ] Network access to pypi.org

### Installation Check
- [ ] Package installed: `pip show requests`
- [ ] Version correct: `requests.__version__ >= "2.28.0"`
- [ ] Dependencies installed: `pip show urllib3`

### Integration Check
- [ ] Module importable: `from src.api.client import APIClient`
- [ ] Client instantiable: `client = APIClient()`
- [ ] Connection works: `client.get('https://httpbin.org/get')`
- [ ] Cleanup works: `client.close()`
```

**Strategy 4: Troubleshooting Section**

For error-prone setups:
```markdown
## Troubleshooting
### Issue: SSL Certificate Error
**Symptom:** `SSLError: certificate verify failed`
**Solution:**
```bash
export REQUESTS_CA_BUNDLE=/path/to/certfile
# Or
pip install --upgrade certifi
```

### Issue: Connection Timeout
**Symptom:** `Timeout: No response from server`
**Solution:** Increase timeout parameter:
```python
response = requests.get(url, timeout=30)  # 30 seconds
```
```

**Q: How do I maintain consistency across libraries?**

Follow template structures from `ae_context.md` → 🧬 Pattern Library section:

1. **Same section headings** across all libraries
2. **Same validation pattern** (import → version check → functional test)
3. **Same integration structure** (create module → initialize → bridge → cleanup)
4. **Same metadata format** (YAML frontmatter)

**Consistency Checklist:**
- [ ] Section headings match template
- [ ] Code blocks use language tags
- [ ] Validation follows 3-step pattern
- [ ] Metadata complete and formatted identically

---

## 📚 Quick Reference

**Q: What's the TL;DR workflow?**

```markdown
Library Maintainer Quick Flow:

1. Read ae_context.md (principles)
2. Analyze codebase (dependencies, integration points, config)
3. Create ae_install.md (6-step pattern: deps → config → integrate → bridge → cleanup → validate)
4. Create ae_uninstall.md (reverse ae_install.md)
5. Create ae_update.md (version transitions + rollback)
6. Create ae_use.md (basic → advanced + best practices + anti-patterns)
7. Validate (manual checklist + tools)
8. Update metadata (version 1.0.0)
9. Submit to registry
```

**Q: Where can I find examples?**

- Registry: https://github.com/fluent-meaning-symbiotic/agentic_executables_registry/tree/main/ae_use_registry
- Local examples: `ae_use_registry/` directory
- Templates: `ae_context.md` → 🧬 Pattern Library

**Q: What if I get stuck?**

1. Check `ae_context.md` for principles
2. Review existing AE files in registry for patterns
3. Use validation tools for guidance
4. Break complex setups into smaller modules
5. Focus on one lifecycle stage at a time (install → uninstall → update → use)
