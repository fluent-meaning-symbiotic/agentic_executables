# Quick Start Guide

Get up and running with the Prompts Framework MCP Server in minutes.

## Prerequisites

- Dart SDK 3.0 or higher
- (Optional) Docker for containerized deployment

## Installation

### Development Mode

```bash
# Clone or navigate to the package
cd prompts_framework_mcp

# Install dependencies
dart pub get

# Run directly
dart run bin/prompts_framework_mcp_server.dart
```

### Production Build

```bash
# Compile to native binary
dart compile exe bin/prompts_framework_mcp_server.dart -o build/server

# Run the binary
./build/server
```

### Docker Deployment

```bash
# Build Docker image
docker build -t prompts-framework-mcp:latest .

# Run container (interactive mode for STDIO)
docker run -i prompts-framework-mcp:latest
```

## Testing

```bash
# Run tests
dart test

# Run analysis
dart analyze

# Format code
dart format .
```

## Basic Usage

### With MCP-Compatible Client

The server implements the Model Context Protocol and can be used with any MCP-compatible client.

### Example: Claude Desktop

1. Add to your `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "prompts-framework": {
      "command": "/absolute/path/to/build/server"
    }
  }
}
```

2. Restart Claude Desktop

3. The tools will be available in your conversations:
   - `get_ae_instructions`
   - `verify_ae_implementation`
   - `evaluate_ae_compliance`

### Available Tools

#### 1. get_ae_instructions

Get AE framework guidance based on context and action.

**Parameters:**

- `context_type`: `"library"` or `"project"`
- `action`: `"bootstrap"`, `"install"`, `"uninstall"`, `"update"`, or `"use"`

**Example:**

```json
{
  "context_type": "library",
  "action": "bootstrap"
}
```

#### 2. verify_ae_implementation

Generate a verification checklist for your implementation.

**Parameters:**

- `context_type`: `"library"` or `"project"`
- `action`: Same as above
- `description`: Brief description of what was implemented

**Example:**

```json
{
  "context_type": "project",
  "action": "install",
  "description": "Installed go_router with route configuration and navigation setup"
}
```

#### 3. evaluate_ae_compliance

Evaluate implementation compliance with AE principles.

**Parameters:**

- `implementation_details`: Detailed description of implementation
- `context_type`: `"library"` or `"project"`

**Example:**

```json
{
  "implementation_details": "Created modular installation instructions with validation checks...",
  "context_type": "library"
}
```

## Common Workflows

### For Library Maintainers

```bash
# 1. Get bootstrap instructions
Call: get_ae_instructions (library, bootstrap)

# 2. Create AE files following the guidance

# 3. Verify your implementation
Call: verify_ae_implementation (library, bootstrap, "Created AE files...")

# 4. Evaluate compliance
Call: evaluate_ae_compliance (library, "Detailed description...")
```

### For Library Users

```bash
# 1. Get installation instructions
Call: get_ae_instructions (project, install)

# 2. Follow the installation workflow

# 3. Verify installation
Call: verify_ae_implementation (project, install, "Installed library...")

# 4. Get usage guidance
Call: get_ae_instructions (project, use)
```

## Troubleshooting

### Server won't start

- Check that Dart SDK is installed: `dart --version`
- Verify dependencies are installed: `dart pub get`
- Check resources directory exists and contains .md files

### Resources not found

The server looks for resources in these locations (in order):

1. `../resources` (relative to compiled binary)
2. `resources/` (in current directory)
3. Relative to the script location

Make sure your `.md` files are in one of these paths.

### Docker build fails

- Ensure you're in the project root directory
- Check that all files are present (especially `resources/*.md`)
- Verify Docker is running: `docker --version`

## Next Steps

- Read the full [README.md](README.md) for detailed information
- Check [example/usage_example.md](example/usage_example.md) for practical examples
- Review the [AE framework documentation](resources/) to understand the principles
- Integrate with your preferred AI agent/client

## Support

For issues, questions, or contributions:

- Check existing documentation
- Review the test suite for examples
- Consult the AE framework principles in `resources/ae_context.md`

## License

BSD-3-Clause (see LICENSE file)
