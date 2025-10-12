<!--
version: 1.0.0
library: xsoulspace_logger
license: MIT
-->

# xsoulspace_logger Installation Guide

## Overview

xsoulspace_logger is a pure Dart logging library providing configurable console and file output with rotation, structured logging, and preset configurations.

## Installation

### 1. Add Dependency

Add to `pubspec.yaml`:

```yaml
dependencies:
  xsoulspace_logger: ^0.1.0
```

Or reference locally/from git as needed.

### 2. Install Packages

```bash
dart pub get
# or
flutter pub get
```

## Configuration

### 1. Import Library

```dart
import 'package:xsoulspace_logger/xsoulspace_logger.dart';
```

### 2. Choose Configuration Preset

Select appropriate preset based on environment:

- **Development**: `LoggerConfig.debug()` - Verbose console + file
- **Production**: `LoggerConfig.production()` - Info level, file only
- **Testing**: `LoggerConfig.consoleOnly()` - Console only, no files
- **Verbose**: `LoggerConfig.verbose()` - All logs, large files
- **Silent**: `LoggerConfig.silent()` - Errors only

### 3. Custom Configuration (Optional)

Create custom config for specific needs:

```dart
final config = LoggerConfig(
  minLevel: LogLevel.debug,
  enableConsole: true,
  enableFile: true,
  logDirectory: '/custom/path',
  enableRotation: true,
  maxFileSizeMB: 20,
  maxFileCount: 10,
);
```

## Integration

### 1. Initialize Logger

**Early in application lifecycle** (e.g., `main()` or app initialization):

```dart
Future<void> main() async {
  // Initialize logger singleton
  final logger = Logger(LoggerConfig.debug());
  await logger.init();

  // Rest of app initialization
}
```

**Important:** Always call `await logger.init()` immediately after creating the Logger instance. This ensures proper async initialization and prevents race conditions.

### 2. Access Logger Instance

Logger uses singleton pattern - access anywhere:

```dart
final logger = Logger();
```

### 3. Bridge to Application Layers

#### A. Service Layer

```dart
class ApiService {
  final _logger = Logger();

  Future<Response> fetchData() async {
    _logger.info('API', 'Fetching data from endpoint');
    try {
      final response = await http.get(url);
      _logger.debug('API', 'Response received', data: {'status': response.statusCode});
      return response;
    } catch (e, stack) {
      _logger.error('API', 'Request failed', error: e, stackTrace: stack);
      rethrow;
    }
  }
}
```

#### B. State Management

```dart
class AppState extends ChangeNotifier {
  final _logger = Logger();

  void updateUser(User user) {
    _logger.debug('STATE', 'Updating user', data: {'userId': user.id});
    // Update logic
    notifyListeners();
  }
}
```

#### C. UI Layer (Error Boundaries)

```dart
class ErrorHandler {
  static void handleError(Object error, StackTrace stack) {
    Logger().error('UI', 'Unhandled error', error: error, stackTrace: stack);
    // Show error UI
  }
}
```

### 4. Cleanup Integration

For applications with defined lifecycle (e.g., Flutter):

```dart
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
    Logger().dispose(); // Flush file buffer
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      Logger().dispose(); // Flush on background/exit
    }
  }
}
```

## Validation

### 1. Verify Installation

```dart
import 'package:xsoulspace_logger/xsoulspace_logger.dart';

Future<void> testLogger() async {
  final logger = Logger(LoggerConfig.consoleOnly());
  await logger.init();
  logger.info('TEST', 'Logger initialized successfully');
}
```

### 2. Verify File Output (if enabled)

Check log directory:

- Default: System temp directory
- Custom: Specified `logDirectory` path

Files: `app_YYYYMMDD_HHMMSS.log`

### 3. Verify Log Levels

Test filtering by level:

```dart
final logger = Logger(LoggerConfig(
  minLevel: LogLevel.info,
  enableConsole: true,
  enableFile: false,
));
await logger.init();

logger.verbose('TEST', 'Should not appear'); // Filtered
logger.debug('TEST', 'Should not appear');   // Filtered
logger.info('TEST', 'Should appear');        // Visible
logger.warning('TEST', 'Should appear');     // Visible
logger.error('TEST', 'Should appear');       // Visible
```

### 4. Verify Rotation (if enabled)

For file output with rotation:

1. Generate logs exceeding `maxFileSizeMB`
2. Verify new log file creation
3. Check old files are maintained up to `maxFileCount`

## Troubleshooting

### File Permission Issues

Ensure write access to log directory:

- Use temp directory (default) for universal access
- For custom paths, verify permissions

### Singleton Reset

To reinitialize with new config:

```dart
await Logger.reset(newConfig);
final logger = Logger();
```

### Memory/Performance

- Use appropriate `minLevel` for production (INFO or higher)
- Enable file rotation to prevent disk bloat
- Disable console output in production for performance
- Use structured `data` maps sparingly for large objects

## Best Practices

1. **Initialize Early**: Set up logger before any other operations and always call `await logger.init()`
2. **Use Presets**: Leverage built-in configs for common scenarios
3. **Categorize**: Use consistent category names (e.g., 'API', 'DB', 'UI')
4. **Structured Data**: Prefer `data` parameter over string interpolation
5. **Error Context**: Always include error and stackTrace for exceptions
6. **Cleanup**: Call `dispose()` for graceful shutdown with file logging
7. **Level Discipline**: Use appropriate levels (debug for dev, info for prod)

## Integration Checklist

- [ ] Dependency added to pubspec.yaml
- [ ] Packages installed
- [ ] Logger initialized in main() or app setup
- [ ] **Logger.init() called after instantiation**
- [ ] Configuration preset chosen or custom config created
- [ ] Logger accessed in key application layers (services, state, UI)
- [ ] Cleanup/dispose integrated for file output
- [ ] Validation tests passed
- [ ] Log output verified (console/file as configured)
- [ ] Error handling integrated with logger
- [ ] Production configuration reviewed (levels, file rotation)
