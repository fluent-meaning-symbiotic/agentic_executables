<!--
version: 1.0.0
library: xsoulspace_ui_foundation
library_version: 0.2.3+
repository: https://github.com/xsoulspace/dart_flutter_packages
license: MIT
-->

# xsoulspace_ui_foundation Installation Guide

## Overview

`xsoulspace_ui_foundation` is a Flutter library providing shared UI utilities, extensions, and helpers including:

- BuildContext, DateTime, and Widget extensions
- Infinite scroll pagination utilities (complements `infinite_scroll_pagination`)
- Device runtime type detection
- Keyboard control utilities
- Loadable interface for async initialization

## Installation

### Step 1: Add Dependency

Add `xsoulspace_ui_foundation` to your `pubspec.yaml`:

```yaml
dependencies:
  xsoulspace_ui_foundation: ^0.2.3
```

Run dependency installation:

```bash
flutter pub get
```

### Step 2: Verify Dependencies

The library requires:

- Flutter SDK (>=3.8.1 <4.0.0)
- Dart SDK (>=3.8.1 <4.0.0)
- `infinite_scroll_pagination: ^5.1.1`
- `xsoulspace_foundation: ^0.2.2`
- `collection`, `from_json_to_json`, `is_dart_empty_or_not`

These are installed automatically with the library.

## Configuration

### Step 1: Import the Library

Import the library in your Dart files where needed:

```dart
import 'package:xsoulspace_ui_foundation/xsoulspace_ui_foundation.dart';
```

### Step 2: Optional - Selective Imports

For specific features, import only what you need:

```dart
// For extensions only
import 'package:xsoulspace_ui_foundation/src/extensions/extensions.dart';

// For pagination utilities only
import 'package:xsoulspace_ui_foundation/src/utils/infinite_scroll_pagination_utils/infinite_scroll_pagination_utils.dart';

// For interfaces only
import 'package:xsoulspace_ui_foundation/src/interfaces.dart';
```

## Integration

### Step 1: Using Extensions

Extensions are available on imported types:

**BuildContext Extensions:**

```dart
// Access theme, media query, navigator shortcuts
final theme = context.theme;
final size = context.screenSize;
context.showSnackBar('Message');
```

**DateTime Extensions:**

```dart
final date = DateTime.now();
final formatted = date.toFormattedString();
```

**Widget Extensions:**

```dart
Widget myWidget = Text('Hello')
  .withPadding(EdgeInsets.all(16))
  .withOpacity(0.8);
```

### Step 2: Implementing Pagination (Optional)

If using infinite scroll pagination:

1. Create a request builder extending `PagingControllerRequestsBuilder<T>`:

```dart
class MyItemPagingRequestsBuilder
    extends PagingControllerRequestsBuilder<MyItem> {
  MyItemPagingRequestsBuilder({required super.onLoadData});

  factory MyItemPagingRequestsBuilder.fromApi({
    required MyApi api,
  }) => MyItemPagingRequestsBuilder(
    onLoadData: (pageKey) async => api.getPaginatedItems(pageKey),
  );
}
```

2. Create a controller extending `BasePagingController<T>`:

```dart
class MyItemPagingController extends BasePagingController<MyItem> {
  MyItemPagingController({required this.requestBuilder});

  @override
  final MyItemPagingRequestsBuilder requestBuilder;
}
```

3. Integrate with state management (Provider, ChangeNotifier, etc.):

```dart
class MyNotifier with ChangeNotifier {
  late final itemPagingController = MyItemPagingController(
    requestBuilder: MyItemPagingRequestsBuilder.fromApi(api: myApi),
  );

  void onLoad() => itemPagingController.onLoad();

  @override
  void dispose() {
    itemPagingController.dispose();
    super.dispose();
  }
}
```

4. Use in widgets with `PagedListView`:

```dart
PagedListView<int, MyItem>(
  pagingController: notifier.itemPagingController.controller,
  builderDelegate: PagedChildBuilderDelegate<MyItem>(
    itemBuilder: (context, item, index) => MyItemWidget(item),
  ),
)
```

### Step 3: Using Interfaces

Implement `Loadable` for async initialization:

```dart
class MyService implements Loadable {
  @override
  Future<void> onLoad() async {
    // Initialize async resources
    await _loadConfiguration();
    await _connectToDatabase();
  }
}
```

### Step 4: Device Runtime Type Detection

```dart
final deviceType = DeviceRuntimeType.current;
if (deviceType.isMobile) {
  // Mobile-specific UI
} else if (deviceType.isDesktop) {
  // Desktop-specific UI
}
```

### Step 5: Keyboard Control

```dart
// Close keyboard when tapping outside input fields
GestureDetector(
  onTap: () => closeKeyboard(context),
  child: MyWidget(),
)
```

## Validation

### Verify Installation

1. Check that imports resolve without errors
2. Verify extensions are available on their respective types
3. For pagination: ensure `PagingController` compiles successfully
4. Run `flutter analyze` to check for issues

### Test Integration

Create a simple test to verify functionality:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:xsoulspace_ui_foundation/xsoulspace_ui_foundation.dart';

void main() {
  test('Library imports successfully', () {
    // Test that key classes are accessible
    expect(Loadable, isNotNull);
    expect(BasePagingController, isNotNull);
  });
}
```

## Troubleshooting

### Common Issues

1. **Dependency Conflicts**: Ensure Flutter/Dart SDK versions meet requirements (>=3.8.1)
2. **Import Errors**: Use correct import paths; check `pubspec.yaml` for typos
3. **Extension Not Found**: Ensure proper import of extensions file
4. **Pagination Errors**: Verify `infinite_scroll_pagination` package is installed

### Resolution Steps

1. Run `flutter pub get` to refresh dependencies
2. Run `flutter clean` and rebuild if issues persist
3. Check that all required dependencies are compatible
4. Verify import statements match library structure

## Next Steps

- Review `ae_use.md` for detailed usage patterns and best practices
- Explore example implementations in the library's example directory
- Check library documentation for advanced features
- Consider creating custom extensions following library patterns

## Notes for AI Agents

- This library emphasizes extension methods and utilities over complex state
- Integration is minimal - mostly imports and pattern adoption
- No global configuration or initialization required
- Pagination utilities require understanding of `infinite_scroll_pagination` package
- Extensions are non-breaking additions to existing Flutter types
