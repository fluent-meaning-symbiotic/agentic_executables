<!--
version: 1.0.0
library: xsoulspace_logger
license: MIT
-->

# xsoulspace_logger Update Guide

## Overview

This guide provides instructions for updating xsoulspace_logger to newer versions, handling breaking changes, and ensuring smooth version transitions.

## Pre-Update Preparation

### 1. Backup Current State

```bash
# Backup pubspec.lock
cp pubspec.lock pubspec.lock.backup

# Backup log files (if valuable)
cp -r /path/to/logs /path/to/backup/logs_$(date +%Y%m%d)

# Commit current working state
git add .
git commit -m "Backup before xsoulspace_logger update"
```

### 2. Check Current Version

```bash
# View current version
grep "xsoulspace_logger" pubspec.lock

# Or use dart/flutter
dart pub deps | grep xsoulspace_logger
flutter pub deps | grep xsoulspace_logger
```

### 3. Review Changelog

Check library CHANGELOG.md for:

- Breaking changes
- New features
- Deprecations
- Migration notes

## Update Process

### 1. Update Dependency Version

**Option A: Latest Version**

```yaml
dependencies:
  xsoulspace_logger: ^0.2.0 # Update to target version
```

**Option B: Flexible Range**

```yaml
dependencies:
  xsoulspace_logger: ^0.1.0 # Allows patch/minor updates
```

**Option C: Specific Version**

```yaml
dependencies:
  xsoulspace_logger: 0.2.0 # Exact version
```

### 2. Fetch Updated Package

```bash
dart pub upgrade xsoulspace_logger
# or
flutter pub upgrade xsoulspace_logger

# Or upgrade all packages:
dart pub upgrade
flutter pub upgrade
```

### 3. Verify New Version

```bash
grep "xsoulspace_logger" pubspec.lock
```

## Migration by Version

### From 0.0.x to 0.1.x (Example)

#### Breaking Changes

1. **Logger Singleton Pattern** (if applicable)

   ```dart
   // OLD:
   final logger = Logger.instance;

   // NEW:
   final logger = Logger();
   ```

2. **Config Constructor Changes** (if applicable)

   ```dart
   // OLD:
   LoggerConfig(level: LogLevel.debug, console: true)

   // NEW:
   LoggerConfig(minLevel: LogLevel.debug, enableConsole: true)
   ```

#### New Features

1. **Log Rotation** (if added in update)

   ```dart
   final config = LoggerConfig.production(
     enableRotation: true,
     maxFileSizeMB: 50,
     maxFileCount: 10,
   );
   ```

2. **Structured Data** (if added)
   ```dart
   logger.info('API', 'Request completed', data: {
     'endpoint': '/users',
     'duration': 123,
   });
   ```

### From 0.1.x to 0.2.x (Example)

_Version-specific migration steps will be documented here based on actual changelog_

## Re-Integration Steps

### 1. Update Import Statements (if package structure changed)

Search for outdated imports:

```bash
grep -r "xsoulspace_logger" . --include="*.dart"
```

Update if needed:

```dart
// Check if import path changed
import 'package:xsoulspace_logger/xsoulspace_logger.dart';
```

### 2. Update Configuration

Apply new configuration options:

```dart
// Add new optional parameters
final config = LoggerConfig.debug(
  logDirectory: '/var/logs',
  // New parameters (example):
  enableRotation: true,
  maxFileSizeMB: 20,
);
```

### 3. Update Logger Initialization

Verify singleton pattern or initialization:

```dart
void main() {
  // Ensure initialization matches updated API
  final logger = Logger(LoggerConfig.debug());
  runApp(MyApp());
}
```

### 4. Update Method Calls

Check for deprecated methods:

```bash
# Search for potentially deprecated patterns
grep -r "logger\." . --include="*.dart"
```

Update as needed:

```dart
// Example: If method signature changed
// OLD: logger.log('INFO', 'Message')
// NEW: logger.info('CATEGORY', 'Message')
```

### 5. Adopt New Features (Optional)

Enhance logging with new capabilities:

```dart
// Example: Use new structured logging
logger.info('API', 'Request', data: {
  'method': 'GET',
  'url': url,
  'status': 200,
});

// Example: Use new presets
final config = LoggerConfig.verbose(); // If new preset added
```

## Validation

### 1. Static Analysis

```bash
dart analyze
# or
flutter analyze
```

Resolve any warnings/errors related to logger.

### 2. Compilation Check

```bash
# Dart
dart compile exe bin/main.dart

# Flutter
flutter build apk --debug
```

