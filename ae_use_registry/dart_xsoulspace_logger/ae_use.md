<!--
version: 1.0.0
library: xsoulspace_logger
license: MIT
-->

# xsoulspace_logger Usage Guide

## Overview

xsoulspace_logger provides configurable logging with console and file output, structured data support, and log rotation. This guide covers common usage patterns, best practices, and anti-patterns.

## Core Concepts

### Log Levels (Severity Order)

1. **VERBOSE** - Detailed diagnostic information (development only)
2. **DEBUG** - Debug information for troubleshooting
3. **INFO** - Normal operational messages
4. **WARNING** - Potential issues that don't stop execution
5. **ERROR** - Serious problems requiring attention

### Configuration Presets

- `LoggerConfig.debug()` - Development (VERBOSE, console + file)
- `LoggerConfig.production()` - Production (INFO, file only)
- `LoggerConfig.verbose()` - Detailed logging (VERBOSE, large files)
- `LoggerConfig.silent()` - Minimal logging (ERROR only)
- `LoggerConfig.consoleOnly()` - Testing (no files)

### Logger Lifecycle

1. **Create** - Create singleton with config
2. **Initialize** - Call `await logger.init()` for async setup
3. **Use** - Log throughout application
4. **Dispose** - Flush file buffer on exit

**Note:** Explicit initialization via `await logger.init()` is required after creating a Logger instance, even for console-only configurations. This ensures proper async initialization and prevents race conditions.

## Common Usage Patterns

### Pattern 1: Application Initialization

```dart
void main() async {
  // Initialize logger first
  final logger = Logger(LoggerConfig.debug());
  await logger.init();

  logger.info('APP', 'Application starting');

  // Setup
  await initializeServices();
  logger.info('APP', 'Services initialized');

  // Run app
  runApp(MyApp());
}
```

### Pattern 2: Service Layer Logging

```dart
class UserService {
  final _logger = Logger();

  Future<User> fetchUser(String id) async {
    _logger.debug('USER_SERVICE', 'Fetching user', data: {'userId': id});

    try {
      final response = await api.get('/users/$id');
      _logger.info('USER_SERVICE', 'User fetched successfully', data: {
        'userId': id,
        'status': response.statusCode,
      });
      return User.fromJson(response.data);
    } catch (e, stack) {
      _logger.error(
        'USER_SERVICE',
        'Failed to fetch user',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }
}
```

### Pattern 3: Error Boundary Logging

```dart
class ErrorBoundary {
  static void handleError(Object error, StackTrace stack) {
    // Log critical errors
    Logger().error(
      'ERROR_BOUNDARY',
      'Unhandled exception caught',
      error: error,
      stackTrace: stack,
    );

    // Show user-friendly message
    showErrorDialog(error);
  }
}

Future<void> main() async {
  // Initialize logger first
  final logger = Logger(LoggerConfig.debug());
  await logger.init();

  // Flutter error handling
  FlutterError.onError = (details) {
    ErrorBoundary.handleError(details.exception, details.stack ?? StackTrace.current);
  };

  // Dart error handling
  runZonedGuarded(() {
    runApp(MyApp());
  }, ErrorBoundary.handleError);
}
```

### Pattern 4: State Management Logging

```dart
class AppStateNotifier extends ChangeNotifier {
  final _logger = Logger();

  User? _user;
  User? get user => _user;

  Future<void> login(String email, String password) async {
    _logger.debug('AUTH', 'Login attempt', data: {'email': email});

    try {
      final user = await authService.login(email, password);
      _user = user;
      _logger.info('AUTH', 'Login successful', data: {'userId': user.id});
      notifyListeners();
    } catch (e, stack) {
      _logger.error('AUTH', 'Login failed', error: e, stackTrace: stack);
      rethrow;
    }
  }

  void logout() {
    _logger.info('AUTH', 'User logged out', data: {'userId': _user?.id});
    _user = null;
    notifyListeners();
  }
}
```

### Pattern 5: Network Request Logging

