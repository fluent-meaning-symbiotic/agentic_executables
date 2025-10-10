<!--
version: 1.0.0
library: xsoulspace_ui_foundation
library_version: 0.2.3+
repository: https://github.com/xsoulspace/dart_flutter_packages
license: MIT
-->

# xsoulspace_ui_foundation Update Guide

## Overview

This guide helps you update `xsoulspace_ui_foundation` to newer versions, handling breaking changes and migrations.

## Pre-Update Steps

### Step 1: Backup Current State

1. Commit current changes:

   ```bash
   git add .
   git commit -m "chore: backup before xsoulspace_ui_foundation update"
   ```

2. Create a backup branch (optional):
   ```bash
   git checkout -b backup/before-ui-foundation-update
   git checkout main
   ```

### Step 2: Review Current Version

Check your current version in `pubspec.yaml`:

```yaml
dependencies:
  xsoulspace_ui_foundation: ^0.2.3 # Current version
```

### Step 3: Check Changelog

Review the library's [CHANGELOG.md](https://github.com/xsoulspace/dart_flutter_packages/blob/main/pkgs/xsoulspace_ui_foundation/CHANGELOG.md) for:

- Breaking changes
- New features
- Deprecations
- Migration notes

## Update Process

### Step 1: Update Dependency Version

Update version in `pubspec.yaml`:

```yaml
dependencies:
  xsoulspace_ui_foundation: ^0.3.0 # New version
```

### Step 2: Fetch New Version

Run dependency update:

```bash
flutter pub upgrade xsoulspace_ui_foundation
```

Or update all dependencies:

```bash
flutter pub upgrade
```

### Step 3: Clean Build

```bash
flutter clean
flutter pub get
```

## Migration Patterns

### Minor Version Updates (0.2.x → 0.2.y)

Minor updates typically include:

- Bug fixes
- New features (backwards compatible)
- Performance improvements

**Action Required:**

- Generally none
- Review changelog for new features
- Run tests to verify compatibility

### Major Version Updates (0.2.x → 0.3.x)

Major updates may include breaking changes.

#### Common Breaking Changes

**1. Extension Method Changes:**

If extension methods are renamed or removed:

```dart
// Before (0.2.x)
context.screenSize

// After (0.3.x) - hypothetical
context.mediaSize  // Renamed
```

Search and replace across codebase:

```bash
find lib/ -type f -name "*.dart" -exec sed -i '' 's/screenSize/mediaSize/g' {} +
```

**2. Pagination API Changes:**

If pagination classes change structure:

Before:

```dart
class MyPagingController extends BasePagingController<Item> {
  @override
  final requestBuilder;
}
```

After (hypothetical):

```dart
class MyPagingController extends BasePagingController<Item> {
  MyPagingController({required super.requestBuilder});
}
```

Update all controller implementations accordingly.

**3. Interface Changes:**

If `Loadable` or other interfaces change:

Before:

```dart
abstract interface class Loadable {
  Future<void> onLoad();
}
```

After (hypothetical):

```dart
abstract interface class Loadable {
  Future<void> onLoad();
  Future<void> onDispose();  // New method
}
```

Implement new required methods in all classes.

**4. Dependency Updates:**

If underlying dependencies update (e.g., `infinite_scroll_pagination`):

- Check for breaking changes in those packages
- Update your code accordingly
- Test pagination functionality thoroughly

## Version-Specific Migration Guides

### Updating from 0.1.x to 0.2.x

Changes:

- Added `xsoulspace_foundation` dependency
- Enhanced pagination utilities
- New extension methods

Migration:

1. No breaking changes reported
2. Review new features in changelog
3. Consider adopting new utilities

### Updating to 0.3.x (Future)

_This section will be updated when 0.3.x is released_

Check changelog for specific migration steps.

## Validation

### Step 1: Static Analysis

Run Flutter analyzer:

```bash
flutter analyze
```

Fix all errors and warnings related to the update.

### Step 2: Find Usage Points

Search for library usage to identify potential issues:

```bash
# Find all imports
grep -r "xsoulspace_ui_foundation" lib/

# Find extension usage patterns
grep -r "\.context\." lib/  # BuildContext extensions
grep -r "BasePagingController" lib/
grep -r "Loadable" lib/
```

### Step 3: Run Tests

Execute full test suite:

```bash
flutter test
```

Address any failing tests.

### Step 4: Manual Testing

Test key functionality:

1. Screens using extension methods
2. Pagination implementations
3. Loadable implementations
4. Device detection logic
5. Keyboard control

### Step 5: Integration Testing

If you have integration tests:

```bash
flutter test integration_test/
```

## Troubleshooting

### Dependency Conflicts

If dependency resolution fails:

1. Check Flutter/Dart SDK version requirements
2. Run:
   ```bash
   flutter pub upgrade --major-versions
   ```
3. Review conflicting dependencies in error message
4. Update other packages if needed

### Compilation Errors

1. Read error messages carefully
2. Check if APIs have changed in changelog
3. Search for deprecated methods
4. Update code to new APIs

### Runtime Issues

1. Clear all caches:
   ```bash
   flutter clean
   rm -rf build/
   flutter pub get
   ```
2. Restart IDE
3. Rebuild app from scratch

### Breaking Changes

If breaking changes are too complex:

1. Stay on current version temporarily
2. Create a migration plan
3. Test migration in separate branch
4. Review library migration guides
5. Consider creating adapter layer for gradual migration

## Rollback

If update causes critical issues:

1. Revert `pubspec.yaml` changes:

   ```bash
   git checkout pubspec.yaml pubspec.lock
   ```

2. Or manually change version back:

   ```yaml
   dependencies:
     xsoulspace_ui_foundation: ^0.2.3 # Previous version
   ```

3. Restore dependencies:

   ```bash
   flutter clean
   flutter pub get
   ```

4. Revert code changes if needed:
   ```bash
   git checkout lib/
   ```

## Post-Update Checklist

- [ ] `pubspec.yaml` updated to new version
- [ ] `flutter pub get` completed successfully
- [ ] `flutter analyze` passes with no errors
- [ ] All tests pass
- [ ] Breaking changes addressed
- [ ] New features reviewed
- [ ] Documentation updated (if needed)
- [ ] Manual testing completed
- [ ] App builds and runs successfully
- [ ] Changes committed to version control

## Best Practices

1. **Read Changelog**: Always review changelog before updating
2. **Test in Branch**: Update in separate git branch first
3. **Incremental Updates**: Update one major version at a time
4. **Test Thoroughly**: Run full test suite after update
5. **Update Dependencies**: Keep all dependencies up to date
6. **CI/CD**: Ensure CI pipeline passes before merging
7. **Monitor**: Watch for runtime issues after deployment

## Notes for AI Agents

- This library follows semantic versioning
- Extension methods are most likely to change in major updates
- Pagination utilities may evolve with underlying `infinite_scroll_pagination` package
- Breaking changes will be documented in changelog
- Most updates should be non-breaking for minor versions
- Focus on testing extension method usage after updates
- Check for deprecated APIs when updating
