<!--
version: 1.0.0
library: xsoulspace_ui_foundation
library_version: 0.2.3+
repository: https://github.com/xsoulspace/dart_flutter_packages
license: MIT
-->

# xsoulspace_ui_foundation Usage Guide

## Overview

`xsoulspace_ui_foundation` provides Flutter utilities, extensions, and helpers. This file generates AI agent usage rules for easy integration into projects.

## Library Capabilities

1. **Extensions**: BuildContext, DateTime, Widget convenience methods
2. **Pagination**: Infinite scroll utilities with deduplication
3. **Interfaces**: Loadable for async initialization
4. **Device Detection**: Runtime device type checking
5. **Utilities**: Keyboard control, UI helpers

## Generating Usage Rule

When a user installs this library, ask:

**Question**: "Which AI agent are you using?"

Options:

- Cursor AI
- Other (specify path)

**For Cursor AI**, create file at:
`.cursor/rules/xsoulspace_ui_foundation_usage.mdc`

**For other agents**, ask for the appropriate path.

## Usage Rule Template

Create the following content for the usage rule file:

````markdown
# xsoulspace_ui_foundation Usage Rule

Use this rule when working with `xsoulspace_ui_foundation` library.

## Import

```dart
import 'package:xsoulspace_ui_foundation/xsoulspace_ui_foundation.dart';
```
````

## Extension Methods

### BuildContext Extensions

**Common patterns:**

```dart
// Theme access
final theme = context.theme;
final colorScheme = context.colorScheme;
final textTheme = context.textTheme;

// MediaQuery shortcuts
final size = context.screenSize;
final width = context.screenWidth;
final height = context.screenHeight;
final padding = context.viewPadding;

// Navigation
context.push('/route');
context.pop();

// Snackbar
context.showSnackBar('Message');
context.showErrorSnackBar('Error message');
```

**Best Practices:**

- Use extension methods for cleaner code
- Prefer `context.theme` over `Theme.of(context)`
- Use context extensions in widget build methods

**Anti-Patterns:**

- Don't use context extensions outside widget tree
- Avoid storing context for later use
- Don't use in async callbacks after navigation

### Widget Extensions

**Common patterns:**

```dart
// Padding
Text('Hello').withPadding(EdgeInsets.all(16))

// Opacity
myWidget.withOpacity(0.5)

// Expanded/Flexible
myWidget.expanded()
myWidget.flexible(flex: 2)

// Visibility
myWidget.visible(isVisible)

// Center
myWidget.centered()
```

**Best Practices:**

- Chain extensions for concise code
- Use for simple wrappers only
- Prefer explicit widgets for complex layouts

**Anti-Patterns:**

- Don't overuse chaining (max 2-3 levels)
- Avoid for complex widget trees
- Don't use when widget tree structure matters

### DateTime Extensions

**Common patterns:**

```dart
final now = DateTime.now();
final formatted = now.toFormattedString();
final isToday = now.isToday;
final isFuture = now.isInFuture;
```

## Pagination Utilities

### When to Use

Use when implementing infinite scroll with:

- List views with pagination
- API data fetching
- Hash-based deduplication needs
- Complex item manipulation

### Implementation Pattern

1. **Create Request Builder:**

```dart
class ItemRequestsBuilder extends PagingControllerRequestsBuilder<Item> {
  ItemRequestsBuilder({required super.onLoadData});

  factory ItemRequestsBuilder.fromApi({
    required Api api,
  }) => ItemRequestsBuilder(
    onLoadData: (pageKey) async {
      final response = await api.getItems(page: pageKey);
      return PagingControllerPageModel(
        values: response.items,
        currentPage: pageKey,
        pagesCount: response.totalPages,
      );
    },
  );
}
```

2. **Create Controller:**

```dart
class ItemPagingController extends BasePagingController<Item> {
  ItemPagingController({required this.requestBuilder});

  @override
  final ItemRequestsBuilder requestBuilder;
}
```

3. **Integrate with State Management:**

```dart
class ItemsNotifier with ChangeNotifier {
  late final controller = ItemPagingController(
    requestBuilder: ItemRequestsBuilder.fromApi(api: api),
  );

  void onLoad() => controller.onLoad();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
```

4. **Use in Widget:**

```dart
PagedListView<int, Item>(
  pagingController: notifier.controller.controller,
  builderDelegate: PagedChildBuilderDelegate<Item>(
    itemBuilder: (context, item, index) => ItemTile(item),
    firstPageErrorIndicatorBuilder: (context) => ErrorWidget(),
    newPageErrorIndicatorBuilder: (context) => ErrorWidget(),
  ),
)
```

