# Getting Started with Prompts Framework MCP Server

Welcome! This guide will help you get the MCP server running in minutes.

## What is This?

The Prompts Framework MCP Server is a **strategic thinking tool** for AI agents. It provides guidance on how to manage libraries using the Agentic Executables (AE) framework - a language-agnostic approach to library management.

### Key Features

- 🌐 **Language Agnostic**: Works with any programming language
- 🤖 **AI-First**: Designed for AI agents, not direct human use
- 📋 **Strategic Guidance**: Provides HOW-TO, not direct execution
- ✅ **Principle-Based**: Validates against 6 core AE principles
- 🔧 **Three Tools**: Instructions, Verification, Evaluation

## Prerequisites

Just one requirement:

- **Dart SDK 3.0+** ([Install here](https://dart.dev/get-dart))

Optional:

- Docker (for containerized deployment)
- MCP-compatible client (Claude Desktop, custom client, etc.)

## Installation (30 seconds)

```bash
cd prompts_framework_mcp
./build.sh
```

That's it! The binary is now at `build/server`.

## Usage

### Option 1: With Claude Desktop (Recommended)

1. Find your Claude config file:

   - macOS: `~/Library/Application Support/Claude/claude_desktop_config.json`
   - Windows: `%APPDATA%/Claude/claude_desktop_config.json`

2. Add this configuration:

   ```json
   {
     "mcpServers": {
       "prompts-framework": {
         "command": "/absolute/path/to/prompts_framework_mcp/build/server"
       }
     }
   }
   ```

3. Restart Claude Desktop

4. The tools are now available! Try asking:
   > "Use the prompts-framework MCP to get instructions for bootstrapping AE files in my library"

### Option 2: Direct Execution

```bash
# Run the server (it listens on STDIO)
./build/server

# It will wait for JSON-RPC 2.0 commands via stdin
```

### Option 3: Docker

```bash
docker build -t prompts-framework-mcp:latest .
docker run -i prompts-framework-mcp:latest
```

## The Three Tools

### 1. get_ae_instructions

**Purpose**: Get the right documentation for your task

**Use when**: You need to know HOW to do something with AE

**Example**:

```json
{
  "context_type": "library",
  "action": "bootstrap"
}
```

**Returns**: Relevant .md documentation with step-by-step guidance

### 2. verify_ae_implementation

**Purpose**: Check if your implementation follows AE principles

**Use when**: You've created AE files and want to verify quality

**Example**:

```json
{
  "context_type": "library",
  "action": "bootstrap",
  "description": "Created ae_install.md with modular installation steps"
}
```

**Returns**: Checklist of items to verify

### 3. evaluate_ae_compliance

**Purpose**: Get a compliance score with recommendations

**Use when**: You want detailed feedback on your implementation

**Example**:

```json
{
  "implementation_details": "Created comprehensive installation guide...",
  "context_type": "library"
}
```

**Returns**: Score (0-100), principle-by-principle breakdown, recommendations

## Real-World Example

Let's say you're creating AE files for the `axios` library:

```
You (to AI): "I need to bootstrap AE for the axios library"

AI → MCP: get_ae_instructions(library, bootstrap)
MCP → AI: [Returns ae_bootstrap.md + ae_context.md]

AI: [Analyzes axios codebase]
AI: [Creates ae_install.md, ae_uninstall.md, ae_update.md]
AI: "I've created the files. Here's my plan..."

You: "Looks good, proceed"

AI → MCP: verify_ae_implementation(library, bootstrap, "Created files...")
MCP → AI: [Returns checklist]

AI: [Reviews checklist]
AI → MCP: evaluate_ae_compliance(library, "Detailed description...")
MCP → AI: [Returns score: 85/100 with recommendations]

AI: "Implementation complete! Score: 85/100. Applied all recommendations."
```

## Understanding the Context Types

### "library" context

Use when you're the **library maintainer** creating/maintaining AE files

**Actions**:

- `bootstrap`: Create AE files for your library
- `update`: Update AE files for new version

### "project" context

Use when you're a **library user** integrating a library into your project

**Actions**:

- `install`: Install library as AE
- `uninstall`: Remove library
- `update`: Update library version
- `use`: Apply library features

## Common Workflows

### Bootstrap Workflow (Library Maintainers)

```
1. get_ae_instructions (library, bootstrap)
2. [Create AE files]
3. verify_ae_implementation
4. evaluate_ae_compliance
5. [Apply recommendations]
6. Done!
```

### Installation Workflow (Library Users)

```
1. get_ae_instructions (project, install)
2. [Follow installation steps]
3. verify_ae_implementation
4. get_ae_instructions (project, use)
5. [Use library features]
```

## Troubleshooting

### "Server won't start"

- Check Dart: `dart --version`
- Rebuild: `./build.sh`
- Check resources exist: `ls resources/`

### "Tools not showing in Claude"

- Verify absolute path in config
- Restart Claude completely
- Check server runs: `./build/server` (should wait for input)

### "Getting error responses"

- Check parameter names match exactly
- Verify enum values (library/project, bootstrap/install/etc)
- All parameters are strings

## Tips for AI Agents

1. **Always start with get_ae_instructions** - Don't guess the workflow
2. **Present plans before executing** - Humans approve changes
3. **Use verify before finalizing** - Catch issues early
4. **Evaluate for quality** - Ensure high standards
5. **Follow modularity** - Break tasks into steps
6. **Include validation** - Always verify success
7. **Ensure reversibility** - Provide uninstall/rollback

## Next Steps

- ✅ Server is built and ready
- ✅ Documentation is complete
- ✅ Tests are passing

**Now**: Integrate with your AI agent/client and start using it!

**Later**: Consider these enhancements:

- Add custom evaluation criteria
- Extend with library-specific guidance
- Create organization-specific AE principles
- Build web UI for testing

## Need Help?

1. Read the full [README.md](README.md)
2. Check [example/usage_example.md](example/usage_example.md)
3. Review [PROJECT_STATUS.md](PROJECT_STATUS.md)
4. Look at [example/mcp_config_examples.json](example/mcp_config_examples.json)

## Quick Reference

| File                | Purpose                       |
| ------------------- | ----------------------------- |
| `build/server`      | Compiled binary (run this)    |
| `build.sh`          | Build script (run to rebuild) |
| `README.md`         | Full documentation            |
| `QUICKSTART.md`     | Quick reference               |
| `PROJECT_STATUS.md` | Implementation status         |
| `resources/*.md`    | AE framework documentation    |
| `example/`          | Usage examples and configs    |

---

**You're ready to go! 🚀**

Start by integrating with your AI agent and trying the tools. The server will guide the agent through proper AE management for any library in any language.
