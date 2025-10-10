# Usage Examples

This document provides practical examples of using the Prompts Framework MCP Server.

## Example 1: Bootstrapping AE for a Library

**Scenario**: A developer wants to create AE files for the `axios` JavaScript library.

**AI Agent Query**:

```json
{
  "tool": "get_ae_instructions",
  "arguments": {
    "context_type": "library",
    "action": "bootstrap"
  }
}
```

**Response**:
The MCP server returns `ae_bootstrap.md` and `ae_context.md` content, providing:

- Workflow for analyzing the codebase
- Instructions for generating `ae_install.md`, `ae_uninstall.md`, `ae_update.md`
- Guidance on creating usage rules
- Core AE principles

**AI Agent Actions**:

1. Analyzes axios codebase structure
2. Creates modular installation instructions
3. Generates uninstallation procedures
4. Produces a plan for developer approval
5. Executes after confirmation

## Example 2: Installing Library as AE

**Scenario**: A developer wants to use `go_router` as an AE in their Flutter project.

**AI Agent Query**:

```json
{
  "tool": "get_ae_instructions",
  "arguments": {
    "context_type": "project",
    "action": "install"
  }
}
```

**Response**:
Returns `ae_use.md` and `ae_context.md`, providing:

- Usage workflow for project integration
- Instructions for fetching and executing `ae_install.md`
- Validation and error handling guidelines
- Adaptation strategies for project fit

**AI Agent Actions**:

1. Locates `ae_install.md` in go_router's AE files
2. Follows installation steps
3. Configures router settings
4. Integrates with existing navigation
5. Validates successful installation

## Example 3: Verifying Implementation

**Scenario**: After bootstrapping AE files, verify compliance with AE principles.

**AI Agent Query**:

```json
{
  "tool": "verify_ae_implementation",
  "arguments": {
    "context_type": "library",
    "action": "bootstrap",
    "description": "Created ae_install.md with dependency setup, configuration steps, and integration instructions. Included validation checks and rollback procedures."
  }
}
```

**Response**:

```json
{
  "success": true,
  "verification_checklist": [
    {
      "principle": "Modularity",
      "check": "Are instructions structured in clear, reusable steps?",
      "critical": true
    },
    {
      "principle": "Agent Empowerment",
      "check": "Can AI agents autonomously execute these instructions?",
      "critical": true
    },
    ...
  ]
}
```

**AI Agent Actions**:

1. Reviews each checklist item
2. Confirms all critical items are addressed
3. Makes improvements where needed
4. Reports verification status to developer

## Example 4: Evaluating Compliance

**Scenario**: Evaluate the quality of created AE files.

**AI Agent Query**:

```json
{
  "tool": "evaluate_ae_compliance",
  "arguments": {
    "context_type": "library",
    "implementation_details": "Created comprehensive ae_install.md with:\n- Step-by-step dependency installation using package manager\n- Configuration file generation with defaults\n- Service initialization and integration points\n- Validation checks at each step\n- Clear rollback procedures\n- Modular structure allowing independent execution\n- Domain context for agent understanding"
  }
}
```

**Response**:

```json
{
  "success": true,
  "evaluation": {
    "overall_score": 85,
    "overall_rating": "Highly Compliant",
    "principle_scores": [
      {
        "principle": "Agent Empowerment",
        "score": 80,
        "weight": 20,
        "assessment": "Excellent"
      },
      {
        "principle": "Modularity",
        "score": 100,
        "weight": 20,
        "assessment": "Excellent"
      },
      ...
    ],
    "recommendations": [
      "Implementation shows good compliance with AE principles. Continue following these patterns."
    ]
  }
}
```

**AI Agent Actions**:

1. Reviews scores for each principle
2. Identifies areas needing improvement
3. Applies recommendations
4. Re-evaluates if score is below threshold
5. Reports final compliance status

## Integration with AI Agents

### Claude Desktop Configuration

Add to your Claude Desktop MCP config:

```json
{
  "mcpServers": {
    "prompts-framework": {
      "command": "/path/to/agentic_executables_mcp/build/server"
    }
  }
}
```

### Programmatic Usage

```dart
import 'package:dart_mcp/client.dart';
import 'package:dart_mcp/stdio.dart';

void main() async {
  final client = MCPClient();

  // Connect to server
  final connection = await client.connectStdioServer(
    'dart',
    ['run', 'agentic_executables_mcp:agentic_executables_mcp_server'],
  );

  // Initialize
  await connection.initialize(...);
  await connection.notifyInitialized();

  // Call tool
  final result = await connection.callTool(
    'get_ae_instructions',
    {'context_type': 'library', 'action': 'bootstrap'},
  );

  print(result);
}
```

## Common Patterns

### Pattern 1: Bootstrap → Verify → Evaluate

```
1. get_ae_instructions (library, bootstrap)
2. [Agent creates AE files]
3. verify_ae_implementation (library, bootstrap, [description])
4. [Agent reviews checklist]
5. evaluate_ae_compliance (library, [implementation_details])
6. [Agent applies recommendations if needed]
```

### Pattern 2: Install → Use

```
1. get_ae_instructions (project, install)
2. [Agent follows ae_install.md]
3. verify_ae_implementation (project, install, [description])
4. get_ae_instructions (project, use)
5. [Agent applies library features]
```

### Pattern 3: Update Workflow

```
1. get_ae_instructions (project, update)
2. [Agent follows ae_update.md]
3. verify_ae_implementation (project, update, [description])
4. [Agent validates post-update functionality]
```

## Tips for AI Agents

1. **Always start with get_ae_instructions** to understand the workflow
2. **Use verify_ae_implementation** before finalizing any changes
3. **Run evaluate_ae_compliance** to ensure quality standards
4. **Present plans to developers** before executing changes
5. **Follow the modularity principle** - break down complex tasks
6. **Include validation steps** in all implementations
7. **Ensure reversibility** for installation/configuration actions
8. **Provide context** in descriptions for better guidance
