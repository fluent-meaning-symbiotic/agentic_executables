# requests Usage Guide

## Overview

Comprehensive guide for using the requests library effectively in Python projects.

## Quick Reference

### Basic GET Request

```python
import requests
response = requests.get('https://api.example.com/data')
print(response.json())
```

### POST Request with Data

```python
response = requests.post('https://api.example.com/data', json={'key': 'value'})
```

### With Timeout

```python
response = requests.get('https://api.example.com/data', timeout=5)
```

## Common Usage Patterns

### 1. Basic HTTP Methods

**GET:**

```python
response = requests.get('https://httpbin.org/get')
data = response.json()
```

**POST:**

```python
response = requests.post('https://httpbin.org/post', data={'key': 'value'})
```

**PUT:**

```python
response = requests.put('https://httpbin.org/put', json={'updated': True})
```

**DELETE:**

```python
response = requests.delete('https://httpbin.org/delete')
```

### 2. Headers and Authentication

**Custom Headers:**

```python
headers = {'Authorization': 'Bearer token123', 'User-Agent': 'MyApp/1.0'}
response = requests.get('https://api.example.com/data', headers=headers)
```

**Basic Auth:**

```python
from requests.auth import HTTPBasicAuth
response = requests.get('https://api.example.com', auth=HTTPBasicAuth('user', 'pass'))
```

**Token Auth:**

```python
headers = {'Authorization': f'Bearer {token}'}
response = requests.get('https://api.example.com', headers=headers)
```

### 3. Session Management

**Persistent Sessions:**

```python
session = requests.Session()
session.headers.update({'Authorization': 'Bearer token123'})

# All requests use the same headers and cookies
response1 = session.get('https://api.example.com/endpoint1')
response2 = session.get('https://api.example.com/endpoint2')
```

**Session with Retry:**

```python
from requests.adapters import HTTPAdapter
from requests.packages.urllib3.util.retry import Retry

session = requests.Session()
retry = Retry(total=3, backoff_factor=0.3, status_forcelist=[500, 502, 503, 504])
adapter = HTTPAdapter(max_retries=retry)
session.mount('http://', adapter)
session.mount('https://', adapter)
```

### 4. Error Handling

**Basic Error Handling:**

```python
try:
    response = requests.get('https://api.example.com/data', timeout=5)
    response.raise_for_status()  # Raises HTTPError for bad responses
    data = response.json()
except requests.exceptions.HTTPError as e:
    print(f"HTTP error: {e}")
except requests.exceptions.ConnectionError as e:
    print(f"Connection error: {e}")
except requests.exceptions.Timeout as e:
    print(f"Timeout error: {e}")
except requests.exceptions.RequestException as e:
    print(f"General error: {e}")
```

**Status Code Checking:**

```python
response = requests.get('https://api.example.com/data')
if response.status_code == 200:
    print("Success!")
elif response.status_code == 404:
    print("Not found")
else:
    print(f"Error: {response.status_code}")
```

### 5. JSON Handling

**Send JSON:**

```python
payload = {'key1': 'value1', 'key2': 'value2'}
response = requests.post('https://api.example.com/data', json=payload)
```

**Parse JSON:**

```python
response = requests.get('https://api.example.com/data')
data = response.json()
```

**Handle JSON Errors:**

```python
try:
    data = response.json()
except ValueError:
    print("Response is not valid JSON")
```

### 6. File Operations

**Upload Files:**

```python
files = {'file': open('report.pdf', 'rb')}
response = requests.post('https://api.example.com/upload', files=files)
```

**Download Files:**

```python
response = requests.get('https://example.com/file.pdf')
with open('downloaded_file.pdf', 'wb') as f:
    f.write(response.content)
```

**Streaming Downloads:**

```python
response = requests.get('https://example.com/largefile.zip', stream=True)
with open('largefile.zip', 'wb') as f:
    for chunk in response.iter_content(chunk_size=8192):
        f.write(chunk)
```

## Best Practices

### Always Use Timeouts

```python
# Good
response = requests.get('https://api.example.com', timeout=10)

# Bad
response = requests.get('https://api.example.com')  # Can hang forever
```

### Use Sessions for Multiple Requests

```python
# Good - reuses connection
with requests.Session() as session:
    session.get('https://api.example.com/1')
    session.get('https://api.example.com/2')

# Less efficient - creates new connection each time
requests.get('https://api.example.com/1')
requests.get('https://api.example.com/2')
```

