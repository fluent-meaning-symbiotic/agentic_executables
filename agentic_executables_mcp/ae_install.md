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

### Locate Claude Desktop Config

```bash
# macOS
CONFIG_FILE="$HOME/Library/Application Support/Claude/claude_desktop_config.json"

# Windows (PowerShell)
$CONFIG_FILE = "$env:APPDATA\Claude\claude_desktop_config.json"

# Linux
CONFIG_FILE="$HOME/.config/Claude/claude_desktop_config.json"

# Create directory if needed
mkdir -p "$(dirname "$CONFIG_FILE")"
```

### Update Config File

Edit `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "agentic_executables": {
      "command": "/absolute/path/to/agentic_executables_mcp/build/server"
    }
  }
}
```

Replace with your actual absolute path. Use `$(pwd)/build/server` to get it.

**Important**: Use absolute paths only, not relative (`./`) or home (`~/`).

### Validate Config

```bash
# Check JSON syntax
python3 -m json.tool "$CONFIG_FILE" > /dev/null && echo "✓ Valid" || echo "✗ Invalid"

# Check entry exists
grep -q "agentic_executables" "$CONFIG_FILE" && echo "✓ Found" || echo "✗ Missing"
```

### Restart Claude Desktop

**Complete quit** (not just close window):

- macOS: Cmd+Q
- Windows: Alt+F4
- Linux: File → Quit

Wait 3s, then relaunch. MCP servers connect at startup only.

## Validation

Test in Claude Desktop:

**1. List tools**:

```
"What MCP tools are available?"
```

Expected: 5 tools from agentic_executables server.

**2. Get definition**:

```
"Use get_agentic_executable_definition"
```

Expected: AE definition, contexts, actions, principles (< 2s).

**3. Fetch instructions**:

```
"Use get_ae_instructions with context 'library' and action 'bootstrap'"
```

Expected: Returns ae_bootstrap.md content (< 3s).

**4. Test registry**:

```
"Use manage_ae_registry to get python_requests install file"
```

Expected: Returns ae_install.md for python_requests (< 5s).

## Alternative Methods

**Docker** (no Dart SDK needed):

```bash
docker build -t prompts-framework-mcp .
docker run -i prompts-framework-mcp
```

Config: `"command": "docker", "args": ["run", "-i", "prompts-framework-mcp"]`

**Dev mode** (no compilation):

```bash
dart run bin/agentic_executables_mcp_server.dart
```

Config: `"command": "dart", "args": ["run", "/abs/path/bin/agentic_executables_mcp_server.dart"]`

Note: Slower startup (~2s) but no build step.

## Troubleshooting

**Clone fails**: Check git installed, network connectivity, try SSH: `git clone git@github.com:...`

**Pub get fails**: Check Dart 3.0+, clear cache: `dart pub cache clean`, retry with `--verbose`

**Build fails**: Check disk space (100MB needed), clean: `rm -rf build/ .dart_tool/`, rebuild

**Server won't start**: Check permissions: `chmod +x build/server`, check deps: `ldd build/server` (Linux) or `otool -L build/server` (macOS)

**Tools not showing**:

- Verify config path: `ls "$CONFIG_FILE"`
- Check JSON: `python3 -m json.tool "$CONFIG_FILE"`
- Use absolute paths (not `./` or `~/`)
- Test server: `./build/server` (should wait for input)
- Complete quit + relaunch Claude (Cmd+Q on macOS)

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
- [ ] Server starts without exit
- [ ] Config has absolute path
- [ ] Valid JSON in config
- [ ] Claude completely restarted
- [ ] 5 tools visible
- [ ] All validation tests pass

## Uninstall

```bash
# Remove from config, restart Claude
# rm build/server
# rm -rf .dart_tool/ pubspec.lock
```

## Support

Issues: https://github.com/fluent-meaning-symbiotic/agentic_executables/issues

---

**Agent Notes**: Use absolute paths. Validate each step. Test registry. Complete restart required. ~100MB disk, network needed.
