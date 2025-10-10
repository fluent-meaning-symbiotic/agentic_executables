<!--
version: 1.0.0
library: xsoulspace_ui_foundation
library_version: 0.2.3+
repository: https://github.com/xsoulspace/dart_flutter_packages
license: MIT
-->

# xsoulspace_ui_foundation Uninstallation Guide

## Overview

This guide provides instructions for safely removing `xsoulspace_ui_foundation` from your Flutter project, ensuring complete cleanup and restoration to the original state.

## Pre-Uninstallation Checklist

Before removing the library, identify all usage points:

1. Search for imports:

   ```bash
   grep -r "xsoulspace_ui_foundation" lib/
   ```

2. Identify key usage patterns:

   - Extension method calls (BuildContext, DateTime, Widget extensions)
   - Pagination controllers and builders
   - `Loadable` interface implementations
   - Device runtime type checks
   - Keyboard control utilities

3. Document custom implementations built on top of the library

## Uninstallation Steps

### Step 1: Remove Code Dependencies

#### 1.1 Remove Pagination Implementations

Remove all classes extending library pagination components:

- Remove `PagingControllerRequestsBuilder` implementations
- Remove `BasePagingController` or `HashPagingController` extensions
- Remove `PagingControllerPageModel` usages

Replace with:

- Direct `PagingController` from `infinite_scroll_pagination`
- Custom pagination logic
- Alternative pagination solution

#### 1.2 Replace Extension Method Calls

**BuildContext Extensions:**
Replace:

```dart
context.theme
context.screenSize
context.showSnackBar('Message')
```

With:

```dart
Theme.of(context)
MediaQuery.of(context).size
ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Message')))
```

**DateTime Extensions:**
Replace custom extensions with standard DateTime methods or create local extensions.

**Widget Extensions:**
Replace:

```dart
Text('Hello').withPadding(EdgeInsets.all(16))
```

With:

```dart
Padding(
  padding: EdgeInsets.all(16),
  child: Text('Hello'),
)
```

#### 1.3 Replace Loadable Interface

Remove `Loadable` interface from classes:

Replace:

```dart
class MyService implements Loadable {
  @override
  Future<void> onLoad() async { ... }
}
```

With:

```dart
class MyService {
  Future<void> initialize() async { ... }
  // Or use custom initialization pattern
}
```

Update all `onLoad()` calls to your new initialization method.

#### 1.4 Replace Device Runtime Type Detection

Replace:

```dart
final deviceType = DeviceRuntimeType.current;
if (deviceType.isMobile) { ... }
```

With:

```dart
import 'package:flutter/foundation.dart';

final isMobile = defaultTargetPlatform == TargetPlatform.android ||
                 defaultTargetPlatform == TargetPlatform.iOS;
```

Or use alternative device detection package.

#### 1.5 Replace Keyboard Control

Replace:

```dart
closeKeyboard(context);
```

With:

```dart
FocusScope.of(context).unfocus();
```

### Step 2: Remove Import Statements

Remove all imports of `xsoulspace_ui_foundation`:

```dart
// Remove these lines
import 'package:xsoulspace_ui_foundation/xsoulspace_ui_foundation.dart';
import 'package:xsoulspace_ui_foundation/src/extensions/extensions.dart';
import 'package:xsoulspace_ui_foundation/src/utils/infinite_scroll_pagination_utils/infinite_scroll_pagination_utils.dart';
import 'package:xsoulspace_ui_foundation/src/interfaces.dart';
```

### Step 3: Remove Dependency

Remove from `pubspec.yaml`:

```yaml
dependencies:
  # xsoulspace_ui_foundation: ^0.2.3  # Remove this line
```

### Step 4: Clean Build

Run cleanup commands:

```bash
flutter pub get
flutter clean
flutter pub get
```

## Validation

### Verify Removal

1. **Check for remaining references:**

   ```bash
   grep -r "xsoulspace_ui_foundation" lib/
   grep -r "xsoulspace_ui_foundation" test/
   ```

   Should return no results.

2. **Verify compilation:**

   ```bash
   flutter analyze
   flutter test
   ```

3. **Check dependency tree:**

   ```bash
   flutter pub deps
   ```

   Ensure `xsoulspace_ui_foundation` is not listed.

4. **Build and run application:**
   ```bash
   flutter run
   ```
   Verify app functions correctly without the library.

### Post-Uninstallation Testing

1. Test all screens/features that previously used library functionality
2. Verify pagination still works (if using alternative)
3. Check extension method replacements work correctly
4. Ensure device detection logic functions properly
5. Verify keyboard dismiss functionality works

## Rollback

If issues occur after uninstallation:

1. Re-add dependency to `pubspec.yaml`
2. Run `flutter pub get`
3. Restore removed imports
4. Revert code changes from git: `git checkout -- .`

## Cleanup Verification

Final checklist:

- [ ] All library imports removed
- [ ] Extension method calls replaced
- [ ] Pagination implementations migrated
- [ ] `Loadable` interface removed/replaced
- [ ] Device detection replaced
- [ ] Keyboard control replaced
- [ ] Dependency removed from `pubspec.yaml`
- [ ] `flutter analyze` passes
- [ ] `flutter test` passes
- [ ] Application builds and runs successfully
- [ ] All features tested and working

## Notes for AI Agents

- The library provides mostly extension methods and utilities - removal is straightforward
- Most functionality can be replaced with standard Flutter APIs
- Pagination requires migration to alternative solution or direct use of `infinite_scroll_pagination`
- No global state or configuration to clean up
- Focus on replacing extension methods with standard Flutter patterns
- Ensure all import statements are removed to avoid compilation errors
- Test thoroughly as extensions may be used throughout the codebase