### Handle Exceptions Properly

```python
try:
    response = requests.get('https://api.example.com', timeout=5)
    response.raise_for_status()
except requests.exceptions.RequestException as e:
    # Log error, return default value, or re-raise
    logger.error(f"Request failed: {e}")
    return None
```

### Verify SSL Certificates

```python
# Good - default behavior
response = requests.get('https://api.example.com')

# Only disable for testing, never in production
response = requests.get('https://api.example.com', verify=False)
```

## Advanced Usage

### Custom Retry Logic

```python
def make_request_with_retry(url, max_retries=3):
    for attempt in range(max_retries):
        try:
            response = requests.get(url, timeout=5)
            response.raise_for_status()
            return response
        except requests.exceptions.RequestException as e:
            if attempt == max_retries - 1:
                raise
            time.sleep(2 ** attempt)  # Exponential backoff
```

### Concurrent Requests

```python
from concurrent.futures import ThreadPoolExecutor

urls = ['https://api.example.com/1', 'https://api.example.com/2']

with ThreadPoolExecutor(max_workers=5) as executor:
    responses = list(executor.map(requests.get, urls))
```

### Proxy Configuration

```python
proxies = {
    'http': 'http://proxy.example.com:8080',
    'https': 'https://proxy.example.com:8080',
}
response = requests.get('https://api.example.com', proxies=proxies)
```

### Custom Adapters

```python
from requests.adapters import HTTPAdapter

session = requests.Session()
adapter = HTTPAdapter(pool_connections=100, pool_maxsize=100)
session.mount('https://', adapter)
```

## Performance Tips

1. **Reuse Sessions**: Significantly faster for multiple requests
2. **Use Connection Pooling**: Handled automatically by sessions
3. **Stream Large Responses**: Use `stream=True` for large files
4. **Adjust Timeouts**: Balance between responsiveness and reliability
5. **Concurrent Requests**: Use threading for I/O-bound operations

## Security Considerations

1. **Always Verify SSL**: Don't disable `verify` in production
2. **Protect Credentials**: Use environment variables for secrets
3. **Validate Input**: Sanitize URLs and parameters
4. **Handle Sensitive Data**: Don't log full responses with credentials
5. **Update Regularly**: Keep requests package up to date for security patches

## Common Patterns

### API Client Class

```python
class APIClient:
    def __init__(self, base_url, token):
        self.base_url = base_url
        self.session = requests.Session()
        self.session.headers.update({'Authorization': f'Bearer {token}'})

    def get(self, endpoint):
        url = f"{self.base_url}/{endpoint}"
        response = self.session.get(url, timeout=10)
        response.raise_for_status()
        return response.json()

    def post(self, endpoint, data):
        url = f"{self.base_url}/{endpoint}"
        response = self.session.post(url, json=data, timeout=10)
        response.raise_for_status()
        return response.json()
```

### Rate Limiting

```python
import time

class RateLimitedClient:
    def __init__(self, requests_per_second=10):
        self.delay = 1.0 / requests_per_second
        self.last_request = 0

    def get(self, url):
        now = time.time()
        if now - self.last_request < self.delay:
            time.sleep(self.delay - (now - self.last_request))

        response = requests.get(url)
        self.last_request = time.time()
        return response
```

## Troubleshooting

### Issue: Timeout Errors

```python
# Increase timeout
response = requests.get(url, timeout=30)

# Or separate connect and read timeouts
response = requests.get(url, timeout=(5, 30))  # 5s connect, 30s read
```

### Issue: SSL Certificate Errors

```python
# Update certifi
pip install --upgrade certifi

# Specify CA bundle
response = requests.get(url, verify='/path/to/certfile')
```

### Issue: Connection Pool Full

```python
# Close session when done
session.close()

# Or use context manager
with requests.Session() as session:
    response = session.get(url)
```

## Resources

- [Official Documentation](https://requests.readthedocs.io/)
- [Quickstart Guide](https://requests.readthedocs.io/en/latest/user/quickstart/)
- [Advanced Usage](https://requests.readthedocs.io/en/latest/user/advanced/)

## Quick Tips

1. Always set timeouts to prevent hanging
2. Use sessions for multiple requests to the same host
3. Handle exceptions explicitly
4. Verify SSL certificates in production
5. Stream large file downloads
6. Use connection pooling for performance
7. Implement retry logic for unreliable APIs
8. Keep the library updated for security patches