### 3. Runtime Testing

Test critical logging paths:

```dart
void testLoggerUpdate() {
  final logger = Logger(LoggerConfig.consoleOnly());

  // Test all log levels
  logger.verbose('TEST', 'Verbose test');
  logger.debug('TEST', 'Debug test');
  logger.info('TEST', 'Info test');
  logger.warning('TEST', 'Warning test');
  logger.error('TEST', 'Error test');

  // Test structured data
  logger.info('TEST', 'Data test', data: {'key': 'value'});

  // Test error logging
  try {
    throw Exception('Test exception');
  } catch (e, stack) {
    logger.error('TEST', 'Exception test', error: e, stackTrace: stack);
  }
}
```

### 4. File Output Verification (if enabled)

Check log files:

- Verify format
- Check rotation (if configured)
- Ensure data integrity

### 5. Performance Check

Monitor for performance regressions:

- Log write latency
- Memory usage
- File size growth

## Troubleshooting

### Breaking Change Compilation Errors

```
Error: The method 'X' isn't defined for the class 'Logger'
```

**Solution**: Review changelog for method renames/removals and update calls.

### Configuration Errors

```
Error: The named parameter 'oldParam' isn't defined
```

**Solution**: Check `LoggerConfig` constructor for parameter changes.

### Runtime Issues

**Problem**: Logs not appearing after update

**Solution**:

1. Verify log level configuration
2. Check console/file enable flags
3. Ensure logger initialization

**Problem**: File rotation not working

**Solution**:

1. Verify `enableRotation: true`
2. Check `maxFileSizeMB` configuration
3. Ensure write permissions

### Dependency Conflicts

```
Error: Package xsoulspace_logger requires SDK version >=3.8.0
```

**Solution**: Update Dart/Flutter SDK or use compatible logger version.

## Rollback Procedure

If update causes issues:

### 1. Restore Previous Version

```yaml
# In pubspec.yaml, revert to previous version
dependencies:
  xsoulspace_logger: ^0.1.0 # Previous working version
```

### 2. Downgrade Package

```bash
dart pub downgrade xsoulspace_logger
# or
flutter pub downgrade xsoulspace_logger
```

### 3. Restore Backup

```bash
# Restore pubspec.lock
cp pubspec.lock.backup pubspec.lock

# Re-fetch packages
dart pub get
# or
flutter pub get

# Revert code changes
git revert HEAD
```

## Post-Update Tasks

### 1. Update Documentation

Document any API changes in:

- Internal developer guides
- Code comments
- README.md

### 2. Team Communication

Notify team of:

- Breaking changes
- New features to adopt
- Migration steps completed

### 3. Monitor Production

After deploying updated logger:

- Monitor log output
- Check file storage growth
- Verify error reporting
- Ensure performance acceptable

## Update Checklist

- [ ] Current state backed up (code, pubspec.lock, logs)
- [ ] Current version documented
- [ ] Changelog reviewed for breaking changes
- [ ] Target version identified
- [ ] Dependency version updated in pubspec.yaml
- [ ] Package upgraded (pub upgrade)
- [ ] New version verified in pubspec.lock
- [ ] Import statements updated (if needed)
- [ ] Configuration updated with new options
- [ ] Logger initialization updated
- [ ] Method calls updated for API changes
- [ ] New features adopted (optional)
- [ ] Static analysis passed (dart/flutter analyze)
- [ ] Compilation successful
- [ ] Runtime testing completed
- [ ] File output verified (if applicable)
- [ ] Performance validated
- [ ] Documentation updated
- [ ] Team notified
- [ ] Production monitoring planned

## Best Practices

1. **Read Changelog**: Always review before updating
2. **Test in Development**: Never update directly in production
3. **Incremental Updates**: Update one minor version at a time for major changes
4. **Backup First**: Always backup before updates
5. **Validate Thoroughly**: Test all logging paths after update
6. **Monitor Post-Deploy**: Watch for issues after production deployment
7. **Document Changes**: Keep internal docs synchronized with library version
8. **Use Version Ranges**: Allow patch updates but control major/minor updates

## Future-Proofing

To minimize update friction:

1. **Use Presets**: Rely on built-in configs that auto-update
2. **Avoid Deprecated APIs**: Migrate away from deprecated features early
3. **Follow Semantic Versioning**: Understand version implications (major.minor.patch)
4. **Subscribe to Updates**: Watch library repository for announcements
5. **Test Coverage**: Maintain tests that catch breaking changes