```dart
class HttpLogger {
  static void logRequest(
    String method,
    String url, {
    Map<String, dynamic>? headers,
    dynamic body,
  }) {
    Logger().debug('HTTP', 'Request sent', data: {
      'method': method,
      'url': url,
      'hasAuth': headers?.containsKey('Authorization') ?? false,
    });
  }

  static void logResponse(
    String url,
    int statusCode,
    Duration duration,
  ) {
    Logger().info('HTTP', 'Response received', data: {
      'url': url,
      'status': statusCode,
      'duration_ms': duration.inMilliseconds,
    });
  }

  static void logError(String url, Object error) {
    Logger().error('HTTP', 'Request failed', error: error);
  }
}
```

### Pattern 6: Business Logic Tracing

```dart
class PaymentProcessor {
  final _logger = Logger();

  Future<PaymentResult> processPayment(Payment payment) async {
    final traceId = uuid.v4();

    _logger.info('PAYMENT', 'Processing started', data: {
      'traceId': traceId,
      'amount': payment.amount,
      'currency': payment.currency,
    });

    // Validate
    _logger.debug('PAYMENT', 'Validating payment', data: {'traceId': traceId});
    final validation = await validator.validate(payment);
    if (!validation.isValid) {
      _logger.warning('PAYMENT', 'Validation failed', data: {
        'traceId': traceId,
        'errors': validation.errors,
      });
      return PaymentResult.invalid(validation.errors);
    }

    // Process
    _logger.debug('PAYMENT', 'Charging payment method', data: {'traceId': traceId});
    try {
      final result = await gateway.charge(payment);
      _logger.info('PAYMENT', 'Payment successful', data: {
        'traceId': traceId,
        'transactionId': result.id,
      });
      return result;
    } catch (e, stack) {
      _logger.error(
        'PAYMENT',
        'Payment processing failed',
        error: e,
        stackTrace: stack,
      );
      return PaymentResult.error(e);
    }
  }
}
```

### Pattern 7: Environment-Based Configuration

```dart
Future<void> main() async {
  final env = Platform.environment['ENV'] ?? 'development';

  final logger = Logger(_getConfigForEnv(env));
  await logger.init();

  logger.info('APP', 'Starting in $env mode');

  runApp(MyApp());
}

LoggerConfig _getConfigForEnv(String env) {
  return switch (env) {
    'production' => LoggerConfig.production(),
    'staging' => LoggerConfig(
      minLevel: LogLevel.debug,
      enableConsole: false,
      enableFile: true,
    ),
    'test' => LoggerConfig.consoleOnly(level: LogLevel.warning),
    _ => LoggerConfig.debug(),
  };
}
```

### Pattern 8: Structured Performance Logging

```dart
class PerformanceMonitor {
  final _logger = Logger();

  T measureOperation<T>(
    String operation,
    T Function() action, {
    Map<String, dynamic>? metadata,
  }) {
    final stopwatch = Stopwatch()..start();
    _logger.debug('PERF', 'Operation started', data: {
      'operation': operation,
      ...?metadata,
    });

    try {
      final result = action();
      stopwatch.stop();

      _logger.info('PERF', 'Operation completed', data: {
        'operation': operation,
        'duration_ms': stopwatch.elapsedMilliseconds,
        ...?metadata,
      });

      return result;
    } catch (e, stack) {
      stopwatch.stop();
      _logger.error(
        'PERF',
        'Operation failed',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }
}
```

## Best Practices

### 0. Always Initialize After Creation

```dart
// Good: Initialize immediately after creation
final logger = Logger(LoggerConfig.debug());
await logger.init();

// Avoid: Using logger without initialization
final logger = Logger(LoggerConfig.debug());
logger.info('APP', 'Starting');  // May cause issues without init()
```

### 1. Use Consistent Categories

```dart
// Good: Consistent, hierarchical categories
logger.info('API', 'Request completed');
logger.info('API', 'Rate limit reached');
logger.error('DB', 'Connection failed');
logger.debug('UI_HOME', 'Screen rendered');

// Avoid: Inconsistent, unclear categories
logger.info('api', 'Request completed');  // Lowercase
logger.info('Request', 'Completed');       // Message as category
logger.info('', 'Something happened');     // Empty category
```

