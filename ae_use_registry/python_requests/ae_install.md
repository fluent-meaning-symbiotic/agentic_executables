# requests Installation

## Context

Install the requests library for Python projects to handle HTTP requests.

## Prerequisites

- Python 3.7+ installed
- pip package manager available
- Virtual environment recommended

## Installation Steps

### 1. Create Virtual Environment (Recommended)

```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

### 2. Install Package

```bash
pip install requests
```

### 3. Verify Installation

```bash
python -c "import requests; print(requests.__version__)"
```

### 4. Add to Requirements File

Create or update `requirements.txt`:

```
requests>=2.31.0
```

## Validation

### Check Installation

```bash
pip show requests
```

Expected: Shows package information including version and location

### Import Test

```python
import requests
response = requests.get('https://httpbin.org/get')
print(response.status_code)
```

Expected: Prints `200`

## Integration Points

- **requirements.txt** - Dependency specification
- **setup.py/pyproject.toml** - Package configuration
- **Virtual environment** - Isolated dependencies
- **Import statements** - Code integration

## Configuration Options

### Install Specific Version

```bash
pip install requests==2.31.0
```

### Install with Security Features

```bash
pip install requests[security]
```

### Install for Development

```bash
pip install requests[dev]
```

## Common Issues

**Issue**: SSL certificate verification fails
**Solution**: Update certifi package: `pip install --upgrade certifi`

**Issue**: Import error after installation
**Solution**: Ensure correct virtual environment is activated

**Issue**: Permission denied during installation
**Solution**: Use `pip install --user requests` or activate virtual environment

## Next Steps

After installation:

1. Import requests in your Python code
2. Review ae_use.md for usage patterns
3. Set up proper error handling
4. Configure timeouts and retries
5. Consider using sessions for multiple requests
