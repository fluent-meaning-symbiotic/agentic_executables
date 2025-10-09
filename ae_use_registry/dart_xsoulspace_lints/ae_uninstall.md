# xsoulspace_lints Uninstallation Guide

This document provides AI agents with step-by-step instructions to completely remove `xsoulspace_lints` from a Dart/Flutter project and restore the original state.

## Overview

Uninstallation reverses all changes made during installation:

- Removes package dependencies
- Restores or cleans `analysis_options.yaml`
- Removes generated usage rules (if created)
- Validates clean removal

## Pre-Uninstall Assessment

### Step 1: Identify Current Configuration

Check what was installed:

```bash
# Check if xsoulspace_lints is in pubspec.yaml
grep "xsoulspace_lints" pubspec.yaml

# Check analysis_options.yaml configuration
head -n 10 analysis_options.yaml | grep "xsoulspace_lints"

# Check for backup files
ls analysis_options.yaml.backup 2>/dev/null
```

### Step 2: Backup Current State

Create safety backup before uninstalling:

```bash
# Backup current analysis_options.yaml
cp analysis_options.yaml analysis_options.yaml.pre-uninstall

# Backup pubspec.yaml
cp pubspec.yaml pubspec.yaml.pre-uninstall
```

**Note**: These backups allow rollback if uninstallation needs to be reversed.

## Uninstallation Steps

### Step 1: Remove from analysis_options.yaml

**Scenario A: Only xsoulspace_lints Include (Clean Removal)**

If `analysis_options.yaml` only contains xsoulspace_lints include:

```yaml
# Current content:
include: package:xsoulspace_lints/app.yaml
# Maybe some custom rules below...
```

**Action**:

- If installation created backup (`analysis_options.yaml.backup`), restore it:
  ```bash
  mv analysis_options.yaml.backup analysis_options.yaml
  ```
- If no backup and only xsoulspace_lints configuration exists:
  - Ask user if they want to keep `analysis_options.yaml` with default lints
  - Option 1: Remove file completely (clean slate)
  - Option 2: Replace with minimal configuration:
    ```yaml
    include: package:lints/recommended.yaml
    ```

**Scenario B: Custom Rules Below Include**

If file contains custom configurations:

```yaml
# Current content:
include: package:xsoulspace_lints/app.yaml

analyzer:
  exclude:
    - custom/path/**

linter:
  rules:
    custom_rule: true
```

**Action**: Remove only the include line, preserve custom content:

```yaml
# New content:
# include: package:xsoulspace_lints/app.yaml  # Commented out or removed

analyzer:
  exclude:
    - custom/path/**

linter:
  rules:
    custom_rule: true
```

**Agent Decision**:

- If custom rules exist, suggest adding alternative include (e.g., `package:lints/recommended.yaml`)
- Preserve all custom analyzer and linter configurations
- Comment out rather than delete to allow easy re-enabling

### Step 2: Remove from pubspec.yaml

Remove `xsoulspace_lints` from `dev_dependencies`:

**Before**:

```yaml
dev_dependencies:
  lints: ^6.0.0
  xsoulspace_lints: ^0.1.2
  other_package: ^1.0.0
```

**After**:

```yaml
dev_dependencies:
  lints: ^6.0.0
  other_package: ^1.0.0
```

**Agent Decision - Handle lints package**:

- If `lints` was only added for xsoulspace_lints (check git history or ask):
  - **Option A**: Keep it (safe default, provides basic linting)
  - **Option B**: Remove it too (complete removal)
- If `lints` existed before xsoulspace_lints, keep it
- If uncertain, keep `lints` package

### Step 3: Clean Dependencies

Update dependencies to remove the package:

```bash
# For Flutter projects
flutter pub get

# For Dart-only projects
dart pub get
```

**Validation**:

- Command exits with code 0
- `xsoulspace_lints` no longer in `.dart_tool/package_config.json`
- No dependency resolution errors

### Step 4: Remove Usage Rules (If Created)

If AI usage rules were generated during installation, remove them:

**Common Locations**:

```bash
# Cursor AI
rm -f .cursor/rules/xsoulspace_lints_usage.md

# Cline
rm -f .cline/rules/xsoulspace_lints_usage.md

# Generic AI
rm -f .ai/rules/xsoulspace_lints_usage.md

# Windsurf / other
rm -f .windsurf/rules/xsoulspace_lints_usage.md
```

**Agent Action**: Search for usage rule files and remove if found.

### Step 5: Clear Analyzer Baseline (If Used)

If baseline was created during installation:

```bash
# Remove analyzer baseline file if it exists
rm -f analysis_options.baseline.json
```

## Post-Uninstall Validation

### Validation Checklist

1. ✅ Package removed from dependencies

   ```bash
   # Should return empty or not found
   grep "xsoulspace_lints" pubspec.yaml || echo "Not found ✓"
   ```

2. ✅ Configuration removed from analysis_options.yaml

   ```bash
   # Should not contain xsoulspace_lints
   grep "xsoulspace_lints" analysis_options.yaml && echo "Still present ✗" || echo "Removed ✓"
   ```