### 2. Use Structured Data

```dart
// Good: Structured data
logger.info('API', 'User action', data: {
  'userId': user.id,
  'action': 'purchase',
  'itemId': item.id,
  'amount': 99.99,
});

// Avoid: String interpolation
logger.info('API', 'User ${user.id} purchased item ${item.id} for \$99.99');
```

### 3. Log Level Discipline

```dart
// Good: Appropriate levels
logger.verbose('DB', 'Query executed: SELECT * FROM users');  // Dev only
logger.debug('AUTH', 'Token validated');                      // Troubleshooting
logger.info('APP', 'User logged in');                         // Normal ops
logger.warning('API', 'Retry attempt 3/5');                   // Potential issue
logger.error('DB', 'Connection lost', error: e);              // Critical

// Avoid: Wrong levels
logger.error('APP', 'User logged in');        // Not an error
logger.debug('PAYMENT', 'Payment failed');     // Should be error
logger.info('DB', 'Executing: $longQuery');    // Too verbose for info
```

### 4. Always Include Error Context

```dart
// Good: Full context
try {
  await riskyOperation();
} catch (e, stack) {
  logger.error(
    'OPERATION',
    'Failed to complete operation',
    error: e,
    stackTrace: stack,
  );
}

// Avoid: Missing context
try {
  await riskyOperation();
} catch (e) {
  logger.error('OPERATION', 'Failed');  // No error object or stack
}
```

### 5. Dispose Logger Properly

```dart
// Good: Proper cleanup
class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    Logger().dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      Logger().dispose();
    }
  }

  @override
  Widget build(BuildContext context) => MaterialApp(/*...*/);
}
```

### 6. Use Presets for Common Scenarios

```dart
// Good: Use presets
final logger = Logger(LoggerConfig.production());

// Avoid: Manual config for common cases
final logger = Logger(LoggerConfig(
  minLevel: LogLevel.info,
  enableConsole: false,
  enableFile: true,
  enableRotation: true,
  maxFileSizeMB: 50,
  maxFileCount: 5,
));  // This is LoggerConfig.production()!
```

## Anti-Patterns

### ❌ Over-Logging

```dart
// Bad: Too much noise
void processItems(List<Item> items) {
  logger.debug('PROCESS', 'Starting to process items');
  for (final item in items) {
    logger.debug('PROCESS', 'Processing item ${item.id}');
    // ... process item ...
    logger.debug('PROCESS', 'Finished processing item ${item.id}');
  }
  logger.debug('PROCESS', 'Finished processing all items');
}

// Good: Summary logging
void processItems(List<Item> items) {
  logger.debug('PROCESS', 'Processing ${items.length} items');
  // ... process all items ...
  logger.debug('PROCESS', 'Processed ${items.length} items');
}
```

### ❌ Logging Sensitive Data

```dart
// Bad: Logging passwords, tokens, PII
logger.debug('AUTH', 'Login attempt', data: {
  'email': email,
  'password': password,  // NEVER LOG PASSWORDS
});

// Good: Redact sensitive data
logger.debug('AUTH', 'Login attempt', data: {
  'email': email.replaceAll(RegExp(r'(?<=.{3}).(?=.*@)'), '*'),
  'hasPassword': password.isNotEmpty,
});
```

### ❌ Using Wrong Log Levels

```dart
// Bad: Everything is info
logger.info('API', 'Making request');          // Should be debug
logger.info('API', 'Connection failed');       // Should be error
logger.info('API', 'Retry attempt 5/10');      // Should be warning

// Good: Appropriate levels
logger.debug('API', 'Making request');
logger.error('API', 'Connection failed', error: e);
logger.warning('API', 'Retry attempt 5/10');
```

### ❌ Logging in Loops Without Throttling

