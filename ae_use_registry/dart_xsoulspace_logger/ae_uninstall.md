<!--
version: 1.0.0
library: xsoulspace_logger
license: MIT
-->

# xsoulspace_logger Uninstallation Guide

## Overview

This guide provides step-by-step instructions to cleanly remove xsoulspace_logger from your project, reversing all integrations and restoring the original state.

## Pre-Uninstallation

### 1. Backup Logs (Optional)

If preserving log history:

```bash
# Copy log files before removal
cp -r /path/to/logs /path/to/backup
```

### 2. Identify Logger Usage

Search codebase for logger references:

```bash
# Find import statements
grep -r "import 'package:xsoulspace_logger" .

# Find Logger instantiation
grep -r "Logger(" .

# Find logger method calls
grep -r "\.verbose\|\.debug\|\.info\|\.warning\|\.error" . | grep -v "node_modules"
```

## Uninstallation Steps

### 1. Remove Integrations

#### A. Remove Logger Initialization

Locate and remove logger setup (typically in `main()` or app initialization):

```dart
// REMOVE:
final logger = Logger(LoggerConfig.debug());
```

#### B. Remove Logger Calls from Services

```dart
// BEFORE:
class ApiService {
  final _logger = Logger();

  Future<Response> fetchData() async {
    _logger.info('API', 'Fetching data');
    // ...
    _logger.error('API', 'Error', error: e, stackTrace: stack);
  }
}

// AFTER:
class ApiService {
  Future<Response> fetchData() async {
    // Service logic without logging
  }
}
```

#### C. Remove Logger from State Management

```dart
// BEFORE:
class AppState extends ChangeNotifier {
  final _logger = Logger();

  void updateUser(User user) {
    _logger.debug('STATE', 'Updating user', data: {'userId': user.id});
    // ...
  }
}

// AFTER:
class AppState extends ChangeNotifier {
  void updateUser(User user) {
    // State logic without logging
  }
}
```

#### D. Remove Cleanup/Dispose Calls

```dart
// REMOVE:
@override
void dispose() {
  Logger().dispose();
  super.dispose();
}

// REMOVE:
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.paused) {
    Logger().dispose();
  }
}
```

### 2. Remove Import Statements

Remove all logger imports:

```dart
// REMOVE:
import 'package:xsoulspace_logger/xsoulspace_logger.dart';
```

### 3. Remove Configuration

Delete any logger configuration files or environment variables:

```dart
// Remove custom config constants:
// static const logDirectory = '/var/logs/myapp';
```

### 4. Remove Dependency

Remove from `pubspec.yaml`:

```yaml
dependencies:
  xsoulspace_logger: ^0.1.0 # REMOVE THIS LINE
```

Update packages:

```bash
dart pub get
# or
flutter pub get
```

### 5. Clean Build Artifacts

```bash
# Dart
dart pub cache repair

# Flutter
flutter clean
flutter pub get
```

## Post-Uninstallation

### 1. Verify Removal

#### A. Check Imports

```bash
# Should return no results:
grep -r "xsoulspace_logger" . --exclude-dir=node_modules
```

#### B. Check pubspec.lock

Verify `xsoulspace_logger` is not in `pubspec.lock`:

```bash
grep "xsoulspace_logger" pubspec.lock
# Should return no results
```

#### C. Compile Check

```bash
dart analyze
# or
flutter analyze
```

Ensure no import errors or missing references.

### 2. Remove Log Files (Optional)

Clean up generated log files:

```bash
# Remove from temp directory (default location)
rm -rf /tmp/app_*.log

# Remove from custom directory
rm -rf /custom/log/path/*.log
```

### 3. Update Documentation

Remove logger references from:

- README.md
- API documentation
- Developer guides
- Setup instructions

### 4. Replace Logging (Optional)

If logging is still needed, integrate alternative:

#### Option A: Dart's print

```dart
// Simple console output
print('Application started');
```

#### Option B: Flutter's debugPrint

```dart
// Flutter-specific
debugPrint('Debug message');
```

#### Option C: Alternative Logger

```dart
// Example: logger package
import 'package:logger/logger.dart';
final logger = Logger();
logger.i('Info message');
```

## Validation

### 1. Build Verification

```bash
# Dart
dart compile exe bin/main.dart

# Flutter
flutter build apk --debug
```

### 2. Runtime Verification

Run application and verify:

- No logger-related errors
- Application functions normally
- No missing functionality due to logger removal

### 3. Code Cleanliness

Search for orphaned logger-related code:

```bash
# Look for logging-related variables
grep -r "_logger\|Logger\(\)" . --exclude-dir=node_modules

# Look for log level references
grep -r "LogLevel\|LoggerConfig" . --exclude-dir=node_modules
```

## Troubleshooting

### Import Errors After Removal

```
Error: Can't find 'package:xsoulspace_logger/xsoulspace_logger.dart'
```

**Solution**: Search for remaining import statements and remove them.

### Missing Method Errors

```
Error: The method 'info' isn't defined for the class
```

**Solution**: Remove logger method calls (`.info()`, `.error()`, etc.)

### Orphaned Variables

```
Warning: Unused local variable '_logger'
```

**Solution**: Remove unused logger instance variables.

## Rollback (If Issues Arise)

To restore logger:

1. Re-add dependency to `pubspec.yaml`
2. Run `dart pub get` or `flutter pub get`
3. Restore backed-up code with logger integrations
4. Re-initialize logger in application

## Uninstallation Checklist

- [ ] Logs backed up (if needed)
- [ ] Logger usage identified in codebase
- [ ] Logger initialization removed
- [ ] Logger calls removed from all services
- [ ] Logger calls removed from state management
- [ ] Logger calls removed from UI/error handling
- [ ] Cleanup/dispose calls removed
- [ ] Import statements removed
- [ ] Configuration removed
- [ ] Dependency removed from pubspec.yaml
- [ ] Packages updated (pub get)
- [ ] Build artifacts cleaned
- [ ] Import verification passed (no remaining references)
- [ ] pubspec.lock verified (dependency removed)
- [ ] Compilation successful (dart/flutter analyze)
- [ ] Log files removed (if desired)
- [ ] Documentation updated
- [ ] Build verification passed
- [ ] Runtime verification passed
- [ ] Code cleanliness verified (no orphaned code)

## Alternative: Disable Without Removal

If temporarily disabling logger:

```dart
// Option 1: Use silent config
Logger.reset(LoggerConfig(
  minLevel: LogLevel.error,
  enableConsole: false,
  enableFile: false,
));

// Option 2: Conditional initialization
Logger.reset(kDebugMode ? LoggerConfig.debug() : null);
```

This allows quick re-enablement without code changes.
