# xsoulspace_lints Installation Guide

This document provides AI agents with step-by-step instructions to install, configure, and integrate `xsoulspace_lints` into a Dart/Flutter project.

## Overview

`xsoulspace_lints` is a configuration package providing strict lint rules for Dart and Flutter projects. It offers three rule configurations:

- `app.yaml` - For application development
- `library.yaml` - For monorepo/internal libraries
- `public_library.yaml` - For packages published to pub.dev

## Prerequisites Check

Before installation, verify:

1. Project has `pubspec.yaml` file (Dart/Flutter project)
2. Project structure indicates type (app vs library vs public package)
3. Existing `analysis_options.yaml` may need backup

## Installation Steps

### Step 1: Add Dependencies

Add to `pubspec.yaml` under `dev_dependencies`:

```yaml
dev_dependencies:
  lints: ^6.0.0
  xsoulspace_lints: ^0.1.2
```

**Agent Decision**: Check if `lints` already exists in dependencies. If present with compatible version (>=6.0.0), keep existing version. If older, update to compatible version.

### Step 2: Fetch Dependencies

Run the appropriate command based on project type:

```bash
# For Flutter projects (if flutter dependency exists in pubspec.yaml)
flutter pub get

# For Dart-only projects
dart pub get
```

**Validation**: Confirm command exits with code 0 and packages are downloaded.

### Step 3: Backup Existing Configuration

If `analysis_options.yaml` exists:

```bash
# Create backup with timestamp
cp analysis_options.yaml analysis_options.yaml.backup
```

**Note**: Store backup location for potential rollback during uninstallation.

## Configuration Steps

### Step 1: Detect Project Type

Analyze project structure to determine appropriate ruleset:

```yaml
# Detection Logic:
1. Check pubspec.yaml for 'publish_to: none' → use app.yaml or library.yaml
2. If no 'publish_to: none' → likely public package → use public_library.yaml
3. Check for Flutter SDK dependency:
  - Has flutter: dependency → application → app.yaml
  - No flutter: but has packages → library → library.yaml
4. Check directory structure:
  - Has example/ → public package → public_library.yaml
  - Has multiple packages in workspace → monorepo → library.yaml
  - Has lib/ and typical app structure → app.yaml
```

**Decision Matrix**:

- **app.yaml**: Single Flutter/Dart application, game, or app module
- **library.yaml**: Internal libraries, monorepo packages, shared modules
- **public_library.yaml**: Packages intended for pub.dev publication

**Agent Prompt**: If uncertain, ask user:

```
I detected your project as [detected_type].
Which xsoulspace_lints configuration should I use?
1. app.yaml - Application development
2. library.yaml - Internal library/monorepo
3. public_library.yaml - Public package for pub.dev
```

### Step 2: Configure analysis_options.yaml

**If analysis_options.yaml does NOT exist:**

Create new file with selected configuration:

```yaml
# analysis_options.yaml
include: package:xsoulspace_lints/app.yaml # or library.yaml or public_library.yaml

# Custom rules can be added below
# analyzer:
#   exclude:
#     - custom/path/**
#
# linter:
#   rules:
#     # Override rules here if needed
```

**If analysis_options.yaml EXISTS:**

1. Read existing content
2. Identify current `include:` statement if present
3. Replace or add `include:` at the top:

```yaml
# analysis_options.yaml
include: package:xsoulspace_lints/app.yaml # NEW/UPDATED

# ... preserve existing custom configurations below ...
```

**Merge Strategy**:

- Keep the xsoulspace_lints include at the top
- Preserve any custom `analyzer:` sections
- Preserve any custom `linter.rules:` sections
- Note: Custom rules override package rules
- Warn if conflicting rules exist

## Integration Steps

### Step 1: Run Initial Analysis

Execute analyzer to discover lint violations:

```bash
# For Flutter projects
flutter analyze

# For Dart-only projects
dart analyze
```

**Capture Output**: Count total violations, categorize by severity (error/warning/info).

### Step 2: Assess Impact

Analyze violations to create fix strategy:

```yaml
# Categorization:
1. Auto-fixable violations:
  - Missing const constructors
  - Missing trailing commas
  - Import ordering issues
  - Formatting issues

2. Manual fix violations:
  - Use of dynamic types
  - Missing return type declarations
  - BuildContext usage after async
  - Print statements in production

3. Intentional exceptions:
  - Generated code (add to analyzer.exclude)
  - Third-party code
  - Temporary debug code
```

### Step 3: Integration Strategy Selection

**Agent Decision**: Choose strategy based on violation count:

**Strategy A - Immediate Adoption** (< 50 violations):

1. Fix all violations immediately
2. Use IDE quick-fixes where possible
3. Manually fix remaining issues
4. Commit clean codebase

**Strategy B - Gradual Adoption** (50-200 violations):

1. Fix critical errors first (those breaking builds)
2. Create TODO list for warnings
3. Fix by file/module over time
4. Track progress

