# xsoulspace_lints Installation

## Context

Install xsoulspace_lints package for Dart/Flutter projects to enforce code quality standards.

## Prerequisites

- Dart SDK installed
- Existing Dart or Flutter project
- `pubspec.yaml` file present

## Installation Steps

### 1. Add Dependency

Add to `pubspec.yaml` under `dev_dependencies`:

```yaml
dev_dependencies:
  xsoulspace_lints: ^3.0.0
```

### 2. Create Analysis Options

Create or update `analysis_options.yaml` in project root:

```yaml
include: package:xsoulspace_lints/all.yaml
```

For Flutter projects, use:

```yaml
include: package:xsoulspace_lints/flutter.yaml
```

### 3. Install Package

```bash
dart pub get
# or for Flutter
flutter pub get
```

## Validation

### Check Installation

```bash
dart pub deps | grep xsoulspace_lints
```

Expected: Should show xsoulspace_lints in dependency tree

### Run Analysis

```bash
dart analyze
# or
flutter analyze
```

Expected: Linter should run with xsoulspace_lints rules

## Integration Points

- **analysis_options.yaml** - Lint rule configuration
- **pubspec.yaml** - Package dependency
- **IDE/Editor** - Real-time linting feedback
- **CI/CD** - Automated code quality checks

## Configuration Options

### Customize Rules

To override specific rules, add to `analysis_options.yaml`:

```yaml
include: package:xsoulspace_lints/all.yaml

linter:
  rules:
    # Disable specific rules
    avoid_print: false
```

### Severity Levels

Adjust error severity:

```yaml
analyzer:
  errors:
    missing_required_param: error
    missing_return: warning
```

## Common Issues

**Issue**: Package not found
**Solution**: Run `dart pub get` or check internet connection

**Issue**: Too many lint errors
**Solution**: Start with basic rules, gradually enable stricter ones

**Issue**: Rule conflicts with existing code style
**Solution**: Override specific rules in analysis_options.yaml

## Next Steps

After installation:

1. Run `dart analyze` to see current issues
2. Fix high-priority errors first
3. Configure custom rules if needed
4. Integrate into CI/CD pipeline
5. Refer to ae_use.md for usage patterns
