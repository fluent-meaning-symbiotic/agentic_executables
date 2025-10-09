# xsoulspace_lints Usage Rule Generator

This document guides AI agents in creating usage rules for assisting developers working with `xsoulspace_lints` in their projects.

## Overview

This file serves as a **template** for generating AI agent-specific usage rules. After successful installation of `xsoulspace_lints`, the AI agent should:

1. Ask the user which AI agent they're using
2. Determine the appropriate rule placement
3. Generate a usage rule file from this template
4. Place it in the correct location for that AI agent

## Usage Rule Generation Process

### Step 1: Detect or Ask for AI Agent

**Agent Detection**:

```bash
# Check for AI agent configuration directories
if [ -d ".cursor" ]; then
  SUGGESTED_AGENT="Cursor"
  SUGGESTED_PATH=".cursor/rules/xsoulspace_lints_usage.md"
elif [ -d ".cline" ]; then
  SUGGESTED_AGENT="Cline"
  SUGGESTED_PATH=".cline/rules/xsoulspace_lints_usage.md"
elif [ -d ".windsurf" ]; then
  SUGGESTED_AGENT="Windsurf"
  SUGGESTED_PATH=".windsurf/rules/xsoulspace_lints_usage.md"
else
  SUGGESTED_AGENT="Generic"
  SUGGESTED_PATH=".ai/rules/xsoulspace_lints_usage.md"
fi
```

**Prompt User**:

```
I've detected you're using [SUGGESTED_AGENT].
Should I create a usage rule for xsoulspace_lints assistance?

This will help me provide better suggestions that comply with your lint rules.

Suggested location: [SUGGESTED_PATH]

Options:
1. Yes, use suggested path
2. Yes, but specify custom path
3. No, skip usage rule creation
```

### Step 2: Detect Active Ruleset

Read `analysis_options.yaml` to determine which ruleset is active:

```bash
# Extract included ruleset
if grep -q "package:xsoulspace_lints/app.yaml" analysis_options.yaml; then
  RULESET="app"
elif grep -q "package:xsoulspace_lints/library.yaml" analysis_options.yaml; then
  RULESET="library"
elif grep -q "package:xsoulspace_lints/public_library.yaml" analysis_options.yaml; then
  RULESET="public_library"
else
  RULESET="unknown"
fi
```

### Step 3: Generate Usage Rule

Create the usage rule file with content below, adapted to detected ruleset.

---

## Generated Usage Rule Template

_The following content should be placed in the AI agent's rules directory:_

````markdown
# xsoulspace_lints Usage Guide

**Active Ruleset**: [app.yaml / library.yaml / public_library.yaml]  
**Package Version**: [detected from pubspec.lock]  
**Last Updated**: [generation timestamp]

## Purpose

This rule helps AI agents provide code suggestions that comply with the strict lint rules enforced by `xsoulspace_lints` in this project.

---

## Core Principles

When suggesting or writing Dart/Flutter code, **always** adhere to the active lint rules:

### 1. Code Style

#### Constants

- **prefer_const_constructors**: Use `const` constructors whenever possible

  ```dart
  // ✅ Good
  const Text('Hello');
  const EdgeInsets.all(8.0);

  // ❌ Bad
  Text('Hello');
  EdgeInsets.all(8.0);
  ```
````

- **prefer_const_declarations**: Use `const` for immutable values

  ```dart
  // ✅ Good
  const maxRetries = 3;

  // ❌ Bad
  final maxRetries = 3;
  ```

- **prefer_const_literals_to_create_immutables**: Use const for literal collections

  ```dart
  // ✅ Good
  const colors = <Color>[Colors.red, Colors.blue];

  // ❌ Bad
  final colors = <Color>[Colors.red, Colors.blue];
  ```

#### Quotes and Strings

- **prefer_single_quotes**: Always use single quotes for strings

  ```dart
  // ✅ Good
  final message = 'Hello world';

  // ❌ Bad
  final message = "Hello world";
  ```

- **prefer_interpolation_to_compose_strings**: Use string interpolation

  ```dart
  // ✅ Good
  final greeting = 'Hello, $name!';

  // ❌ Bad
  final greeting = 'Hello, ' + name + '!';
  ```

- **avoid_escaping_inner_quotes**: Choose quote style to avoid escaping

  ```dart
  // ✅ Good
  final message = "It's a beautiful day";

  // ❌ Bad
  final message = 'It\'s a beautiful day';
  ```

#### Formatting

- **require_trailing_commas**: Add trailing commas to multi-line parameter lists

  ```dart
  // ✅ Good
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: const Text('Hello'),
    ); // Trailing comma here
  }

  // ❌ Bad
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: const Text('Hello')
    ); // No trailing comma
  }
  ```

