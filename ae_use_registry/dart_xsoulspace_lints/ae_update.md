# xsoulspace_lints Update

## Context

Update xsoulspace_lints to latest version, handling breaking changes and new rules.

## Prerequisites

- xsoulspace_lints currently installed
- Backup or git commit of current state

## Update Steps

### 1. Check Current Version

```bash
dart pub deps | grep xsoulspace_lints
```

### 2. Update Package Version

**Option A - Latest version:**
Edit `pubspec.yaml`:

```yaml
dev_dependencies:
  xsoulspace_lints: ^3.0.0 # Update version number
```

**Option B - Use pub upgrade:**

```bash
dart pub upgrade xsoulspace_lints
# or for Flutter
flutter pub upgrade xsoulspace_lints
```

### 3. Get Updated Dependencies

```bash
dart pub get
```

### 4. Review Breaking Changes

Check changelog:

- Visit https://pub.dev/packages/xsoulspace_lints/changelog
- Review changes between versions
- Note deprecated or new rules

### 5. Update Analysis Configuration

If breaking changes affect analysis_options.yaml, update accordingly:

```yaml
include: package:xsoulspace_lints/all.yaml

# Add overrides for new rules if needed
linter:
  rules:
    new_rule_name: false # Disable temporarily if needed
```

## Migration Steps

### Run Analysis

```bash
dart analyze
```

### Address New Warnings

1. Review new lint warnings
2. Fix critical issues first
3. Suppress false positives if needed
4. Update code to comply with new rules

### Test After Update

```bash
# Run tests
dart test
# or
flutter test

# Verify build
dart compile exe bin/main.dart
# or
flutter build apk
```

## Validation

### Verify Version Update

```bash
dart pub deps | grep xsoulspace_lints
```

Expected: Shows new version number

### Check Analysis Runs

```bash
dart analyze
```

Expected: Analysis completes (may have new warnings)

### Validate Build

```bash
dart compile exe bin/main.dart
# or
flutter build --debug
```

Expected: Builds successfully

## Rollback Procedure

If update causes issues:

### 1. Revert Version

Edit `pubspec.yaml` back to previous version:

```yaml
dev_dependencies:
  xsoulspace_lints: ^2.0.0 # Previous version
```

### 2. Restore Dependencies

```bash
dart pub get
```

### 3. Verify Rollback

```bash
dart pub deps | grep xsoulspace_lints
dart analyze
```

## Common Migration Scenarios

### New Rules Added

```yaml
# Temporarily disable new rules
linter:
  rules:
    new_strict_rule: false
```

### Deprecated Rules Removed

Remove custom overrides for deprecated rules from analysis_options.yaml

### Changed Rule Behavior

Review and update code patterns that trigger modified rules

## Integration Points

- **pubspec.yaml** - Version constraint updated
- **pubspec.lock** - Locked version updated
- **analysis_options.yaml** - May need rule adjustments
- **CI/CD** - May need pipeline updates
- **IDE** - May need restart for new rules

## Best Practices

1. **Incremental Updates**: Update one major version at a time
2. **Review Changelog**: Always check breaking changes
3. **Test Thoroughly**: Run full test suite after update
4. **Team Coordination**: Update with team to avoid conflicts
5. **CI/CD First**: Test update in CI before local adoption

## Version-Specific Notes

### 3.x Updates

- New strict type checking rules
- Enhanced null safety rules
- Performance lint additions

### 2.x to 3.x Migration

- Review breaking changes in changelog
- Update any custom rule overrides
- Test null safety compliance

## Next Steps

After update:

1. Commit updated pubspec.yaml and pubspec.lock
2. Run full test suite
3. Review and fix new lint warnings
4. Update team documentation
5. Monitor for issues in CI/CD
