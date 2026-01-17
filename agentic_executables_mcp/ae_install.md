<!--
version: 1.0.0
library: agentic_executables_mcp
repository: https://github.com/fluent-meaning-symbiotic/agentic_executables
license: MIT
author: Arenukvern and contributors
-->

# Prompts Framework MCP Server Installation

Agentic Executable for installing the Prompts Framework MCP Server.

## Context

The Agentic Executables MCP Server provides strategic guidance for AI agents managing Agentic Executables (AE) - a framework-agnostic approach to library management. This server enables AI agents to bootstrap, install, uninstall, update, and use libraries as Agentic Executables across any programming language or framework.

**Domain Knowledge:**
- MCP (Model Context Protocol) provides standardized interface for AI agent interactions
- MCP servers communicate via STDIO and connect at client startup
- Configuration format varies by MCP client (Cursor, Claude Desktop, VSCode, etc.)
- Server must be accessible via absolute path in MCP client configuration

## Setup

### Prerequisites

Check requirements:

```bash
# Git 2.0+
git --version

# Dart SDK 3.0+ (for building from source)
dart --version

# Disk space: ~100MB (repo 5MB + deps 50MB + build 20MB)
df -h .
```

**Network required for**: git clone, pub get, registry operations.

### Repository Setup

**Choose Installation Location:**

Decide where to clone the repository. Common locations:
- `~/mcp/` - Dedicated MCP servers directory
- `~/projects/` - General projects directory
- `~/.local/share/` - User-local applications (Linux)
- Any custom location you prefer

**Clone from GitHub:**

```bash
# Set your preferred installation directory
INSTALL_DIR="${INSTALL_DIR:-$HOME/mcp}"  # Default: ~/mcp, override with INSTALL_DIR=/custom/path

# Create directory if needed
mkdir -p "$INSTALL_DIR"

# Clone and navigate
cd "$INSTALL_DIR"
git clone https://github.com/fluent-meaning-symbiotic/agentic_executables.git
cd agentic_executables/agentic_executables_mcp

# Get absolute path for later use
REPO_PATH="$(pwd)"
echo "Repository installed at: $REPO_PATH"

# Validate
test -f pubspec.yaml && echo "✓ Ready" || echo "✗ Failed"
```

**If Already Cloned:**

```bash
# Navigate to existing installation
cd /path/to/agentic_executables/agentic_executables_mcp

# Update repository
git pull origin main

# Get absolute path
REPO_PATH="$(pwd)"
echo "Repository at: $REPO_PATH"
```

### Installation Steps

**Step 1: Install Dependencies**

```bash
dart pub get

# Validate
test -f pubspec.lock && test -d .dart_tool && echo "✓ Done" || echo "✗ Failed"
```

**Step 2: Build Native Binary**

```bash
# Using build script (recommended)
./build.sh

# Or manual
dart compile exe bin/agentic_executables_mcp_server.dart -o build/server

# Validate
ls -lh build/server
# Expected: ~15-20MB executable
```

**Step 3: Test Server**

```bash
timeout 3s ./build/server || echo "✓ Server OK"
```

Server should wait for input (not exit immediately).

### Alternative Setup Methods

**Docker** (no Dart SDK needed):

```bash
docker build -t prompts-framework-mcp .
docker run -i prompts-framework-mcp
```

**Dev mode** (no compilation, requires Dart SDK):

```bash
dart run bin/agentic_executables_mcp_server.dart
```

Note: Dev mode has slower startup (~2s) but no build step required.

## Config

### Get Absolute Server Path

```bash
# Get absolute path (run from agentic_executables_mcp directory)
SERVER_PATH="$(pwd)/build/server"
echo "$SERVER_PATH"

# Validate
test -f "$SERVER_PATH" && echo "✓ Valid" || echo "✗ Invalid"
```

**Important**: Use absolute paths only, not relative (`./`) or home (`~/`).

### Detect MCP Client Configuration

Before configuring, detect your MCP client's config file location:

