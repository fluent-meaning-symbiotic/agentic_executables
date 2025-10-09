# Prompts Framework MCP Server Installation

Agentic Executable for installing the Prompts Framework MCP Server.

## Prerequisites

Check requirements before installation:

```bash
# Verify Dart SDK 3.0+
dart --version

# Expected: Dart SDK version: 3.0.0 or higher
```

If Dart SDK missing, install from: https://dart.dev/get-dart

## Installation

### Step 1: Navigate to Package Directory

```bash
cd prompts_framework_mcp
```

### Step 2: Install Dependencies

```bash
dart pub get
```

**Validation**:

```bash
# Check pubspec.lock exists
ls pubspec.lock

# Expected: pubspec.lock file present
```

### Step 3: Build Native Binary

```bash
# Create build directory if not exists
mkdir -p build

# Compile to native executable
dart compile exe bin/prompts_framework_mcp_server.dart -o build/server
```

**Validation**:

```bash
# Verify binary exists and is executable
ls -lh build/server

# Expected: Executable file ~10-20MB
```

Alternative: Use build script

```bash
./build.sh
```

### Step 4: Test Server Startup

```bash
# Run server (will wait for STDIN input)
./build/server &
SERVER_PID=$!

# Give it 2 seconds to start
sleep 2

# Check if running
ps -p $SERVER_PID > /dev/null && echo "Server running" || echo "Server failed"

# Stop test server
kill $SERVER_PID
```

## Configuration

### MCP Client Setup

#### Claude Desktop (macOS)

1. Locate config file:

```bash
# macOS
CONFIG_PATH="$HOME/Library/Application Support/Claude/claude_desktop_config.json"

# Create if doesn't exist
mkdir -p "$(dirname "$CONFIG_PATH")"
touch "$CONFIG_PATH"
```

2. Get absolute path to server:

```bash
# From prompts_framework_mcp directory
SERVER_PATH="$(pwd)/build/server"
echo "Server path: $SERVER_PATH"
```

3. Update config file:

```bash
# Backup existing config
cp "$CONFIG_PATH" "$CONFIG_PATH.backup"

# Add server configuration (manual edit required)
# Open in editor:
open "$CONFIG_PATH"
```

Add this configuration:

```json
{
  "mcpServers": {
    "agentic_executables": {
      "command": "/absolute/path/to/prompts_framework_mcp/build/server"
    }
  }
}
```

Replace `/absolute/path/to/prompts_framework_mcp/build/server` with your actual `$SERVER_PATH`.

#### Claude Desktop (Windows)

```powershell
# Windows config path
$CONFIG_PATH = "$env:APPDATA\Claude\claude_desktop_config.json"

# Get server path
$SERVER_PATH = "$(Get-Location)\build\server"

# Edit config
notepad $CONFIG_PATH
```

#### Claude Desktop (Linux)

```bash
# Linux config path
CONFIG_PATH="$HOME/.config/Claude/claude_desktop_config.json"

# Get server path
SERVER_PATH="$(pwd)/build/server"

# Edit config
nano "$CONFIG_PATH"
```

### Step 5: Restart MCP Client

```bash
# Claude Desktop - Quit completely and restart
# macOS: Cmd+Q then relaunch
# Windows: Alt+F4 then relaunch
# Linux: Close window then relaunch
```

## Integration Validation

### Test 1: Check Server Connection

In Claude Desktop, the tools should appear automatically. Test by asking:

```
"List available MCP tools"
```

Expected tools:

- get_agentic_executable_definition
- get_ae_instructions
- verify_ae_implementation
- evaluate_ae_compliance
- manage_ae_registry

### Test 2: Call get_agentic_executable_definition

Ask Claude:

```
"Use the prompts-framework MCP to get the Agentic Executable definition"
```

Expected: Returns AE definition, contexts, actions, tools, principles.

### Test 3: Call get_ae_instructions

Ask Claude:

```
"Use get_ae_instructions with context_type 'library' and action 'bootstrap'"
```

