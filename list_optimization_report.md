# CardWizz List Optimization Report
Generated on 2025-03-05 19:11:17.147394

## Summary
- Files scanned: 106
- Total issues found: 6
- High priority issues: 0
- Medium priority issues: 1
- Low priority issues: 5

## Medium Priority Issues
### ListView without builder in `/lib/screens/settings_screen.dart`
- **Line**: 21
- **Code**: `body: ListView(`


## Optimization Guide
### Converting ListView to ListView.builder
```dart
// Before
ListView(
  children: [
    Item1(),
    Item2(),
    // more items
  ],
)

// After
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return items[index];
  },
)
```