```bash
# Detect Cursor config (check both possible locations)
if [ -f "$HOME/.cursor/mcp.json" ]; then
  CURSOR_CONFIG="$HOME/.cursor/mcp.json"
elif [ -f "$HOME/Library/Application Support/Cursor/User/globalStorage/mcp.json" ]; then
  CURSOR_CONFIG="$HOME/Library/Application Support/Cursor/User/globalStorage/mcp.json"
else
  CURSOR_CONFIG=""
fi

# Detect Claude Desktop config
if [ -f "$HOME/Library/Application Support/Claude/claude_desktop_config.json" ]; then
  CLAUDE_CONFIG="$HOME/Library/Application Support/Claude/claude_desktop_config.json"
elif [ -f "$HOME/.config/Claude/claude_desktop_config.json" ]; then
  CLAUDE_CONFIG="$HOME/.config/Claude/claude_desktop_config.json"
else
  CLAUDE_CONFIG=""
fi

# Report findings
echo "Cursor config: ${CURSOR_CONFIG:-Not found}"
echo "Claude Desktop config: ${CLAUDE_CONFIG:-Not found}"
```

### MCP Client Configuration

**⚠️ CRITICAL**: Always backup existing config files before modifying. They may contain other MCP servers.

```bash
# Backup existing config (replace CONFIG_FILE with your actual path)
CONFIG_FILE="<your-config-path>"
if [ -f "$CONFIG_FILE" ]; then
  cp "$CONFIG_FILE" "${CONFIG_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
  echo "✓ Backup created"
fi
```

The MCP server works with any MCP-compatible client. Configure your IDE/tool below:

#### Cursor IDE

**Config Locations (check both):**
- Primary: `~/.cursor/mcp.json` (most common)
- Alternative: `~/Library/Application Support/Cursor/User/globalStorage/mcp.json` (macOS)
- Windows: `%APPDATA%\Cursor\User\globalStorage\mcp.json`
- Linux: `~/.config/Cursor/User/globalStorage/mcp.json`

**Detect and Configure:**

```bash
# Detect Cursor config location
if [ -f "$HOME/.cursor/mcp.json" ]; then
  CONFIG_FILE="$HOME/.cursor/mcp.json"
elif [ -f "$HOME/Library/Application Support/Cursor/User/globalStorage/mcp.json" ]; then
  CONFIG_FILE="$HOME/Library/Application Support/Cursor/User/globalStorage/mcp.json"
else
  # Create directory if needed
  mkdir -p "$HOME/.cursor"
  CONFIG_FILE="$HOME/.cursor/mcp.json"
fi

# Backup existing config
if [ -f "$CONFIG_FILE" ]; then
  cp "$CONFIG_FILE" "${CONFIG_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
fi

# Set server path (update this to your actual path)
SERVER_PATH="/absolute/path/to/agentic_executables_mcp/build/server"

# Merge configuration safely (preserves existing servers)
python3 << EOF
import json
import sys
from pathlib import Path

config_file = Path("$CONFIG_FILE")
server_path = "$SERVER_PATH"

# Load existing config or create new
if config_file.exists():
    with open(config_file, 'r') as f:
        config = json.load(f)
else:
    config = {}

# Ensure mcpServers exists
if "mcpServers" not in config:
    config["mcpServers"] = {}

# Add agentic_executables server (only if not exists or update if needed)
config["mcpServers"]["agentic_executables"] = {
    "command": server_path
}

# Write back
with open(config_file, 'w') as f:
    json.dump(config, f, indent=2)

print(f"✓ Configuration updated: {config_file}")
print(f"✓ Server entry added/updated: agentic_executables")
EOF

echo "✓ Cursor config updated at: $CONFIG_FILE"
```

