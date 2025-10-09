# xsoulspace_lints Update Guide

This document provides AI agents with step-by-step instructions to update `xsoulspace_lints` from one version to another, handling breaking changes and migrations.

## Overview

Updating `xsoulspace_lints` involves:

- Version comparison and changelog review
- Dependency update
- Handling new, modified, or removed lint rules
- Re-analyzing codebase for new violations
- Migration strategy execution

## Pre-Update Assessment

### Step 1: Check Current Version

Identify currently installed version:

```bash
# Check pubspec.yaml
grep "xsoulspace_lints:" pubspec.yaml

# Check resolved version in pubspec.lock
grep -A 2 "xsoulspace_lints:" pubspec.lock | grep "version:"
```

**Store Current Version**: e.g., `0.1.0` for comparison and rollback reference.

### Step 2: Identify Target Version

Determine which version to update to:

```bash
# Check latest available version on pub.dev
dart pub outdated | grep xsoulspace_lints

# Or check pub.dev directly
# https://pub.dev/packages/xsoulspace_lints/versions
```

**Agent Decision**:

- Default: Update to latest stable version
- If user specifies: Update to specific version
- Consider: Major vs minor vs patch updates

### Step 3: Review Changelog

Read CHANGELOG.md from the package to understand changes:

```bash
# If package is cloned locally, read directly
# Otherwise, check GitHub or pub.dev

# Key sections to analyze:
# - Breaking changes
# - New lint rules added
# - Deprecated lint rules
# - Removed lint rules
# - Configuration changes
```

**What to Look For**:

- 🔴 **Breaking Changes**: Rules that will cause immediate failures
- 🟡 **New Strict Rules**: Rules that may flag existing code
- 🟢 **New Optional Rules**: Rules that can be gradually adopted
- ⚠️ **Deprecated Rules**: Rules to remove from custom overrides
- ❌ **Removed Rules**: Rules that no longer exist

### Step 4: Backup Current State

Create recovery point:

```bash
# Backup critical files
cp pubspec.yaml pubspec.yaml.pre-update-$(date +%Y%m%d)
cp pubspec.lock pubspec.lock.pre-update-$(date +%Y%m%d)
cp analysis_options.yaml analysis_options.yaml.pre-update-$(date +%Y%m%d)

# Optional: Backup entire project
# git commit -am "Backup before xsoulspace_lints update"
```

**Recommendation**: Ensure project is in version control with clean working directory.

## Update Steps

### Step 1: Update pubspec.yaml

Modify version constraint:

**Before** (example):

```yaml
dev_dependencies:
  xsoulspace_lints: ^0.1.0
```

**After** (updating to specific version):

```yaml
dev_dependencies:
  xsoulspace_lints: ^0.2.0 # or specific version
```

**Version Constraint Strategies**:

- `^0.2.0` - Allow compatible updates (0.2.x)
- `>=0.2.0 <0.3.0` - Explicit range
- `0.2.0` - Exact version (most controlled)

**Agent Recommendation**: Use caret syntax (`^`) for automatic patch updates.

### Step 2: Update Dependencies

Fetch the new version:

```bash
# For Flutter projects
flutter pub upgrade xsoulspace_lints

# For Dart-only projects
dart pub upgrade xsoulspace_lints
```

**Validation**:

- Command exits successfully (code 0)
- Check `pubspec.lock` confirms new version
- No dependency resolution conflicts

```bash
# Verify new version installed
grep -A 2 "xsoulspace_lints:" pubspec.lock | grep "version:"
```

### Step 3: Check for Required Configuration Changes

Compare current `analysis_options.yaml` with new package requirements:

**Common Changes**:

1. Include path changes (rare)
2. New recommended excludes
3. Breaking rule renames

**Agent Action**:

- Read package's `lib/app.yaml` (or library.yaml/public_library.yaml)
- Compare with previous version if available
- Identify structural changes

**If Breaking Configuration Changes**:

- Update include path if changed
- Add required excludes
- Remove references to deleted rules

## Migration Steps

### Step 1: Run Initial Analysis

Execute analyzer to discover new violations:

```bash
# Run analyzer
dart analyze > analyze_output_new_version.txt 2>&1

# For Flutter
flutter analyze > analyze_output_new_version.txt 2>&1
```

**Capture Metrics**:

- Total violation count
- New violations compared to pre-update
- Violation types (errors vs warnings vs info)

