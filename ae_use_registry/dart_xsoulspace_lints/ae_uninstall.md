# xsoulspace_lints Uninstallation

## Context

Remove xsoulspace_lints from a Dart/Flutter project and restore default linting behavior.

## Prerequisites

- Project has xsoulspace_lints installed
- Backup of `analysis_options.yaml` (if needed)

## Uninstallation Steps

### 1. Remove Package Reference

Edit `pubspec.yaml`, remove from `dev_dependencies`:

```yaml
dev_dependencies:
  xsoulspace_lints: ^3.0.0 # Remove this line
```

### 2. Update Analysis Options

Edit or remove `analysis_options.yaml`:

**Option A - Remove entirely:**

```bash
rm analysis_options.yaml
```

**Option B - Remove include line:**

```yaml
# Remove or comment out:
# include: package:xsoulspace_lints/all.yaml
```

**Option C - Switch to default Dart lints:**

```yaml
include: package:lints/recommended.yaml
```

### 3. Clean Dependencies

```bash
dart pub get
# or for Flutter
flutter pub get
```

### 4. Clear Analysis Cache

```bash
# Remove analysis cache
rm -rf .dart_tool/
```

## Validation

### Verify Removal

```bash
dart pub deps | grep xsoulspace_lints
```

Expected: No output (package not found)

### Check Analysis Configuration

```bash
cat analysis_options.yaml
```

Expected: No reference to xsoulspace_lints

### Run Analysis

```bash
dart analyze
```

Expected: Analysis runs with default or alternative rules

## Cleanup Checklist

- [ ] Package removed from pubspec.yaml
- [ ] analysis_options.yaml updated or removed
- [ ] Dependencies refreshed (pub get)
- [ ] Analysis cache cleared
- [ ] No references to xsoulspace_lints in codebase
- [ ] Analysis runs successfully with new configuration

## State Restoration

### If You Need to Revert

1. Restore `pubspec.yaml` from backup/git
2. Restore `analysis_options.yaml`
3. Run `dart pub get`
4. Verify with `dart analyze`

## Files Modified

- `pubspec.yaml` - Dependency removed
- `analysis_options.yaml` - Include statement removed/modified
- `.dart_tool/` - Cache directory (regenerated)
- `pubspec.lock` - Dependency lock file (updated)

## Common Issues

**Issue**: Analysis still using old rules
**Solution**: Clear `.dart_tool/` and restart IDE

**Issue**: pubspec.lock conflicts
**Solution**: Delete pubspec.lock and run `dart pub get`

**Issue**: IDE still showing old lint warnings
**Solution**: Restart IDE or analysis server

## Next Steps

After uninstallation:

1. Verify project builds without errors
2. Review existing lint warnings (may differ)
3. Consider alternative linting packages if needed
4. Update CI/CD configuration to remove xsoulspace_lints checks
