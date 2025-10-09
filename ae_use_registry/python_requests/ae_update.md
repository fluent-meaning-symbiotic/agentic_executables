# requests Update

## Context

Update the requests library to the latest version, handling compatibility changes.

## Prerequisites

- requests currently installed
- Virtual environment activated (if used)
- Git commit or backup of current state

## Update Steps

### 1. Check Current Version

```bash
pip show requests
```

### 2. Update Package

**Option A - Latest version:**

```bash
pip install --upgrade requests
```

**Option B - Specific version:**

```bash
pip install requests==2.31.0
```

**Option C - Update from requirements:**

```bash
pip install --upgrade -r requirements.txt
```

### 3. Update Requirements File

Edit `requirements.txt`:

```
requests>=2.31.0  # Update version constraint
```

### 4. Verify Update

```bash
pip show requests
python -c "import requests; print(requests.__version__)"
```

## Migration Steps

### Review Changelog

Visit https://github.com/psf/requests/blob/main/HISTORY.md

### Test After Update

```bash
python -m pytest tests/
# or
python -m unittest discover
```

### Check for Deprecations

Review code for deprecated methods:

- Old session handling
- Deprecated parameters
- Changed default behaviors

## Validation

### Verify Version

```bash
pip show requests | grep Version
```

Expected: Shows new version number

### Test HTTP Calls

```python
import requests
response = requests.get('https://httpbin.org/get')
assert response.status_code == 200
print("Update successful!")
```

### Run Full Test Suite

```bash
python -m pytest
```

## Rollback Procedure

If update causes issues:

### 1. Uninstall New Version

```bash
pip uninstall requests
```

### 2. Install Previous Version

```bash
pip install requests==2.28.0  # Replace with your previous version
```

### 3. Verify Rollback

```bash
pip show requests
```

## Common Migration Scenarios

### SSL/TLS Changes

Update certificate handling:

```python
import requests
response = requests.get('https://example.com', verify=True)
```

### Session Changes

Review session configuration:

```python
session = requests.Session()
session.headers.update({'User-Agent': 'MyApp'})
```

### Timeout Behavior

Ensure timeouts are explicit:

```python
requests.get('https://example.com', timeout=5)
```

## Integration Points

- **requirements.txt** - Version constraint updated
- **Virtual environment** - Package files updated
- **Import statements** - May need adjustments
- **Error handling** - Exception types may change
- **SSL/TLS** - Certificate handling updates

## Best Practices

1. **Test First**: Test update in development before production
2. **Pin Versions**: Use exact versions in production requirements
3. **Review Changes**: Always check changelog for breaking changes
4. **Gradual Updates**: Update one major version at a time
5. **Monitor Issues**: Check GitHub issues for known problems

## Version-Specific Notes

### 2.x to 3.x Migration

(When 3.x is released)

- Review breaking changes
- Update exception handling
- Check API changes

### Security Updates

Always apply security patches promptly:

```bash
pip install --upgrade requests
```

## Common Issues

**Issue**: SSL verification fails after update
**Solution**: Update certifi: `pip install --upgrade certifi`

**Issue**: Import errors
**Solution**: Restart Python interpreter or IDE

**Issue**: Breaking API changes
**Solution**: Review changelog and update code accordingly

**Issue**: Performance regression
**Solution**: Check for new configuration options or report issue

## Next Steps

After update:

1. Update requirements.txt and commit
2. Run full test suite
3. Deploy to staging environment
4. Monitor for issues
5. Update production after validation
6. Document any code changes needed
