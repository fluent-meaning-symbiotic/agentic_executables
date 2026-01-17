# Prompts Framework MCP Server Installation

Agentic Executable for installing the Prompts Framework MCP Server.

## Repository Setup

### Clone from GitHub

```bash
# Clone and navigate
git clone https://github.com/fluent-meaning-symbiotic/agentic_executables.git
cd agentic_executables/agentic_executables_mcp

# Validate
test -f pubspec.yaml && echo "✓ Ready" || echo "✗ Failed"
```

### If Already Cloned

```bash
cd /path/to/agentic_executables/agentic_executables_mcp
git pull origin main
```

## Prerequisites

Check requirements:

```bash
# Git 2.0+
git --version

# Dart SDK 3.0+
dart --version

# Disk space: ~100MB (repo 5MB + deps 50MB + build 20MB)
df -h .
```

**Network required for**: git clone, pub get, registry operations.

## Installation

### Step 1: Install Dependencies

```bash
dart pub get

# Validate
test -f pubspec.lock && test -d .dart_tool && echo "✓ Done" || echo "✗ Failed"
```

### Step 2: Build Native Binary

```bash
# Using build script (recommended)
./build.sh

# Or manual
dart compile exe bin/agentic_executables_mcp_server.dart -o build/server

# Validate
ls -lh build/server
# Expected: ~15-20MB executable
```

### Step 3: Test Server

```bash
timeout 3s ./build/server || echo "✓ Server OK"
```

## Configuration

### Get Absolute Server Path

```bash
# Get absolute path
SERVER_PATH="$(pwd)/build/server"
echo "$SERVER_PATH"

# Validate
test -f "$SERVER_PATH" && echo "✓ Valid" || echo "✗ Invalid"
```

**Important**: Use absolute paths only, not relative (`./`) or home (`~/`).

### MCP Client Configuration

The MCP server works with any MCP-compatible client. Configure your IDE/tool below:

#### Cursor IDE

**Config Location:**
- macOS: `~/Library/Application Support/Cursor/User/globalStorage/mcp.json`
- Windows: `%APPDATA%\Cursor\User\globalStorage\mcp.json`
- Linux: `~/.config/Cursor/User/globalStorage/mcp.json`

**Configuration:**
```json
{
  "mcpServers": {
    "agentic_executables": {
      "command": "/absolute/path/to/agentic_executables_mcp/build/server"
    }
  }
}
```

**Restart**: Complete quit (Cmd+Q / Alt+F4) and relaunch Cursor.

#### Claude Desktop

**Config Location:**
- macOS: `~/Library/Application Support/Claude/claude_desktop_config.json`
- Windows: `%APPDATA%\Claude\claude_desktop_config.json`
- Linux: `~/.config/Claude/claude_desktop_config.json`

**Configuration:**
```json
{
  "mcpServers": {
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

For any MCP-compatible client, add to your MCP configuration:

```json
{
  "mcpServers": {
    "agentic_executables": {
      "command": "/absolute/path/to/agentic_executables_mcp/build/server"
    }
  }
}
```

**Note**: Configuration format may vary by client. Check your client's MCP documentation for exact format.

### Validate Config

```bash
# Set CONFIG_FILE to your client's config path
# Example for Claude Desktop (macOS):
CONFIG_FILE="$HOME/Library/Application Support/Claude/claude_desktop_config.json"

# Check JSON syntax
python3 -m json.tool "$CONFIG_FILE" > /dev/null && echo "✓ Valid" || echo "✗ Invalid"

# Check entry exists
grep -q "agentic_executables" "$CONFIG_FILE" && echo "✓ Found" || echo "✗ Missing"
```

**Important**: MCP servers connect at startup only. Complete quit and relaunch your IDE/client after configuration changes.

## Validation

Test MCP connection in your IDE/client:

**1. List available MCP tools**:

Ask your AI assistant: *"What MCP tools are available?"* or *"List MCP servers"*

Expected: 5 tools from `agentic_executables` server:
- `get_agentic_executable_definition`
- `get_ae_instructions`
- `verify_ae_implementation`
- `evaluate_ae_compliance`
- `manage_ae_registry`

**2. Get framework definition**:

Ask: *"Use get_agentic_executable_definition"* or invoke the tool directly

Expected: AE framework definition, contexts, actions, principles (< 2s).

**3. Fetch bootstrap instructions**:

Ask: *"Use get_ae_instructions with context 'library' and action 'bootstrap'"*

Expected: Returns `ae_bootstrap.md` + `ae_context.md` content (< 3s).

**4. Test registry fetch**:

Ask: *"Use manage_ae_registry to get python_requests install file"*

Expected: Returns `ae_install.md` for `python_requests` (< 5s).

**5. Verify server connectivity**:

Test server directly (should wait for input):
```bash
./build/server
# Press Ctrl+C to exit
```

If server exits immediately, check logs or run with verbose output.

## Alternative Methods

**Docker** (no Dart SDK needed):

```bash
docker build -t prompts-framework-mcp .
docker run -i prompts-framework-mcp
```

**MCP Client Config** (works with any MCP client):
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

**Dev mode** (no compilation, requires Dart SDK):

```bash
dart run bin/agentic_executables_mcp_server.dart
```

**MCP Client Config** (works with any MCP client):
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

**Note**: Dev mode has slower startup (~2s) but no build step required. Docker method works without Dart SDK installation.

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

**Registry fails**:

- Check library exists: https://github.com/fluent-meaning-symbiotic/agentic_executables/tree/main/ae_use_registry
- Use format: `<language>_<library_name>` (e.g., `python_requests`)
- Test network: `curl -I https://raw.githubusercontent.com/.../README.md`

**Slow performance**: Registry ops are slower (network). Local ops should be < 2s. Use compiled binary, not `dart run`.

## Success Checklist

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

## Support

Issues: https://github.com/fluent-meaning-symbiotic/agentic_executables/issues

---

**Agent Notes**: 
- Use absolute paths (not `./` or `~/`)
- Validate each step before proceeding
- Test registry connectivity
- Complete IDE/client restart required (not just window close)
- ~100MB disk space needed
- Network access required for registry operations
- Works with any MCP-compatible client (Cursor, Claude Desktop, VSCode, etc.)