```dart
// Bad: Flooding logs
void onScroll(ScrollNotification notification) {
  logger.debug('UI', 'Scroll position: ${notification.metrics.pixels}');
  // Called hundreds of times per second!
}

// Good: Throttle or aggregate
var _lastLogTime = DateTime.now();
void onScroll(ScrollNotification notification) {
  final now = DateTime.now();
  if (now.difference(_lastLogTime).inSeconds >= 1) {
    logger.debug('UI', 'Scroll position: ${notification.metrics.pixels}');
    _lastLogTime = now;
  }
}
```

### ❌ Not Using try-catch with Errors

```dart
// Bad: Error might not be logged
void riskyOperation() {
  final result = mightThrow();  // Exception escapes
  logger.info('OPERATION', 'Success');
}

// Good: Catch and log errors
void riskyOperation() {
  try {
    final result = mightThrow();
    logger.info('OPERATION', 'Success');
  } catch (e, stack) {
    logger.error('OPERATION', 'Failed', error: e, stackTrace: stack);
    rethrow;
  }
}
```

### ❌ Creating Multiple Logger Instances

```dart
// Bad: Multiple instances (defeats singleton)
class Service {
  final logger = Logger(LoggerConfig.debug());  // New instance each time!
}

// Good: Use singleton
class Service {
  final _logger = Logger();  // Gets singleton instance
}
```

## Performance Considerations

### 1. Use Appropriate Log Levels

```dart
// Production config with INFO level filters out debug/verbose automatically
final logger = Logger(LoggerConfig.production());

// These won't be processed in production:
logger.verbose('PERF', 'Detailed trace');  // Skipped
logger.debug('PERF', 'Debug info');        // Skipped

// These will be logged:
logger.info('PERF', 'Operation completed');
logger.error('PERF', 'Failed', error: e);
```

### 2. Avoid Expensive Operations in Log Calls

```dart
// Bad: Expensive serialization even if not logged
logger.debug('DATA', 'Processing: ${largeObject.toJson()}');

// Good: Check level first (or rely on filtering)
if (LogLevel.debug.isEnabled(logger.config.minLevel)) {
  logger.debug('DATA', 'Processing: ${largeObject.toJson()}');
}

// Better: Use lazy evaluation with data parameter
logger.debug('DATA', 'Processing', data: {
  'itemCount': largeObject.items.length,  // Cheap summary
});
```

### 3. Enable File Rotation

```dart
// Good: Prevents unlimited disk usage
final logger = Logger(LoggerConfig(
  minLevel: LogLevel.info,
  enableFile: true,
  enableRotation: true,
  maxFileSizeMB: 10,  // Rotate at 10MB
  maxFileCount: 5,    // Keep 5 files max
));
```

## Testing with Logger

### 1. Use Console-Only Config for Tests

```dart
void main() {
  setUp(() {
    Logger.reset(LoggerConfig.consoleOnly(level: LogLevel.warning));
  });

  test('user service test', () {
    // Test code - only warnings/errors logged to console
  });
}
```

### 2. Silence Logger in Tests

```dart
void main() {
  setUp(() {
    // Silent config: errors only, no output
    Logger.reset(LoggerConfig(
      minLevel: LogLevel.error,
      enableConsole: false,
      enableFile: false,
    ));
  });
}
```

## Troubleshooting

### Logs Not Appearing

**Check:** Log level filtering

```dart
// If logger config has minLevel: LogLevel.info,
// then debug/verbose won't appear
logger.debug('TEST', 'Not visible');  // Filtered
logger.info('TEST', 'Visible');       // Shown
```

### File Output Not Working

**Check:** File permissions and path

```dart
final config = LoggerConfig.production(
  logDirectory: '/var/logs/myapp',  // Ensure writable
);
```

### Performance Issues

**Check:** Console/file configuration in production

```dart
// Production should disable console for performance
final config = LoggerConfig.production();  // console disabled by default
```

## Summary

**Key Takeaways:**

- Use appropriate log levels (debug for dev, info for prod)
- Structure data with `data` parameter
- Always log errors with error object and stack trace
- Use consistent category naming
- Dispose logger for graceful file cleanup
- Leverage configuration presets
- Avoid over-logging and sensitive data
- Enable file rotation in production