### Step 2: Categorize New Violations

Identify what changed:

```bash
# Compare with pre-update analysis (if captured)
# This shows NEW violations introduced by version update
```

**Violation Categories**:

1. **New Strict Rules Enabled**
   - Rules that didn't exist before
   - Rules promoted from warning to error
2. **Existing Code Pattern Issues**

   - Code that violates newly enabled rules
   - Technical debt now flagged

3. **False Positives**
   - Rules that don't apply to your use case
   - Rules to consider disabling

### Step 3: Choose Migration Strategy

Based on violation count and severity:

**Strategy A: Immediate Fix** (< 50 new violations)

- Fix all violations immediately
- Use automated fixes where possible
- Manually address remaining issues
- Suitable for: Minor/patch updates

**Strategy B: Gradual Adoption** (50-200 new violations)

1. Fix breaking errors immediately (build fails)
2. Create issue tracker for warnings
3. Fix by module/feature over time
4. Set deadline for completion

- Suitable for: Minor updates with many new rules

**Strategy C: Selective Enablement** (> 200 new violations)

1. Identify most valuable new rules
2. Disable others temporarily
3. Enable rules incrementally
4. Use baseline for existing violations

- Suitable for: Major version updates

**Strategy D: Baseline Approach** (Any violation count)

1. Generate baseline of current violations
2. New code must pass all rules
3. Fix existing violations opportunistically

- Suitable for: Large codebases, major updates

```bash
# Generate baseline
dart analyze --write-baseline
```

### Step 4: Handle Specific Rule Changes

#### New Rules Added

**Action**: Decide whether to adopt immediately or defer

```yaml
# analysis_options.yaml - Temporarily disable new strict rule
include: package:xsoulspace_lints/app.yaml

linter:
  rules:
    # Disable new rule until ready
    new_strict_rule_name: false
```

**Best Practice**: Document why rule is disabled and when to enable it.

#### Deprecated Rules

**Action**: Remove from custom overrides if present

```yaml
# Before:
linter:
  rules:
    old_deprecated_rule: true  # This rule is deprecated

# After: (remove it)
linter:
  rules:
    # old_deprecated_rule removed - deprecated in v0.2.0
```

#### Removed Rules

**Action**: Clean up references

```yaml
# Before:
linter:
  rules:
    removed_rule: false  # Override no longer needed

# After: (remove it)
linter:
  rules:
    # removed_rule removed - no longer exists in package
```

#### Rule Behavior Changes

**Action**: Re-evaluate code that uses changed rules

Example: Rule becomes stricter or changes enforcement scope

- Review flagged code
- Adjust code or override rule if necessary

### Step 5: Apply Automated Fixes

Use Dart's fix command for auto-fixable violations:

```bash
# Preview fixes
dart fix --dry-run

# Apply fixes
dart fix --apply

# For Flutter
flutter pub run dart fix --apply
```

**Validation**:

- Review changes before committing
- Ensure tests still pass
- Check that behavior is preserved

### Step 6: Manual Fixes

For violations requiring manual intervention:

**Common Manual Fixes**:

1. **Type Annotations**: Add explicit types where inferred types flagged
2. **Async/Await**: Fix BuildContext usage after async gaps
3. **Dynamic Types**: Replace dynamic with specific types
4. **API Changes**: Update code for any xsoulspace_lints API changes (rare)

**Recommended Approach**:

- Fix by file or module
- Run tests after each batch
- Commit incrementally

### Step 7: Update Custom Overrides

Review `analysis_options.yaml` custom rules:

```yaml
# Review these sections after update:
analyzer:
  exclude:
    # Are these still necessary?
    - generated/**

linter:
  rules:
    # Are these overrides still needed?
    some_rule: false # Why disabled? Still relevant?
```

**Agent Task**:

- Identify overrides that may be outdated
- Suggest removing unnecessary overrides
- Document necessary overrides with comments

## Post-Update Validation

### Validation Checklist

1. ✅ Version updated successfully

   ```bash
   grep -A 2 "xsoulspace_lints:" pubspec.lock | grep "version:"
   # Should show new version
   ```

2. ✅ Analyzer runs without crashes

   ```bash
   dart analyze || flutter analyze
   # Should complete (may have violations, but shouldn't crash)
   ```

3. ✅ Configuration valid

   ```bash
   # Check analysis_options.yaml has no syntax errors
   dart analyze --help >/dev/null 2>&1 && echo "Config valid ✓"
   ```