**Strategy C - Selective Adoption** (> 200 violations):

1. Start with new code only (use baseline)
2. Create `analysis_options.yaml` with selective rule overrides
3. Gradually enable strict rules
4. Consider using analyzer baseline feature:

```bash
# Generate baseline of existing issues to ignore
dart analyze --write-baseline
```

### Step 4: Apply Fixes

Execute chosen strategy:

```bash
# For auto-fixable issues, use IDE or CLI:
dart fix --apply  # Applies automated fixes

# For Flutter projects:
flutter analyze && dart fix --apply
```

**Validation After Each Batch**:

- Run analyzer
- Ensure build still succeeds
- Run tests if available
- Commit changes incrementally

### Step 5: Configure IDE Integration

Ensure IDE recognizes new lint rules:

**VS Code**:

- Reload window: Cmd/Ctrl + Shift + P → "Developer: Reload Window"
- Verify lints appear in Problems panel

**Android Studio / IntelliJ**:

- File → Invalidate Caches / Restart
- Verify Dart Analysis shows lints

**Cursor**:

- Reload workspace
- Check analysis server is running

## Post-Installation Validation

### Validation Checklist

1. ✅ Dependencies installed successfully

   ```bash
   # Verify package in .dart_tool/package_config.json
   grep "xsoulspace_lints" .dart_tool/package_config.json
   ```

2. ✅ Configuration active

   ```bash
   # Verify analysis_options.yaml has correct include
   head -n 5 analysis_options.yaml | grep "xsoulspace_lints"
   ```

3. ✅ Analyzer runs without errors

   ```bash
   # Should complete without crashes
   dart analyze || flutter analyze
   ```

4. ✅ Lint rules are active

   ```bash
   # Test with intentional violation (e.g., missing const)
   # Should show lint warning
   ```

5. ✅ IDE integration working
   - Open any Dart file
   - Verify lint suggestions appear
   - Test quick-fix functionality

### Success Criteria

- ✅ Package appears in dependencies
- ✅ `analysis_options.yaml` includes correct ruleset
- ✅ Analyzer executes successfully
- ✅ Lint violations are detected and displayed
- ✅ IDE shows real-time lint feedback
- ✅ Build process succeeds (with or without lint warnings)

## Rollback Procedure

If installation causes issues:

1. Restore backed-up `analysis_options.yaml`:

   ```bash
   mv analysis_options.yaml.backup analysis_options.yaml
   ```

2. Remove from `pubspec.yaml`:

   ```yaml
   # Remove these lines:
   dev_dependencies:
     xsoulspace_lints: ^0.1.2
   ```

3. Run pub get:
   ```bash
   dart pub get  # or flutter pub get
   ```

## Common Issues and Solutions

### Issue 1: Overwhelming Number of Violations

**Solution**: Use gradual adoption strategy (Strategy C above) with baseline:

```bash
dart analyze --write-baseline
```

### Issue 2: Conflicts with Existing Rules

**Solution**: Custom rules in `analysis_options.yaml` override package rules:

```yaml
include: package:xsoulspace_lints/app.yaml

linter:
  rules:
    # Disable specific rule if needed
    lines_longer_than_80_chars: false
```

### Issue 3: Generated Code Violations

**Solution**: Exclude generated files:

```yaml
include: package:xsoulspace_lints/app.yaml

analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
    - "**/*.gr.dart"
    - lib/generated_plugin_registrant.dart
```

### Issue 4: Import Style Conflicts

**Note**: `app.yaml` uses package imports, `library.yaml` uses relative imports
**Solution**: Ensure correct ruleset for project type, or override:

```yaml
linter:
  rules:
    always_use_package_imports: false # Allow relative
    prefer_relative_imports: true # Enforce relative
```

## Next Steps

After successful installation:

1. Consider generating usage rule for AI assistance:

   - See `ae_use.md` for creating `xsoulspace_lints_usage` rule
   - Place in `.cursor/rules/` or equivalent for your AI agent

2. Review specific lint rules:

   - Read `lib/app.yaml`, `lib/library.yaml`, or `lib/public_library.yaml`
   - Understand enabled rules and their purpose

3. Configure team workflow:

   - Add analyzer check to CI/CD pipeline
   - Document intentional rule overrides
   - Share lint adoption strategy with team

4. Monitor and iterate:
   - Gradually enable stricter rules
   - Adjust overrides based on team feedback
   - Keep xsoulspace_lints updated

## Summary

Installation complete when:

- ✅ Package installed via pubspec.yaml
- ✅ Appropriate ruleset configured in analysis_options.yaml
- ✅ Analyzer executes successfully
- ✅ Integration strategy chosen and executed
- ✅ IDE shows lint feedback
- ✅ Team is aware of new standards

For ongoing usage assistance, see `ae_use.md` to generate AI agent usage rules.