- **lines_longer_than_80_chars**: Keep lines under 80 characters

  ```dart
  // ✅ Good
  final message = 'This is a very long message that should be '
      'broken into multiple lines for readability';

  // ❌ Bad
  final message = 'This is a very long message that should be broken into multiple lines for readability';
  ```

- **eol_at_end_of_file**: Always end files with a newline

### 2. Type Safety

#### Type Declarations

- **always_declare_return_types**: Explicitly declare return types

  ```dart
  // ✅ Good
  int calculateSum(int a, int b) {
    return a + b;
  }

  // ❌ Bad
  calculateSum(int a, int b) {
    return a + b;
  }
  ```

- **type_annotate_public_apis**: Annotate public API types

  ```dart
  // ✅ Good
  class Counter {
    int value = 0;
    void increment() => value++;
  }

  // ❌ Bad
  class Counter {
    var value = 0;  // Public field needs type
    void increment() => value++;
  }
  ```

- **avoid_annotating_with_dynamic**: Avoid explicit dynamic types

  ```dart
  // ✅ Good
  Object? parseJson(String input) => jsonDecode(input);

  // ❌ Bad
  dynamic parseJson(String input) => jsonDecode(input);
  ```

#### Avoiding Dynamic

- **avoid_dynamic_calls**: Avoid calling methods on dynamic types

  ```dart
  // ✅ Good
  void process(Object obj) {
    if (obj is String) {
      print(obj.toUpperCase()); // Type is known
    }
  }

  // ❌ Bad
  void process(dynamic obj) {
    print(obj.toUpperCase()); // Dynamic call
  }
  ```

### 3. Async/Await Safety

#### BuildContext Usage

- **use_build_context_synchronously**: Don't use context after async gaps

  ```dart
  // ✅ Good
  Future<void> loadData(BuildContext context) async {
    final data = await fetchData();
    if (!context.mounted) return;
    Navigator.pop(context);
  }

  // ❌ Bad
  Future<void> loadData(BuildContext context) async {
    final data = await fetchData();
    Navigator.pop(context); // Context used after await
  }
  ```

#### Future Handling

- **unawaited_futures**: Always await or explicitly ignore futures

  ```dart
  // ✅ Good
  await saveData();
  // or
  unawaited(saveData()); // Explicitly ignored

  // ❌ Bad
  saveData(); // Future not awaited
  ```

- **discarded_futures**: Don't discard futures from async functions

  ```dart
  // ✅ Good
  final result = await fetchData();
  processResult(result);

  // ❌ Bad
  fetchData(); // Future discarded
  ```

- **avoid_void_async**: Avoid void async functions (use Future<void>)

  ```dart
  // ✅ Good
  Future<void> initialize() async {
    await loadData();
  }

  // ❌ Bad
  void initialize() async {
    await loadData();
  }
  ```

### 4. Code Organization

#### Constructors

- **sort_constructors_first**: Place constructors before methods

  ```dart
  // ✅ Good
  class MyClass {
    const MyClass();  // Constructor first

    void myMethod() {} // Methods after
  }

  // ❌ Bad
  class MyClass {
    void myMethod() {} // Method before constructor

    const MyClass();
  }
  ```

- **sort_unnamed_constructors_first**: Default constructor before named

  ```dart
  // ✅ Good
  class MyClass {
    const MyClass();           // Default first
    const MyClass.named();     // Named after
  }
  ```

- **prefer_initializing_formals**: Use `this.` syntax in constructors

  ```dart
  // ✅ Good
  class Point {
    final int x, y;
    const Point(this.x, this.y);
  }

  // ❌ Bad
  class Point {
    final int x, y;
    const Point(int x, int y) : x = x, y = y;
  }
  ```

- **use_super_parameters**: Use super parameters in Dart 2.17+

  ```dart
  // ✅ Good
  class MyWidget extends StatelessWidget {
    const MyWidget({super.key});
  }

  // ❌ Bad
  class MyWidget extends StatelessWidget {
    const MyWidget({Key? key}) : super(key: key);
  }
  ```

#### Imports

[IF RULESET = app]

- **always_use_package_imports**: Use package: imports, not relative

  ```dart
  // ✅ Good
  import 'package:my_app/models/user.dart';

  // ❌ Bad
  import '../models/user.dart';
  ```

[IF RULESET = library]

- **prefer_relative_imports**: Use relative imports within library

  ```dart
  // ✅ Good
  import '../models/user.dart';

  // ❌ Bad (within same library)
  import 'package:my_lib/models/user.dart';
  ```

[IF RULESET = public_library]

- **prefer_relative_imports**: Use relative imports within library

  ```dart
  // ✅ Good
  import '../models/user.dart';

  // ❌ Bad (within same library)
  import 'package:my_lib/models/user.dart';
  ```