4. ✅ Project builds successfully

   ```bash
   # For Flutter
   flutter build apk --debug --dry-run

   # For Dart
   dart compile kernel bin/main.dart --output=/dev/null
   ```

5. ✅ Tests pass

   ```bash
   flutter test  # or dart test
   ```

6. ✅ IDE integration works

   - Reload workspace
   - Verify new lint rules appear
   - Test quick-fix functionality

7. ✅ CI/CD pipeline passes
   - Push to feature branch
   - Verify CI builds and analyzes successfully

### Success Criteria

- ✅ New version installed and locked
- ✅ Analysis runs without errors (warnings acceptable based on strategy)
- ✅ All tests pass
- ✅ Build succeeds
- ✅ IDE shows updated lint rules
- ✅ Migration strategy documented (if gradual)
- ✅ Team notified of changes (if applicable)

## Rollback Procedure

If update causes critical issues:

### Quick Rollback

1. Restore previous versions:

   ```bash
   # Restore backed-up files
   mv pubspec.yaml.pre-update-* pubspec.yaml
   mv pubspec.lock.pre-update-* pubspec.lock
   mv analysis_options.yaml.pre-update-* analysis_options.yaml
   ```

2. Fetch old dependencies:

   ```bash
   flutter pub get  # or dart pub get
   ```

3. Validate rollback:
   ```bash
   dart analyze
   ```

### Git Rollback

If changes were committed:

```bash
# Revert the update commit
git revert <commit_hash>

# Or reset to before update
git reset --hard HEAD~1  # Caution: loses uncommitted changes
```

### Partial Rollback

If only specific rule changes are problematic:

1. Keep new version
2. Disable problematic rules in `analysis_options.yaml`:

   ```yaml
   include: package:xsoulspace_lints/app.yaml

   linter:
     rules:
       problematic_new_rule: false
   ```

## Version-Specific Migrations

### Updating from 0.1.x to 0.2.x (Example Template)

**Breaking Changes**:

- [List specific breaking changes from CHANGELOG]
- [Rule additions that are very strict]
- [Rule removals]

**Migration Steps**:

1. [Specific step for this version]
2. [Specific step for this version]

**Expected Violations**:

- [Common violations in this migration]

**Estimated Time**: [X hours for typical project]

---

_Note: Add version-specific sections as new major versions are released_

## Best Practices

### Before Updating

1. ✅ Commit or stash all changes (clean working directory)
2. ✅ Run full test suite (ensure baseline health)
3. ✅ Review changelog for breaking changes
4. ✅ Create backups
5. ✅ Update during low-risk period (avoid major releases)

### During Update

1. ✅ Update on feature branch first
2. ✅ Run analyzer immediately after dependency update
3. ✅ Use automated fixes where possible
4. ✅ Document decisions about disabled rules
5. ✅ Test incrementally

### After Update

1. ✅ Run full test suite
2. ✅ Perform manual smoke testing
3. ✅ Update team documentation
4. ✅ Monitor for unexpected issues
5. ✅ Consider updating related packages

## Communication

### For Team Projects

After successful update, notify team:

```markdown
## xsoulspace_lints Updated: v0.1.0 → v0.2.0

**Changes**:

- [List key changes]
- [New rules enabled]
- [Rules disabled with rationale]

**Action Required**:

1. Pull latest changes
2. Run `flutter pub get`
3. Reload IDE workspace
4. Fix any new violations in your code

**Migration Strategy**: [Immediate/Gradual/Baseline]

**Questions**: [Contact person]
```

## Monitoring Post-Update

### Track Metrics

1. **Violation Trends**:

   - Count violations weekly
   - Track reduction progress
   - Celebrate milestones

2. **Team Feedback**:

   - New rules causing friction?
   - Rules providing value?
   - Adjust overrides as needed

3. **Code Quality**:
   - Fewer bugs related to flagged patterns?
   - Improved code consistency?
   - Developer experience impact?

## Summary

Update complete when:

- ✅ New version installed and verified
- ✅ Analysis runs successfully
- ✅ Build and tests pass
- ✅ Migration strategy executed or documented
- ✅ Team updated and aligned
- ✅ Rollback path confirmed
- ✅ Monitoring established (for gradual migrations)

For ongoing usage assistance with new rules, regenerate usage rules via `ae_use.md`.
