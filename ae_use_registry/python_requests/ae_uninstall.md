# requests Uninstallation

## Context

Remove the requests library from a Python project and clean up dependencies.

## Prerequisites

- requests package is installed
- Virtual environment activated (if used)

## Uninstallation Steps

### 1. Uninstall Package

```bash
pip uninstall requests
```

Confirm when prompted.

### 2. Remove from Requirements

Edit `requirements.txt`, remove:

```
requests>=2.31.0
```

### 3. Clean Unused Dependencies

```bash
pip autoremove requests  # If pip-autoremove is installed
# or manually check dependencies:
pip list
```

### 4. Update Lock File

If using pip-tools:

```bash
pip-compile requirements.in
```

## Validation

### Verify Removal

```bash
pip show requests
```

Expected: "WARNING: Package(s) not found: requests"

### Check Import Fails

```python
python -c "import requests"
```

Expected: ImportError

### Verify Requirements

```bash
cat requirements.txt | grep requests
```

Expected: No output

## Cleanup Checklist

- [ ] Package uninstalled via pip
- [ ] requirements.txt updated
- [ ] No import statements for requests in code
- [ ] Dependencies cleaned up
- [ ] Lock files updated
- [ ] Code refactored to use alternative HTTP library (if needed)

## State Restoration

### If You Need to Revert

```bash
pip install requests
# or from requirements
pip install -r requirements.txt
```

## Files Modified

- **requirements.txt** - Dependency removed
- **Virtual environment** - Package files removed
- **Import statements** - Need to be removed from code

## Alternative HTTP Libraries

If removing requests, consider:

- **urllib3** - Lower-level HTTP client
- **httpx** - Modern async-capable client
- **aiohttp** - Async HTTP client/server framework
- **urllib** - Built-in Python library (no installation needed)

## Common Issues

**Issue**: Import errors in code after uninstall
**Solution**: Search and remove all `import requests` statements

**Issue**: Dependent packages break
**Solution**: Check which packages depend on requests: `pip show requests`

**Issue**: Requirements file conflicts
**Solution**: Regenerate from scratch if using pip-compile

## Next Steps

After uninstallation:

1. Remove all requests imports from codebase
2. Refactor HTTP calls to use alternative library
3. Test all HTTP-dependent functionality
4. Update documentation
5. Rebuild virtual environment if issues persist