**Manual Configuration** (if script doesn't work):

If your `mcp.json` already exists with other servers, manually merge:

```json
{
  "mcpServers": {
    "existing_server_1": {
      "command": "/path/to/existing/server1"
    },
    "existing_server_2": {
      "command": "/path/to/existing/server2"
    },
    "agentic_executables": {
      "command": "/absolute/path/to/agentic_executables_mcp/build/server"
    }
  }
}
```

**Restart**: Complete quit (Cmd+Q / Alt+F4) and relaunch Cursor.

#### Claude Desktop

**Config Locations:**
- macOS: `~/Library/Application Support/Claude/claude_desktop_config.json`
- Windows: `%APPDATA%\Claude\claude_desktop_config.json`
- Linux: `~/.config/Claude/claude_desktop_config.json`

**Detect and Configure:**

```bash
# Detect Claude Desktop config location
if [ -f "$HOME/Library/Application Support/Claude/claude_desktop_config.json" ]; then
  CONFIG_FILE="$HOME/Library/Application Support/Claude/claude_desktop_config.json"
elif [ -f "$HOME/.config/Claude/claude_desktop_config.json" ]; then
  CONFIG_FILE="$HOME/.config/Claude/claude_desktop_config.json"
else
  mkdir -p "$HOME/Library/Application Support/Claude"
  CONFIG_FILE="$HOME/Library/Application Support/Claude/claude_desktop_config.json"
fi

# Backup existing config
if [ -f "$CONFIG_FILE" ]; then
  cp "$CONFIG_FILE" "${CONFIG_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
fi

# Set server path (update this to your actual path)
SERVER_PATH="/absolute/path/to/agentic_executables_mcp/build/server"

# Merge configuration safely (preserves existing servers)
python3 << EOF
import json
import sys
from pathlib import Path

config_file = Path("$CONFIG_FILE")
server_path = "$SERVER_PATH"

# Load existing config or create new
if config_file.exists():
    with open(config_file, 'r') as f:
        config = json.load(f)
else:
    config = {}

# Ensure mcpServers exists
if "mcpServers" not in config:
    config["mcpServers"] = {}

# Add agentic_executables server (only if not exists or update if needed)
config["mcpServers"]["agentic_executables"] = {
    "command": server_path
}

# Write back
with open(config_file, 'w') as f:
    json.dump(config, f, indent=2)

print(f"✓ Configuration updated: {config_file}")
print(f"✓ Server entry added/updated: agentic_executables")
EOF

echo "✓ Claude Desktop config updated at: $CONFIG_FILE"
```

**Manual Configuration** (if script doesn't work):

If your `claude_desktop_config.json` already exists with other servers, manually merge:

```json
{
  "mcpServers": {
    "existing_server_1": {
      "command": "/path/to/existing/server1"
    },
    "agentic_executables": {
      "command": "/absolute/path/to/agentic_executables_mcp/build/server"
    }
  }
}
```

**Restart**: Complete quit (Cmd+Q / Alt+F4) and relaunch Claude Desktop.

#### VSCode (with MCP Extension)

**Config Location:** VSCode settings.json or MCP extension config

**Configuration:**
```json
{
  "mcp.servers": {
    "agentic_executables": {
      "command": "/absolute/path/to/agentic_executables_mcp/build/server"
    }
  }
}
```

**Restart**: Reload VSCode window (Cmd+Shift+P → "Reload Window").

#### Generic MCP Client

For any MCP-compatible client, safely merge into existing configuration:

```bash
# Set your config file path and server path
CONFIG_FILE="<path-to-your-mcp-config.json>"
SERVER_PATH="/absolute/path/to/agentic_executables_mcp/build/server"

# Backup existing config
if [ -f "$CONFIG_FILE" ]; then
  cp "$CONFIG_FILE" "${CONFIG_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
fi

# Merge configuration safely
python3 << EOF
import json
import sys
from pathlib import Path

config_file = Path("$CONFIG_FILE")
server_path = "$SERVER_PATH"

# Load existing config or create new
if config_file.exists():
    with open(config_file, 'r') as f:
        config = json.load(f)
else:
    config = {}

# Ensure mcpServers exists (adjust key name if your client uses different format)
if "mcpServers" not in config:
    config["mcpServers"] = {}

# Add agentic_executables server
config["mcpServers"]["agentic_executables"] = {
    "command": server_path
}

# Write back
with open(config_file, 'w') as f:
    json.dump(config, f, indent=2)

print(f"✓ Configuration updated: {config_file}")
EOF
```

**Note**: Configuration format may vary by client. Check your client's MCP documentation for exact format. Common variations:
- `mcpServers` (most common)
- `mcp.servers` (VSCode extension)
- `mcp.servers` nested structure

Always preserve existing server entries when merging.

#### Docker Configuration

For Docker setup, use:

```json
{
  "mcpServers": {
    "agentic_executables": {
      "command": "docker",
      "args": ["run", "-i", "prompts-framework-mcp"]
    }
  }
}
```

#### Dev Mode Configuration

For dev mode (Dart source), use:

```json
{
  "mcpServers": {
    "agentic_executables": {
      "command": "dart",
      "args": ["run", "/absolute/path/to/bin/agentic_executables_mcp_server.dart"]
    }
  }
}
```

### Validate Config

**Check Configuration:**

```bash
# Detect and validate Cursor config
if [ -f "$HOME/.cursor/mcp.json" ]; then
  CONFIG_FILE="$HOME/.cursor/mcp.json"
elif [ -f "$HOME/Library/Application Support/Cursor/User/globalStorage/mcp.json" ]; then
  CONFIG_FILE="$HOME/Library/Application Support/Cursor/User/globalStorage/mcp.json"
fi

# Or set manually for your client
# CONFIG_FILE="<your-config-path>"

if [ -z "$CONFIG_FILE" ] || [ ! -f "$CONFIG_FILE" ]; then
  echo "✗ Config file not found. Please set CONFIG_FILE manually."
  exit 1
fi

# Check JSON syntax
python3 -m json.tool "$CONFIG_FILE" > /dev/null && echo "✓ Valid JSON" || echo "✗ Invalid JSON"

# Check entry exists
grep -q "agentic_executables" "$CONFIG_FILE" && echo "✓ Entry found" || echo "✗ Entry missing"

# Verify server path exists
SERVER_PATH=$(python3 << EOF
import json
with open("$CONFIG_FILE", 'r') as f:
    config = json.load(f)
    print(config.get("mcpServers", {}).get("agentic_executables", {}).get("command", ""))
EOF
)

if [ -n "$SERVER_PATH" ] && [ -f "$SERVER_PATH" ]; then
  echo "✓ Server path valid: $SERVER_PATH"
else
  echo "✗ Server path invalid or missing: $SERVER_PATH"
fi

# List all configured servers (verify no conflicts)
echo "Configured MCP servers:"
python3 << EOF
import json
with open("$CONFIG_FILE", 'r') as f:
    config = json.load(f)
    servers = config.get("mcpServers", {})
    for name in servers.keys():
        print(f"  - {name}")
EOF
```

**Important**: 
- MCP servers connect at startup only. Complete quit and relaunch your IDE/client after configuration changes.
- Always verify existing servers are preserved after configuration updates.
- Keep backup files until you confirm everything works.

## Integration

### Integration Points

- **MCP Client Configuration File** - Server registration point
- **Server Binary** - Executable at `build/server` (or Docker/Dev mode)
- **MCP Protocol** - STDIO communication channel
- **Registry Access** - Network connectivity for GitHub registry operations

### Integration Steps

**Step 1: Locate MCP Configuration**

Use the detection scripts above to find your MCP client's configuration file location, or manually identify it (see Config section above).

**Step 2: Backup Existing Configuration**

Always backup your existing config file before making changes:

```bash
CONFIG_FILE="<your-config-path>"
cp "$CONFIG_FILE" "${CONFIG_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
```

**Step 3: Add Server Entry Safely**

Use the merge scripts provided above to add the `agentic_executables` server entry while preserving existing servers. Never overwrite the entire config file - always merge.

**Step 4: Restart Client**

Complete quit (not just close window) and relaunch your IDE/client. MCP servers connect at startup only.

**Step 5: Verify Integration**

Test MCP connection (see Validation section). Verify that all existing servers still work.

### Bridge to Application Layers

**For AI Agents:**
- Agents can invoke 5 core tools via MCP protocol
- Tools provide strategic guidance (not direct execution)
- Registry operations enable fetching library AE files

**For Library Authors:**
- Use `get_ae_instructions` to bootstrap AE files
- Use `verify_ae_implementation` and `evaluate_ae_compliance` for validation
- Use `manage_ae_registry` to submit libraries

**For Developers:**
- Use `manage_ae_registry` to fetch library AE files
- Execute returned instructions via AI agent
- Use `verify_ae_implementation` to confirm installation

### Resource Management

**Server Process:**
- Server runs as separate process managed by MCP client
- No manual process management required
- Server handles STDIO communication automatically

**Cleanup:**
- Server process terminates when MCP client closes
- No persistent resources created
- Build artifacts (`build/server`) can be removed if uninstalling

## Validation

### Check Installation

**1. Verify Server Binary:**

```bash
# Check binary exists and is executable
test -f build/server && test -x build/server && echo "✓ Valid" || echo "✗ Invalid"

# Check binary size (should be ~15-20MB)
ls -lh build/server
```

**2. Test Server Startup:**

```bash
# Server should wait for input (not exit immediately)
./build/server
# Press Ctrl+C to exit
```

If server exits immediately, check logs or run with verbose output.

### Check Configuration

**1. Validate Config File:**

```bash
# Set CONFIG_FILE to your client's config path
CONFIG_FILE="<your-client-config-path>"

# Check JSON syntax
python3 -m json.tool "$CONFIG_FILE" > /dev/null && echo "✓ Valid JSON" || echo "✗ Invalid JSON"

# Check entry exists
grep -q "agentic_executables" "$CONFIG_FILE" && echo "✓ Entry found" || echo "✗ Entry missing"
```

**2. Verify Absolute Path:**

```bash
# Extract path from config and verify
SERVER_PATH=$(grep -A 2 "agentic_executables" "$CONFIG_FILE" | grep "command" | cut -d'"' -f4)
test -f "$SERVER_PATH" && echo "✓ Path valid" || echo "✗ Path invalid"
```

### Test MCP Connection

Test MCP connection in your IDE/client:

**1. List available MCP tools:**

Ask your AI assistant: *"What MCP tools are available?"* or *"List MCP servers"*

Expected: 5 tools from `agentic_executables` server:
- `get_agentic_executable_definition`
- `get_ae_instructions`
- `verify_ae_implementation`
- `evaluate_ae_compliance`
- `manage_ae_registry`

**2. Get framework definition:**

Ask: *"Use get_agentic_executable_definition"* or invoke the tool directly

Expected: AE framework definition, contexts, actions, principles (< 2s).

**3. Fetch bootstrap instructions:**

Ask: *"Use get_ae_instructions with context 'library' and action 'bootstrap'"*

Expected: Returns `ae_bootstrap.md` + `ae_context.md` content (< 3s).

**4. Test registry fetch:**

Ask: *"Use manage_ae_registry to get python_requests install file"*

Expected: Returns `ae_install.md` for `python_requests` (< 5s).

### Success Checklist

- [ ] Repository cloned/verified
- [ ] Dart SDK 3.0+, Git 2.0+ installed
- [ ] `pubspec.lock` and `.dart_tool/` exist
- [ ] `build/server` exists (~15-20MB)
- [ ] Server starts without exit (waits for input)
- [ ] Config file created with absolute path
- [ ] Valid JSON in config file
- [ ] IDE/client completely restarted (not just window close)
- [ ] 5 tools visible in MCP tools list
- [ ] All validation tests pass

## Troubleshooting

**Clone fails**: Check git installed, network connectivity, try SSH: `git clone git@github.com:...`

**Pub get fails**: Check Dart 3.0+, clear cache: `dart pub cache clean`, retry with `--verbose`

**Build fails**: Check disk space (100MB needed), clean: `rm -rf build/ .dart_tool/`, rebuild

**Server won't start**: Check permissions: `chmod +x build/server`, check deps: `ldd build/server` (Linux) or `otool -L build/server` (macOS)

**Tools not showing**:
- Verify config path exists: `ls "$CONFIG_FILE"`
- Check JSON syntax: `python3 -m json.tool "$CONFIG_FILE"`
- Use absolute paths (not `./` or `~/`)
- Test server directly: `./build/server` (should wait for input)
- Complete quit + relaunch your IDE/client (not just close window)
- Check IDE/client logs for MCP connection errors
- Verify MCP support: Some clients require extensions/plugins for MCP
- Verify existing servers weren't accidentally removed: Check backup file
- For Cursor: Check both `~/.cursor/mcp.json` and `~/Library/Application Support/Cursor/User/globalStorage/mcp.json`

**Registry fails**:
- Check library exists: https://github.com/fluent-meaning-symbiotic/agentic_executables/tree/main/ae_use_registry
- Use format: `<language>_<library_name>` (e.g., `python_requests`)
- Test network: `curl -I https://raw.githubusercontent.com/.../README.md`

**Slow performance**: Registry ops are slower (network). Local ops should be < 2s. Use compiled binary, not `dart run`.

## Support

Issues: https://github.com/fluent-meaning-symbiotic/agentic_executables/issues

---

**Agent Notes**: 
- **Always backup existing config files** before modifying - they may contain other MCP servers
- **Use merge scripts** to preserve existing server configurations - never overwrite entire config files
- **Detect config location** first - Cursor may use `~/.cursor/mcp.json` or `~/Library/Application Support/Cursor/User/globalStorage/mcp.json`
- Use absolute paths (not `./` or `~/`)
- Ask user for preferred installation directory - don't assume clone location
- Validate each step before proceeding
- Test registry connectivity
- Complete IDE/client restart required (not just window close)
- ~100MB disk space needed
- Network access required for registry operations
- Works with any MCP-compatible client (Cursor, Claude Desktop, VSCode, etc.)
- MCP servers connect at startup only - configuration changes require full restart
- Verify all existing servers still work after adding agentic_executables