- **directives_ordering**: Order imports correctly

  ```dart
  // ✅ Good (order: dart, flutter, package, relative)
  import 'dart:async';

  import 'package:flutter/material.dart';

  import 'package:provider/provider.dart';

  import 'models/user.dart';
  ```

#### Widget Structure

- **sort_child_properties_last**: Put child/children parameters last

  ```dart
  // ✅ Good
  Container(
    padding: const EdgeInsets.all(8.0),
    color: Colors.blue,
    child: const Text('Hello'),
  )

  // ❌ Bad
  Container(
    child: const Text('Hello'),
    padding: const EdgeInsets.all(8.0),
    color: Colors.blue,
  )
  ```

### 5. Best Practices

#### Logging

- **avoid_print**: Don't use print() in production code

  ```dart
  // ✅ Good
  import 'package:logging/logging.dart';
  final _logger = Logger('MyClass');
  _logger.info('Message');

  // ❌ Bad
  print('Message');
  ```

#### Flutter Widgets

- **use_key_in_widget_constructors**: Add key parameter to widgets

  ```dart
  // ✅ Good
  class MyWidget extends StatelessWidget {
    const MyWidget({super.key});
  }

  // ❌ Bad
  class MyWidget extends StatelessWidget {
    const MyWidget();
  }
  ```

- **sized_box_for_whitespace**: Use SizedBox instead of Container for spacing

  ```dart
  // ✅ Good
  const SizedBox(width: 20, height: 20)

  // ❌ Bad
  Container(width: 20, height: 20)
  ```

- **use_colored_box**: Use ColoredBox instead of Container with only color

  ```dart
  // ✅ Good
  const ColoredBox(color: Colors.red)

  // ❌ Bad
  Container(color: Colors.red)
  ```

- **use_decorated_box**: Use DecoratedBox instead of Container with only decoration

  ```dart
  // ✅ Good
  const DecoratedBox(decoration: BoxDecoration(...))

  // ❌ Bad
  Container(decoration: const BoxDecoration(...))
  ```

#### Variables and Parameters

- **prefer_final_locals**: Use final for local variables that don't change

  ```dart
  // ✅ Good
  void example() {
    final name = 'John';
    print(name);
  }

  // ❌ Bad
  void example() {
    var name = 'John';
    print(name);
  }
  ```

- **prefer_final_parameters**: Use final for parameters (where it makes sense)

  ```dart
  // ✅ Good
  void process(final String input) {
    // input cannot be reassigned
  }
  ```

- **avoid_positional_boolean_parameters**: Use named parameters for booleans

  ```dart
  // ✅ Good
  void setVisibility({required bool isVisible}) {}
  setVisibility(isVisible: true);

  // ❌ Bad
  void setVisibility(bool isVisible) {}
  setVisibility(true); // What does true mean?
  ```

#### Error Handling

- **only_throw_errors**: Throw Error/Exception types, not arbitrary objects

  ```dart
  // ✅ Good
  throw Exception('Something went wrong');
  throw ArgumentError('Invalid value');

  // ❌ Bad
  throw 'Error message'; // Don't throw strings
  ```

- **avoid_catching_errors**: Catch Exception, not Error

  ```dart
  // ✅ Good
  try {
    riskyOperation();
  } on Exception catch (e) {
    handleException(e);
  }

  // ❌ Bad
  try {
    riskyOperation();
  } on Error catch (e) { // Errors shouldn't be caught
    handleError(e);
  }
  ```

---

## AI Assistant Guidelines

### When Writing New Code

1. **Always use const**: Start with const by default, remove only if necessary
2. **Add trailing commas**: For all multi-line parameter lists
3. **Declare types**: Especially for public APIs and return types
4. **Handle async properly**: Check context.mounted, await futures
5. **Order code**: Constructors first, imports sorted, child parameters last
6. **Use appropriate widgets**: SizedBox, ColoredBox, DecoratedBox over Container
7. **Follow import style**: [package imports for app.yaml / relative for library.yaml]

### When Fixing Lint Errors

1. **Explain the rule**: Tell user why the lint rule exists
2. **Show before/after**: Demonstrate the fix clearly
3. **Use quick fixes**: Suggest IDE quick-fix when available
4. **Batch similar fixes**: Group related violations together
5. **Justify ignores**: Only suggest `// ignore:` for legitimate exceptions

### When Suggesting Ignores

Only suggest ignoring lint rules when:

- Generated code (use analyzer.exclude instead)
- Third-party code that can't be modified
- False positive with clear justification
- Temporary technical debt with TODO

Always explain WHY the ignore is justified:

```dart
// ignore: avoid_print - Debug output in development tool
print('Debug: $value');
```

### When Refactoring

Consider lint rules when suggesting refactors:

- Extract const values to const fields
- Convert dynamic types to specific types
- Split long lines at appropriate points
- Reorder class members to match conventions
- Update import statements to match style