3. ✅ Package not in package config

   ```bash
   # Should return empty
   grep "xsoulspace_lints" .dart_tool/package_config.json && echo "Still present ✗" || echo "Removed ✓"
   ```

4. ✅ Analyzer runs without errors

   ```bash
   # Should complete successfully (may show different lints)
   dart analyze || flutter analyze
   ```

5. ✅ IDE integration updated

   - Reload IDE/editor workspace
   - Verify xsoulspace_lints rules no longer apply
   - Confirm basic linting still works (if lints package kept)

6. ✅ Usage rules removed

   ```bash
   # Check common locations
   find .cursor .cline .ai .windsurf -name "*xsoulspace_lints*" 2>/dev/null || echo "No usage rules found ✓"
   ```

7. ✅ Project builds successfully

   ```bash
   # For Flutter
   flutter build --debug --dry-run

   # For Dart
   dart compile kernel bin/main.dart --output=/dev/null
   ```

### Success Criteria

- ✅ No references to xsoulspace_lints in `pubspec.yaml`
- ✅ No references to xsoulspace_lints in `analysis_options.yaml`
- ✅ Package not in dependency tree
- ✅ Usage rules removed from AI agent directories
- ✅ Analyzer executes without package-related errors
- ✅ Project builds and runs successfully
- ✅ Alternative linting active (if `lints` package kept) or clean slate

## Cleanup Optional Files

Remove backup files after successful uninstallation:

```bash
# Remove pre-uninstall backups (if everything works)
rm -f analysis_options.yaml.pre-uninstall
rm -f pubspec.yaml.pre-uninstall

# Remove installation backup (if exists and uninstall successful)
rm -f analysis_options.yaml.backup
```

**Agent Recommendation**: Keep backups for 24-48 hours or until user confirms everything works.

## Rollback Procedure

If uninstallation causes issues or was done in error:

### Full Rollback

1. Restore backed-up files:

   ```bash
   # Restore analysis_options.yaml
   mv analysis_options.yaml.pre-uninstall analysis_options.yaml

   # Restore pubspec.yaml
   mv pubspec.yaml.pre-uninstall pubspec.yaml
   ```

2. Re-fetch dependencies:

   ```bash
   flutter pub get  # or dart pub get
   ```

3. Validate restoration:
   ```bash
   dart analyze  # or flutter analyze
   ```

### Partial Rollback

If only configuration needs restoration:

1. Re-add include to `analysis_options.yaml`:

   ```yaml
   include: package:xsoulspace_lints/app.yaml # or library.yaml or public_library.yaml
   ```

2. Reload IDE workspace

## Common Issues and Solutions

### Issue 1: Analyzer Shows Errors After Removal

**Cause**: Code relies on strict lint rules that are now relaxed

**Solutions**:

- Option A: Keep `lints` package for basic rules
- Option B: Add `package:lints/recommended.yaml` to analysis_options.yaml
- Option C: Fix actual code issues revealed by standard analyzer

### Issue 2: CI/CD Pipeline Fails

**Cause**: Pipeline expects certain lint rules to be enforced

**Solutions**:

- Update CI configuration to match new lint setup
- Add alternative linting package
- Adjust lint failure threshold

### Issue 3: Team Members Still Have Rules Active

**Cause**: Local IDE cache or team members haven't synced

**Solutions**:

- Commit and push changes to version control
- Notify team to run `pub get` and reload IDE
- Clear IDE caches: VS Code (reload window), IntelliJ (invalidate caches)

### Issue 4: Backup File Not Found

**Cause**: Installation didn't create backup or file was deleted

**Solutions**:

- Check version control history: `git show HEAD:analysis_options.yaml`
- Use default recommended lints configuration
- Ask user for preferred linting package

## Alternative Linting Options

After uninstalling xsoulspace_lints, consider:

### Option 1: Basic Lints (Recommended)

```yaml
# analysis_options.yaml
include: package:lints/recommended.yaml
```

Add to pubspec.yaml if not present:

```yaml
dev_dependencies:
  lints: ^6.0.0
```

### Option 2: Flutter Lints

```yaml
# analysis_options.yaml
include: package:flutter_lints/flutter.yaml
```

Add to pubspec.yaml:

```yaml
dev_dependencies:
  flutter_lints: ^5.0.0
```

### Option 3: No Linting Package (Minimal)

```yaml
# analysis_options.yaml
analyzer:
  strong-mode:
    implicit-casts: false
    implicit-dynamic: false

linter:
  rules:
    # Add only essential rules
    avoid_print: true
    prefer_const_constructors: true
```

### Option 4: Custom Configuration

Create team-specific rules without external package dependency.

## Summary

Uninstallation complete when:

- ✅ Package removed from `pubspec.yaml`
- ✅ Configuration removed from `analysis_options.yaml`
- ✅ Dependencies updated successfully
- ✅ Usage rules removed from AI directories
- ✅ Analyzer runs without xsoulspace_lints references
- ✅ Project builds and runs normally
- ✅ Alternative linting configured (if desired)
- ✅ Team notified of changes (if applicable)

The project has been successfully restored to its pre-installation state with optional alternative linting configured.