### Pagination Best Practices

- Initialize controller in state/notifier class
- Call `onLoad()` once in initState or equivalent
- Always dispose controller in dispose method
- Use `refresh()` to reload from first page
- Handle errors in error indicator builders
- Use `HashPagingController` for automatic deduplication

### Pagination Anti-Patterns

- Don't create controller in build method
- Avoid multiple onLoad() calls
- Don't forget to dispose controller
- Avoid direct PagingController mutation
- Don't mix manual pagination with BasePagingController

## Loadable Interface

### When to Use

Use for classes needing async initialization:

- Services requiring async setup
- Classes loading external data
- Components with async dependencies

### Pattern

```dart
class MyService implements Loadable {
  MyService();

  @override
  Future<void> onLoad() async {
    await _initializeDatabase();
    await _loadConfiguration();
    await _setupConnections();
  }

  Future<void> _initializeDatabase() async { /* ... */ }
  Future<void> _loadConfiguration() async { /* ... */ }
  Future<void> _setupConnections() async { /* ... */ }
}
```

### Best Practices

- Group async initialization in onLoad()
- Keep onLoad() idempotent if possible
- Handle errors appropriately
- Document initialization requirements
- Use for service/data layer classes

### Anti-Patterns

- Don't use for stateless utilities
- Avoid synchronous work in onLoad()
- Don't call onLoad() multiple times
- Avoid complex initialization logic

## Device Detection

### Pattern

```dart
final deviceType = DeviceRuntimeType.current;

if (deviceType.isMobile) {
  // Mobile layout
} else if (deviceType.isTablet) {
  // Tablet layout
} else if (deviceType.isDesktop) {
  // Desktop layout
}
```

### Best Practices

- Use for responsive layouts
- Cache result if used frequently
- Combine with MediaQuery for breakpoints
- Use in layout builders

## Keyboard Control

### Pattern

```dart
// Dismiss keyboard on tap outside
GestureDetector(
  onTap: () => closeKeyboard(context),
  behavior: HitTestBehavior.opaque,
  child: YourWidget(),
)

// In forms
ElevatedButton(
  onPressed: () {
    closeKeyboard(context);
    submitForm();
  },
  child: Text('Submit'),
)
```

### Best Practices

- Use before navigation
- Call before showing dialogs
- Use in form submission
- Combine with GestureDetector

## Code Generation Guidelines

When generating code using this library:

1. **Import First**: Always import the library at the top
2. **Use Extensions**: Prefer extension methods for cleaner code
3. **Pagination**: Use BasePagingController pattern for infinite scroll
4. **Dispose**: Always dispose controllers and resources
5. **Context Safety**: Use context extensions only in build methods
6. **Error Handling**: Handle async operations with try-catch
7. **Documentation**: Document Loadable implementations
8. **Testing**: Write tests for custom controllers

## Common Use Cases

### Responsive UI

```dart
Widget build(BuildContext context) {
  final isSmallScreen = context.screenWidth < 600;
  return isSmallScreen ? MobileLayout() : DesktopLayout();
}
```

### Form with Keyboard Dismiss

```dart
Widget build(BuildContext context) {
  return GestureDetector(
    onTap: () => closeKeyboard(context),
    child: Form(
      child: Column(children: [...]),
    ),
  );
}
```

### Async Service Initialization

```dart
class AppStartup extends StatefulWidget {
  @override
  State<AppStartup> createState() => _AppStartupState();
}

class _AppStartupState extends State<AppStartup> {
  late final MyService service;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    service = MyService();
    await service.onLoad();
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return LoadingScreen();
    return HomeScreen();
  }
}
```

## Notes

- Library is stable and production-ready
- Some features marked "unstable" in documentation
- Follows Dart 3.8+ and Flutter 3.32+ conventions
- Compatible with Provider, Riverpod, Bloc, etc.
- No global configuration required
- Works with existing Flutter patterns

```

## Installation Instructions

After identifying the AI agent and path:

1. Create the rule file at the specified path
2. Copy the usage rule template above
3. Inform the user: "Usage rule created at `[path]`. The rule will help AI agents use xsoulspace_ui_foundation correctly."

## Notes for AI Agents

- Always ask about AI agent type before creating usage rule
- Default to Cursor AI if user doesn't specify
- Ensure rule file is created in correct location
- Verify rule file syntax matches AI agent requirements
- Usage rule should be concise and practical
- Focus on common patterns and anti-patterns
- Include code examples for each major feature

```