Expected: Returns ae_bootstrap.md and ae_context.md content.

### Test 4: Registry Access Test

Ask Claude:

```
"Use manage_ae_registry to get ae_install.md for python_requests from the registry"
```

Expected: Returns installation instructions for python_requests library.

## Troubleshooting

### Issue: Server Won't Start

**Symptom**: Binary doesn't execute or crashes immediately

**Solutions**:

```bash
# Check Dart version
dart --version

# Rebuild with verbose output
dart compile exe bin/prompts_framework_mcp_server.dart -o build/server --verbose

# Check resources directory exists
ls resources/
# Expected: ae_bootstrap.md, ae_context.md, ae_use.md
```

### Issue: Tools Not Showing in Claude

**Symptom**: MCP tools not available in Claude Desktop

**Solutions**:

```bash
# Verify config path is correct
cat "$HOME/Library/Application Support/Claude/claude_desktop_config.json"

# Verify server path is absolute (not relative)
# BAD:  "./build/server"
# GOOD: "/Users/username/prompts_framework_mcp/build/server"

# Check server is executable
ls -l build/server
# Expected: -rwxr-xr-x (executable permissions)

# Completely quit and restart Claude Desktop
# Not just close window - full quit (Cmd+Q on macOS)
```

### Issue: Registry Fetch Fails

**Symptom**: get_from_registry returns error

**Solutions**:

1. Check library exists in registry:

   - Visit https://github.com/fluent-meaning-symbiotic/agentic_executables
   - Navigate to ae_use_registry/
   - Verify library folder exists

2. Check library_id format:

   - Must be: `<language>_<library_name>`
   - Examples: `python_requests`, `dart_provider`
   - Not: `requests`, `Python_Requests`

3. Check action is valid:
   - Valid: `install`, `uninstall`, `update`, `use`
   - Not valid: `bootstrap` (library-only action)

### Issue: Docker Build Fails

**Symptom**: Docker build command fails

**Solutions**:

```bash
# Ensure in correct directory
pwd
# Expected: .../prompts_framework_mcp

# Check Dockerfile exists
ls Dockerfile

# Check all resources exist
ls resources/
# Expected: ae_bootstrap.md, ae_context.md, ae_use.md

# Build with no cache
docker build --no-cache -t prompts-framework-mcp:latest .

# Check Docker version
docker --version
# Expected: Docker version 20.0.0 or higher
```

## Success Criteria

Installation complete when all checks pass:

- [ ] Dart SDK 3.0+ installed and verified
- [ ] Dependencies installed (pubspec.lock exists)
- [ ] Native binary compiled (build/server exists)
- [ ] Server starts without errors
- [ ] MCP client configured with absolute path
- [ ] Client restarted completely
- [ ] All 5 tools visible in client
- [ ] get_agentic_executable_definition returns data
- [ ] get_ae_instructions returns documentation
- [ ] Registry access works (get_from_registry succeeds)

## Next Steps

After successful installation:

1. Read [README.md](README.md) for comprehensive documentation
2. Review all 5 tool descriptions and examples
3. Explore registry operations for library management
4. Test with real library bootstrap or installation
5. Review [ae_use_registry/CONTRIBUTING.md](../ae_use_registry/CONTRIBUTING.md) for registry submission

## Uninstallation

To remove the MCP server:

```bash
# Remove from MCP client config
# Edit claude_desktop_config.json and remove "prompts-framework" entry

# Remove binary
rm build/server

# Optional: Remove dependencies
rm -rf .dart_tool/
rm pubspec.lock
```

Restart MCP client to complete uninstallation.

## Support

For issues:

1. Check troubleshooting section above
2. Verify all prerequisites met
3. Review logs in MCP client
4. Check repository issues: https://github.com/fluent-meaning-symbiotic/agentic_executables/issues

---

**Installation Agent Notes**:

- Use absolute paths, never relative paths in configs
- Validate each step before proceeding to next
- Test registry access after installation
- Ensure client fully restarts (quit, not just close)
- LOC: ~280 (within conciseness target)
