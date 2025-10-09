# xsoulspace_lints Usage Guide

## Overview

Guide for using xsoulspace_lints effectively in Dart/Flutter projects for code quality enforcement.

## Quick Reference

### Check Lint Status

```bash
dart analyze
# or
flutter analyze
```

### Fix Auto-fixable Issues

```bash
dart fix --apply
# or
flutter fix --apply
```

### Run in CI/CD

```bash
dart analyze --fatal-infos
```

## Common Usage Patterns

### 1. Daily Development

**Run analysis before commits:**

```bash
git add .
dart analyze
git commit -m "message"
```

**Fix issues automatically:**

```bash
dart fix --dry-run  # Preview fixes
dart fix --apply    # Apply fixes
```

### 2. IDE Integration

Most IDEs auto-detect analysis_options.yaml and show:

- Real-time lint warnings
- Quick fixes
- Code suggestions

**VS Code**: Install Dart/Flutter extension
**IntelliJ/Android Studio**: Built-in support

### 3. CI/CD Integration

**GitHub Actions:**

```yaml
- name: Analyze code
  run: dart analyze --fatal-infos
```

**GitLab CI:**

```yaml
lint:
  script:
    - dart analyze --fatal-infos
```

### 4. Custom Rule Configuration

**Disable specific rules:**

```yaml
include: package:xsoulspace_lints/all.yaml

linter:
  rules:
    avoid_print: false
    prefer_const_constructors: false
```

**Adjust severity:**

```yaml
analyzer:
  errors:
    todo: ignore
    invalid_annotation_target: warning
```

**Exclude files/folders:**

```yaml
analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
    - "lib/generated/**"
```

## Best Practices

### For Teams

1. **Consistent Configuration**: Use same analysis_options.yaml across team
2. **Pre-commit Hooks**: Run analysis before allowing commits
3. **CI Enforcement**: Fail builds on lint errors
4. **Regular Reviews**: Review and update rules periodically

### For Individual Developers

1. **Fix Incrementally**: Don't try to fix all warnings at once
2. **Understand Rules**: Learn why rules exist before disabling
3. **Use Auto-fix**: Let `dart fix` handle mechanical changes
4. **IDE Feedback**: Pay attention to real-time warnings

### For Legacy Projects

1. **Start Lenient**: Begin with recommended rules
2. **Gradually Strict**: Enable stricter rules over time
3. **Exclude Generated**: Skip generated code from analysis
4. **Prioritize**: Fix critical issues first

## Rule Categories

### Code Style

- Formatting consistency
- Naming conventions
- Import organization

### Best Practices

- Null safety
- Error handling
- Resource management

### Performance

- Unnecessary computations
- Inefficient patterns
- Memory leaks

### Security

- Unsafe patterns
- Data exposure
- Validation issues

## Advanced Usage

### Ignore Specific Warnings

**Single line:**

```dart
// ignore: rule_name
problematicCode();
```

**File-wide:**

```dart
// ignore_for_file: rule_name
```

**Block:**

```dart
// ignore: rule_name
void problematicFunction() {
  // code
}
```

### Custom Lint Rules

For project-specific rules, create custom analyzer plugins (advanced).

### Performance Analysis

Combine with other tools:

```bash
dart analyze
dart format --set-exit-if-changed .
dart test --coverage
```

## Troubleshooting

### Issue: Too Many Warnings

**Solution**:

1. Start with basic rules
2. Fix category by category
3. Use `dart fix --apply` for auto-fixable issues

### Issue: False Positives

**Solution**:

1. Review rule documentation
2. Use `// ignore:` if truly false positive
3. Report bug to package maintainer

### Issue: Performance Impact

**Solution**:

1. Exclude large generated files
2. Reduce analysis scope
3. Update to latest analyzer version

### Issue: Conflicts with Formatter

**Solution**:

1. Run `dart format` after `dart fix`
2. Ensure consistent tool versions
3. Check rule compatibility

## Integration Examples

### Pre-commit Hook (Git)

```bash
#!/bin/sh
dart analyze --fatal-infos || exit 1
dart format --set-exit-if-changed . || exit 1
```

### VS Code Task

```json
{
  "label": "Analyze & Fix",
  "type": "shell",
  "command": "dart analyze && dart fix --apply"
}
```

### Makefile Target

```makefile
lint:
	dart analyze --fatal-infos
	dart format --set-exit-if-changed .
```

## Metrics and Reporting

### Generate Reports

```bash
dart analyze > analysis_report.txt
```

### Track Progress

- Count warnings over time
- Monitor fix rate
- Measure code quality trends

## Related Tools

- **dart format**: Code formatting
- **dart fix**: Auto-fix issues
- **pana**: Package analysis
- **dart_code_metrics**: Advanced metrics

## Resources

- [Package Documentation](https://pub.dev/packages/xsoulspace_lints)
- [Dart Linter Rules](https://dart.dev/tools/linter-rules)
- [Effective Dart](https://dart.dev/guides/language/effective-dart)

## Quick Tips

1. Run analysis frequently during development
2. Fix warnings before they accumulate
3. Use IDE feedback for immediate corrections
4. Keep rules configuration in version control
5. Document team-specific rule decisions
6. Review and update rules quarterly
7. Train team members on common patterns
8. Automate enforcement in CI/CD