---

## Common Patterns

### State Management

```dart
// ✅ Good pattern with ChangeNotifier
class CounterNotifier extends ChangeNotifier {
  int _count = 0;

  int get count => _count;

  void increment() {
    _count++;
    notifyListeners();
  }
}
```

### Widget Building

```dart
// ✅ Good pattern for StatelessWidget
class MyWidget extends StatelessWidget {
  const MyWidget({
    super.key,
    required this.title,
    this.onTap,
  });

  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(title),
    );
  }
}
```

### Async Operations

```dart
// ✅ Good pattern for async with BuildContext
Future<void> loadAndNavigate(BuildContext context) async {
  try {
    final data = await fetchData();

    if (!context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => DetailScreen(data: data),
      ),
    );
  } on Exception catch (e) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
}
```

---

## Quick Reference

### Most Impactful Rules

1. `prefer_const_constructors` - Performance and consistency
2. `use_build_context_synchronously` - Prevents runtime errors
3. `always_declare_return_types` - Code clarity
4. `require_trailing_commas` - Code formatting
5. `avoid_dynamic_calls` - Type safety
6. `unawaited_futures` - Prevents missed async errors
7. `prefer_single_quotes` - Consistency
8. `sort_constructors_first` - Code organization
9. [Import rule based on ruleset] - Import consistency
10. `avoid_print` - Production code quality

### When in Doubt

- **Add const**: Default to const, remove if needed
- **Add types**: Better explicit than implicit
- **Add trailing comma**: Almost always correct for multi-line
- **Check context.mounted**: Always after await when using context
- **Use single quotes**: Default string quote style

---

## Exceptions and Overrides

Current project has these custom overrides in `analysis_options.yaml`:

[AUTO-DETECT: Read analysis_options.yaml and list any custom rule overrides]
[IF NO OVERRIDES: "No custom overrides - following all xsoulspace_lints defaults"]

---

## Maintenance

This usage rule was auto-generated from xsoulspace_lints AE template.

**To regenerate** (after package update):

1. Run package update process (see ae_update.md)
2. Request usage rule regeneration
3. Review changes in active ruleset

**To customize**:

1. Edit this file directly (will be preserved)
2. Add project-specific patterns
3. Document team conventions

---

_Generated by xsoulspace_lints AE system_  
_For installation/update/uninstall, see the `ae_use/` directory in the package_

````

---

## Post-Generation Steps

### Step 4: Create Rule File

```bash
# Create directory if it doesn't exist
mkdir -p $(dirname $SUGGESTED_PATH)

# Write generated content to file
cat > $SUGGESTED_PATH << 'EOF'
[GENERATED CONTENT FROM TEMPLATE ABOVE]
EOF
````

### Step 5: Validate Creation

```bash
# Check file exists
if [ -f "$SUGGESTED_PATH" ]; then
  echo "✅ Usage rule created successfully at $SUGGESTED_PATH"
else
  echo "❌ Failed to create usage rule"
fi
```

### Step 6: Notify User

```
✅ xsoulspace_lints usage rule created!

Location: [SUGGESTED_PATH]
Active ruleset: [app/library/public_library]

I will now use this rule to provide better code suggestions
that comply with your lint configuration.

You can customize this rule file at any time.
```

---

## Rule Maintenance

### When to Regenerate

Regenerate the usage rule when:

1. **Package updated**: New lint rules added or changed
2. **Ruleset changed**: Switched from app.yaml to library.yaml, etc.
3. **Custom overrides added**: Significant changes to analysis_options.yaml
4. **Team conventions updated**: New project-specific patterns added

### How to Regenerate

```bash
# Agent command (conceptual)
# User asks: "Regenerate xsoulspace_lints usage rule"

# Agent:
1. Re-read analysis_options.yaml
2. Detect current ruleset and version
3. Generate updated content
4. Backup existing rule: mv [path] [path].backup
5. Write new rule
6. Notify user of changes
```

---

## Integration with Other Rules

This usage rule should work alongside:

- **flutter_ui_dev** rule (Flutter widget guidelines)
- **dart_extension_type_const_models** rule (Model/DTO patterns)
- **test_guide** rule (Test writing with lint compliance)
- Any project-specific AI agent rules

Lint compliance takes precedence - this rule helps enforce consistency.

---

## Summary

This template enables AI agents to:

1. ✅ Detect user's AI agent platform
2. ✅ Identify active xsoulspace_lints ruleset
3. ✅ Generate comprehensive usage guidance
4. ✅ Place rule in correct location
5. ✅ Provide ongoing development assistance
6. ✅ Maintain rule as project evolves

The generated usage rule helps AI agents write code that passes lint checks on the first attempt, reducing friction and improving development velocity.
