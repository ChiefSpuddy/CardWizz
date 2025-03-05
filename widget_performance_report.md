# CardWizz Widget Performance Report
Generated on: 2025-03-05 19:11:15.819813

## 🔴 High Impact Issues
### Expensive operations in build method
- **File**: `/lib/screens/collection_index_screen.dart`
- **Suggestion**: Move sorting/filtering operations outside build or memoize the results

### Expensive operations in build method
- **File**: `/lib/screens/analytics_screen.dart`
- **Suggestion**: Move sorting/filtering operations outside build or memoize the results

### Expensive operations in build method
- **File**: `/lib/screens/home_overview.dart`
- **Suggestion**: Move sorting/filtering operations outside build or memoize the results

### Using ListView instead of ListView.builder
- **File**: `/lib/screens/settings_screen.dart`
- **Line**: 21
- **Suggestion**: Replace with ListView.builder for better memory usage with large lists
- **Code**: `body: ListView(`

### Using ListView instead of ListView.builder
- **File**: `/lib/screens/profile_screen.dart`
- **Line**: 442
- **Suggestion**: Replace with ListView.builder for better memory usage with large lists
- **Code**: `return ListView(`

### Expensive operations in build method
- **File**: `/lib/screens/profile_screen.dart`
- **Suggestion**: Move sorting/filtering operations outside build or memoize the results

### Using ListView instead of ListView.builder
- **File**: `/lib/screens/privacy_settings_screen.dart`
- **Line**: 41
- **Suggestion**: Replace with ListView.builder for better memory usage with large lists
- **Code**: `body: ListView(`

### Expensive operations in build method
- **File**: `/lib/screens/debug_collection_screen.dart`
- **Suggestion**: Move sorting/filtering operations outside build or memoize the results

### Expensive operations in build method
- **File**: `/lib/screens/custom_collection_detail_screen.dart`
- **Suggestion**: Move sorting/filtering operations outside build or memoize the results

### Expensive operations in build method
- **File**: `/lib/screens/mtg_card_details_screen.dart`
- **Suggestion**: Move sorting/filtering operations outside build or memoize the results

### Expensive operations in build method
- **File**: `/lib/screens/search_screen.dart`
- **Suggestion**: Move sorting/filtering operations outside build or memoize the results

### Expensive operations in build method
- **File**: `/lib/screens/pokemon_card_details_screen.dart`
- **Suggestion**: Move sorting/filtering operations outside build or memoize the results

### Expensive operations in build method
- **File**: `/lib/widgets/acquisition_timeline_chart.dart`
- **Suggestion**: Move sorting/filtering operations outside build or memoize the results

### Using ListView instead of ListView.builder
- **File**: `/lib/widgets/app_drawer.dart`
- **Line**: 157
- **Suggestion**: Replace with ListView.builder for better memory usage with large lists
- **Code**: `child: ListView(`

### Expensive operations in build method
- **File**: `/lib/widgets/app_drawer.dart`
- **Suggestion**: Move sorting/filtering operations outside build or memoize the results

### Expensive operations in build method
- **File**: `/lib/widgets/portfolio_value_chart.dart`
- **Suggestion**: Move sorting/filtering operations outside build or memoize the results

### Expensive operations in build method
- **File**: `/lib/widgets/custom_collections_grid.dart`
- **Suggestion**: Move sorting/filtering operations outside build or memoize the results

### Expensive operations in build method
- **File**: `/lib/widgets/search/card_grid.dart`
- **Suggestion**: Move sorting/filtering operations outside build or memoize the results

### Expensive operations in build method
- **File**: `/lib/widgets/create_collection_sheet.dart`
- **Suggestion**: Move sorting/filtering operations outside build or memoize the results

### Expensive operations in build method
- **File**: `/lib/widgets/collection_grid.dart`
- **Suggestion**: Move sorting/filtering operations outside build or memoize the results

### Expensive operations in build method
- **File**: `/lib/widgets/sign_in_view.dart`
- **Suggestion**: Move sorting/filtering operations outside build or memoize the results

### Expensive operations in build method
- **File**: `/lib/widgets/rarity_distribution_chart.dart`
- **Suggestion**: Move sorting/filtering operations outside build or memoize the results

### Expensive operations in build method
- **File**: `/lib/widgets/premium_dialog.dart`
- **Suggestion**: Move sorting/filtering operations outside build or memoize the results

## 🟠 Medium Impact Issues
### Using Opacity widget
- **File**: `/lib/constants/text_styles.dart`
- **Line**: 91
- **Suggestion**: Consider using AnimatedOpacity, or apply opacity to colors instead of widgets
- **Code**: `color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),`

### Using Opacity widget
- **File**: `/lib/constants/app_colors.dart`
- **Line**: 115
- **Suggestion**: Consider using AnimatedOpacity, or apply opacity to colors instead of widgets
- **Code**: `color: Colors.black.withOpacity(0.5),`

### Using Opacity widget
- **File**: `/lib/constants/card_styles.dart`
- **Line**: 10
- **Suggestion**: Consider using AnimatedOpacity, or apply opacity to colors instead of widgets
- **Code**: `color: Colors.black.withOpacity(0.1),`

### Using Opacity widget
- **File**: `/lib/utils/notification_manager.dart`
- **Line**: 31
- **Suggestion**: Consider using AnimatedOpacity, or apply opacity to colors instead of widgets
- **Code**: `child: Opacity(`

### Column without scrolling parent
- **File**: `/lib/utils/error_handler.dart`
- **Line**: 48
- **Suggestion**: Wrap with SingleChildScrollView to prevent overflow errors
- **Code**: `child: Column(`

### Using Opacity widget
- **File**: `/lib/utils/image_utils.dart`
- **Line**: 201
- **Suggestion**: Consider using AnimatedOpacity, or apply opacity to colors instead of widgets
- **Code**: `color: color?.withOpacity(0.1) ?? Colors.grey.withOpacity(0.2),`

### Using Opacity widget
- **File**: `/lib/screens/collection_index_screen.dart`
- **Line**: 72
- **Suggestion**: Consider using AnimatedOpacity, or apply opacity to colors instead of widgets
- **Code**: `color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),`

### Using Opacity widget
- **File**: `/lib/screens/analytics_screen.dart`
- **Line**: 237
- **Suggestion**: Consider using AnimatedOpacity, or apply opacity to colors instead of widgets
- **Code**: `color: isPositive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),`

### Using Opacity widget
- **File**: `/lib/screens/scanner_screen.dart`
- **Line**: 274
- **Suggestion**: Consider using AnimatedOpacity, or apply opacity to colors instead of widgets
- **Code**: `color: Colors.black.withOpacity(0.5),`

### Column without scrolling parent
- **File**: `/lib/screens/scanner_screen.dart`
- **Line**: 535
- **Suggestion**: Wrap with SingleChildScrollView to prevent overflow errors
- **Code**: `child: Column(`

### Using Opacity widget
- **File**: `/lib/screens/home_overview.dart`
- **Line**: 128
- **Suggestion**: Consider using AnimatedOpacity, or apply opacity to colors instead of widgets
- **Code**: `color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),`

### ListView.builder without keys
- **File**: `/lib/screens/home_overview.dart`
- **Suggestion**: Add keys to list items for better reconciliation

### Using Opacity widget
- **File**: `/lib/screens/base_card_details_screen.dart`
- **Line**: 195
- **Suggestion**: Consider using AnimatedOpacity, or apply opacity to colors instead of widgets
- **Code**: `color: Theme.of(context).primaryColor.withOpacity(0.3),`

### Column without scrolling parent
- **File**: `/lib/screens/base_card_details_screen.dart`
- **Line**: 141
- **Suggestion**: Wrap with SingleChildScrollView to prevent overflow errors
- **Code**: `child: Column(`

### ListView.builder without keys
- **File**: `/lib/screens/base_card_details_screen.dart`
- **Suggestion**: Add keys to list items for better reconciliation

### Using Opacity widget
- **File**: `/lib/screens/profile_screen.dart`
- **Line**: 339
- **Suggestion**: Consider using AnimatedOpacity, or apply opacity to colors instead of widgets
- **Code**: `color: colorScheme.shadow.withOpacity(0.1),`

### Column without scrolling parent
- **File**: `/lib/screens/privacy_settings_screen.dart`
- **Line**: 113
- **Suggestion**: Wrap with SingleChildScrollView to prevent overflow errors
- **Code**: `child: Column(`

### Using Opacity widget
- **File**: `/lib/screens/debug_collection_screen.dart`
- **Line**: 223
- **Suggestion**: Consider using AnimatedOpacity, or apply opacity to colors instead of widgets
- **Code**: `color: Colors.black.withOpacity(0.1),`

### For loop in build method
- **File**: `/lib/screens/collections_screen.dart`
- **Line**: 859
- **Suggestion**: Use List.generate or ListView.builder for dynamic list creation
- **Code**: `for (var option in CollectionSortOption.values)`

### Using Opacity widget
- **File**: `/lib/screens/custom_collection_detail_screen.dart`
- **Line**: 140
- **Suggestion**: Consider using AnimatedOpacity, or apply opacity to colors instead of widgets
- **Code**: `color: color.withOpacity(0.4),`

### Using Opacity widget
- **File**: `/lib/screens/mtg_card_details_screen.dart`
- **Line**: 86
- **Suggestion**: Consider using AnimatedOpacity, or apply opacity to colors instead of widgets
- **Code**: `color: Colors.black.withOpacity(0.5),`

### ListView.builder without keys
- **File**: `/lib/screens/mtg_card_details_screen.dart`
- **Suggestion**: Add keys to list items for better reconciliation

### Column without scrolling parent
- **File**: `/lib/screens/search_screen.dart`
- **Line**: 883
- **Suggestion**: Wrap with SingleChildScrollView to prevent overflow errors
- **Code**: `child: Column(`

### Using Opacity widget
- **File**: `/lib/screens/pokemon_card_details_screen.dart`
- **Line**: 216
- **Suggestion**: Consider using AnimatedOpacity, or apply opacity to colors instead of widgets
- **Code**: `color: isDark ? const Color(0xFF007D41).withOpacity(0.8) : const Color(0xFF007D41),`

### ListView.builder without keys
- **File**: `/lib/screens/pokemon_card_details_screen.dart`
- **Suggestion**: Add keys to list items for better reconciliation

### Column without scrolling parent
- **File**: `/lib/main.dart`
- **Line**: 155
- **Suggestion**: Wrap with SingleChildScrollView to prevent overflow errors
- **Code**: `child: Column(`

### For loop in build method
- **File**: `/lib/services/poke_api_service.dart`
- **Line**: 34
- **Suggestion**: Use List.generate or ListView.builder for dynamic list creation
- **Code**: `for (var i = 0; i < uncachedNumbers.length; i += _maxConcurrentRequests) {`

### For loop in build method
- **File**: `/lib/services/purchase_service.dart`
- **Line**: 73
- **Suggestion**: Use List.generate or ListView.builder for dynamic list creation
- **Code**: `for (var purchaseDetails in purchaseDetailsList) {`

### For loop in build method
- **File**: `/lib/services/tcgdex_api_service.dart`
- **Line**: 56
- **Suggestion**: Use List.generate or ListView.builder for dynamic list creation
- **Code**: `for (var set in filteredSets) {`

### For loop in build method
- **File**: `/lib/services/scanner_service.dart`
- **Line**: 35
- **Suggestion**: Use List.generate or ListView.builder for dynamic list creation
- **Code**: `for (var line in lines) {`

### Using Opacity widget
- **File**: `/lib/services/dialog_service.dart`
- **Line**: 79
- **Suggestion**: Consider using AnimatedOpacity, or apply opacity to colors instead of widgets
- **Code**: `Theme.of(context).colorScheme.secondary.withOpacity(0.8),`

### Column without scrolling parent
- **File**: `/lib/services/dialog_service.dart`
- **Line**: 68
- **Suggestion**: Wrap with SingleChildScrollView to prevent overflow errors
- **Code**: `child: Column(`

### For loop in build method
- **File**: `/lib/services/background_price_update_service.dart`
- **Line**: 101
- **Suggestion**: Use List.generate or ListView.builder for dynamic list creation
- **Code**: `for (var i = 0; i < cards.length; i++) {`

### For loop in build method
- **File**: `/lib/services/storage_service.dart`
- **Line**: 170
- **Suggestion**: Use List.generate or ListView.builder for dynamic list creation
- **Code**: `for (var i = 0; i < list1.length; i++) {`

### For loop in build method
- **File**: `/lib/services/chart_service.dart`
- **Line**: 60
- **Suggestion**: Use List.generate or ListView.builder for dynamic list creation
- **Code**: `for (var i = 1; i < points.length; i++) {`

### Using Opacity widget
- **File**: `/lib/widgets/acquisition_timeline_chart.dart`
- **Line**: 80
- **Suggestion**: Consider using AnimatedOpacity, or apply opacity to colors instead of widgets
- **Code**: `color: colorScheme.surfaceVariant.withOpacity(0.3),`

### Column without scrolling parent
- **File**: `/lib/widgets/acquisition_timeline_chart.dart`
- **Line**: 40
- **Suggestion**: Wrap with SingleChildScrollView to prevent overflow errors
- **Code**: `child: Column(`

### Using Opacity widget
- **File**: `/lib/widgets/price_update_dialog.dart`
- **Line**: 21
- **Suggestion**: Consider using AnimatedOpacity, or apply opacity to colors instead of widgets
- **Code**: `backgroundColor: Colors.white.withOpacity(0.95),`

### Column without scrolling parent
- **File**: `/lib/widgets/price_update_dialog.dart`
- **Line**: 26
- **Suggestion**: Wrap with SingleChildScrollView to prevent overflow errors
- **Code**: `child: Column(`

### Using Opacity widget
- **File**: `/lib/widgets/price_update_button.dart`
- **Line**: 93
- **Suggestion**: Consider using AnimatedOpacity, or apply opacity to colors instead of widgets
- **Code**: `color: Colors.green.withOpacity(0.2),`

### Using Opacity widget
- **File**: `/lib/widgets/theme_switcher.dart`
- **Line**: 42
- **Suggestion**: Consider using AnimatedOpacity, or apply opacity to colors instead of widgets
- **Code**: `color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),`

### Using Opacity widget
- **File**: `/lib/widgets/pokemon_set_icon.dart`
- **Line**: 67
- **Suggestion**: Consider using AnimatedOpacity, or apply opacity to colors instead of widgets
- **Code**: `color: Theme.of(context).colorScheme.primary.withOpacity(0.1),`

### Using Opacity widget
- **File**: `/lib/widgets/styled_toast.dart`
- **Line**: 51
- **Suggestion**: Consider using AnimatedOpacity, or apply opacity to colors instead of widgets
- **Code**: `color: bgColor.withOpacity(0.3),`

### Column without scrolling parent
- **File**: `/lib/widgets/styled_toast.dart`
- **Line**: 80
- **Suggestion**: Wrap with SingleChildScrollView to prevent overflow errors
- **Code**: `child: Column(`

### Using Opacity widget
- **File**: `/lib/widgets/app_drawer.dart`
- **Line**: 69
- **Suggestion**: Consider using AnimatedOpacity, or apply opacity to colors instead of widgets
- **Code**: `? Colors.black.withOpacity(0.7)`

### Column without scrolling parent
- **File**: `/lib/widgets/app_drawer.dart`
- **Line**: 130
- **Suggestion**: Wrap with SingleChildScrollView to prevent overflow errors
- **Code**: `child: Column(`

### Using Opacity widget
- **File**: `/lib/widgets/portfolio_value_chart.dart`
- **Line**: 146
- **Suggestion**: Consider using AnimatedOpacity, or apply opacity to colors instead of widgets
- **Code**: `Colors.green.shade600.withOpacity(0.4), // More visible gradient`

### Column without scrolling parent
- **File**: `/lib/widgets/portfolio_value_chart.dart`
- **Line**: 280
- **Suggestion**: Wrap with SingleChildScrollView to prevent overflow errors
- **Code**: `child: Column(`

### Column without scrolling parent
- **File**: `/lib/widgets/avatar_picker_dialog.dart`
- **Line**: 11
- **Suggestion**: Wrap with SingleChildScrollView to prevent overflow errors
- **Code**: `child: Column(`

### For loop in build method
- **File**: `/lib/widgets/custom_collections_grid.dart`
- **Line**: 319
- **Suggestion**: Use List.generate or ListView.builder for dynamic list creation
- **Code**: `for (var i = 0; i < min(3, binderCards.length); i++)`

### Using Opacity widget
- **File**: `/lib/widgets/custom_collections_grid.dart`
- **Line**: 189
- **Suggestion**: Consider using AnimatedOpacity, or apply opacity to colors instead of widgets
- **Code**: `color: binderColor.withOpacity(0.4),`

### Column without scrolling parent
- **File**: `/lib/widgets/custom_collections_grid.dart`
- **Line**: 265
- **Suggestion**: Wrap with SingleChildScrollView to prevent overflow errors
- **Code**: `child: Column(`

### Using Opacity widget
- **File**: `/lib/widgets/search/recent_searches.dart`
- **Line**: 74
- **Suggestion**: Consider using AnimatedOpacity, or apply opacity to colors instead of widgets
- **Code**: `color: Colors.black.withOpacity(0.05),`

### Column without scrolling parent
- **File**: `/lib/widgets/search/recent_searches.dart`
- **Line**: 84
- **Suggestion**: Wrap with SingleChildScrollView to prevent overflow errors
- **Code**: `child: Column(`

### Using Opacity widget
- **File**: `/lib/widgets/search/search_categories.dart`
- **Line**: 375
- **Suggestion**: Consider using AnimatedOpacity, or apply opacity to colors instead of widgets
- **Code**: `color: colorScheme.primary.withOpacity(0.8)`

### Column without scrolling parent
- **File**: `/lib/widgets/search/search_categories.dart`
- **Line**: 311
- **Suggestion**: Wrap with SingleChildScrollView to prevent overflow errors
- **Code**: `child: Column(`

### Column without scrolling parent
- **File**: `/lib/widgets/search/set_grid.dart`
- **Line**: 50
- **Suggestion**: Wrap with SingleChildScrollView to prevent overflow errors
- **Code**: `child: Column(`

### Using Opacity widget
- **File**: `/lib/widgets/search/card_grid_item.dart`
- **Line**: 65
- **Suggestion**: Consider using AnimatedOpacity, or apply opacity to colors instead of widgets
- **Code**: `Colors.black.withOpacity(0.8),`

### Column without scrolling parent
- **File**: `/lib/widgets/search/card_grid_item.dart`
- **Line**: 75
- **Suggestion**: Wrap with SingleChildScrollView to prevent overflow errors
- **Code**: `child: Column(`

### Using Opacity widget
- **File**: `/lib/widgets/search/search_categories_header.dart`
- **Line**: 37
- **Suggestion**: Consider using AnimatedOpacity, or apply opacity to colors instead of widgets
- **Code**: `: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),`

### Column without scrolling parent
- **File**: `/lib/widgets/search/search_categories_header.dart`
- **Line**: 18
- **Suggestion**: Wrap with SingleChildScrollView to prevent overflow errors
- **Code**: `child: Column(`

### Column without scrolling parent
- **File**: `/lib/widgets/search/loading_state.dart`
- **Line**: 15
- **Suggestion**: Wrap with SingleChildScrollView to prevent overflow errors
- **Code**: `child: Column(`

### Using Opacity widget
- **File**: `/lib/widgets/search/card_skeleton_grid.dart`
- **Line**: 124
- **Suggestion**: Consider using AnimatedOpacity, or apply opacity to colors instead of widgets
- **Code**: `Colors.black.withOpacity(0.7),`

### Column without scrolling parent
- **File**: `/lib/widgets/search/card_skeleton_grid.dart`
- **Line**: 129
- **Suggestion**: Wrap with SingleChildScrollView to prevent overflow errors
- **Code**: `child: Column(`

### Using Opacity widget
- **File**: `/lib/widgets/search/search_app_bar.dart`
- **Line**: 66
- **Suggestion**: Consider using AnimatedOpacity, or apply opacity to colors instead of widgets
- **Code**: `color: Colors.black.withOpacity(0.3),`

### Column without scrolling parent
- **File**: `/lib/widgets/search/search_app_bar.dart`
- **Line**: 74
- **Suggestion**: Wrap with SingleChildScrollView to prevent overflow errors
- **Code**: `child: Column(`

### Using Opacity widget
- **File**: `/lib/widgets/card_grid_item.dart`
- **Line**: 41
- **Suggestion**: Consider using AnimatedOpacity, or apply opacity to colors instead of widgets
- **Code**: `color: Colors.black.withOpacity(0.1),`

### Column without scrolling parent
- **File**: `/lib/widgets/card_grid_item.dart`
- **Line**: 108
- **Suggestion**: Wrap with SingleChildScrollView to prevent overflow errors
- **Code**: `child: Column(`

### Using Opacity widget
- **File**: `/lib/widgets/collection_grid.dart`
- **Line**: 580
- **Suggestion**: Consider using AnimatedOpacity, or apply opacity to colors instead of widgets
- **Code**: `Opacity(`

### Using Opacity widget
- **File**: `/lib/widgets/empty_collection_view.dart`
- **Line**: 261
- **Suggestion**: Consider using AnimatedOpacity, or apply opacity to colors instead of widgets
- **Code**: `colorScheme.primary.withOpacity(0.7),`

### ListView.builder without keys
- **File**: `/lib/widgets/empty_collection_view.dart`
- **Suggestion**: Add keys to list items for better reconciliation

### Using Opacity widget
- **File**: `/lib/widgets/card_back_fallback.dart`
- **Line**: 44
- **Suggestion**: Consider using AnimatedOpacity, or apply opacity to colors instead of widgets
- **Code**: `color: Colors.black.withOpacity(0.5),`

### Column without scrolling parent
- **File**: `/lib/widgets/card_back_fallback.dart`
- **Line**: 28
- **Suggestion**: Wrap with SingleChildScrollView to prevent overflow errors
- **Code**: `child: Column(`

### Using Opacity widget
- **File**: `/lib/widgets/sign_in_view.dart`
- **Line**: 244
- **Suggestion**: Consider using AnimatedOpacity, or apply opacity to colors instead of widgets
- **Code**: `? colorScheme.surface.withOpacity(0.8)`

### Using Opacity widget
- **File**: `/lib/widgets/rarity_distribution_chart.dart`
- **Line**: 192
- **Suggestion**: Consider using AnimatedOpacity, or apply opacity to colors instead of widgets
- **Code**: `color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.15),`

### Column without scrolling parent
- **File**: `/lib/widgets/rarity_distribution_chart.dart`
- **Line**: 54
- **Suggestion**: Wrap with SingleChildScrollView to prevent overflow errors
- **Code**: `child: Column(`

### Using Opacity widget
- **File**: `/lib/widgets/mtg_set_icon.dart`
- **Line**: 48
- **Suggestion**: Consider using AnimatedOpacity, or apply opacity to colors instead of widgets
- **Code**: `color: Theme.of(context).colorScheme.primary.withOpacity(0.1),`

### Using Opacity widget
- **File**: `/lib/widgets/market_scan_button.dart`
- **Line**: 68
- **Suggestion**: Consider using AnimatedOpacity, or apply opacity to colors instead of widgets
- **Code**: `color: Colors.green.withOpacity(0.3),`

### Using Opacity widget
- **File**: `/lib/widgets/create_binder_dialog.dart`
- **Line**: 134
- **Suggestion**: Consider using AnimatedOpacity, or apply opacity to colors instead of widgets
- **Code**: `color: color.withOpacity(0.4),`

### Using Opacity widget
- **File**: `/lib/widgets/animated_background.dart`
- **Line**: 17
- **Suggestion**: Consider using AnimatedOpacity, or apply opacity to colors instead of widgets
- **Code**: `child: Opacity(`

### Using Opacity widget
- **File**: `/lib/widgets/animated_gradient_button.dart`
- **Line**: 103
- **Suggestion**: Consider using AnimatedOpacity, or apply opacity to colors instead of widgets
- **Code**: `color: widget.gradientColors.first.withOpacity(_isPressed ? 0.2 : 0.3),`

### Using Opacity widget
- **File**: `/lib/widgets/premium_dialog.dart`
- **Line**: 54
- **Suggestion**: Consider using AnimatedOpacity, or apply opacity to colors instead of widgets
- **Code**: `color: Theme.of(context).colorScheme.primary.withOpacity(0.5),`

## 🟡 Low Impact Issues
### Repeated Theme.of calls
- **File**: `/lib/constants/text_styles.dart`
- **Line**: 85
- **Suggestion**: Store Theme.of(context) in a local variable to avoid rebuilds
- **Code**: `color: Theme.of(context).colorScheme.onSurface,`

### Hardcoded colors
- **File**: `/lib/constants/app_colors.dart`
- **Line**: 115
- **Suggestion**: Use theme colors for consistency and dark mode support
- **Code**: `color: Colors.black.withOpacity(0.5),`

### Repeated Theme.of calls
- **File**: `/lib/constants/card_styles.dart`
- **Line**: 6
- **Suggestion**: Store Theme.of(context) in a local variable to avoid rebuilds
- **Code**: `color: Theme.of(context).colorScheme.surface,`

### Repeated MediaQuery.of calls
- **File**: `/lib/utils/notification_manager.dart`
- **Line**: 19
- **Suggestion**: Store MediaQuery.of(context) in a local variable to avoid rebuilds
- **Code**: `top: MediaQuery.of(context).padding.top + 12,`

### Repeated Theme.of calls
- **File**: `/lib/utils/notification_manager.dart`
- **Line**: 40
- **Suggestion**: Store Theme.of(context) in a local variable to avoid rebuilds
- **Code**: `color: Theme.of(context).colorScheme.surface,  // Changed from inverseSurface`

### Hardcoded colors
- **File**: `/lib/utils/image_handler.dart`
- **Line**: 38
- **Suggestion**: Use theme colors for consistency and dark mode support
- **Code**: `color: Colors.grey[800],`

### Repeated Theme.of calls
- **File**: `/lib/utils/cached_network_image.dart`
- **Line**: 113
- **Suggestion**: Store Theme.of(context) in a local variable to avoid rebuilds
- **Code**: `color: Theme.of(context).colorScheme.surfaceVariant,`

### Repeated Theme.of calls
- **File**: `/lib/utils/error_handler.dart`
- **Line**: 26
- **Suggestion**: Store Theme.of(context) in a local variable to avoid rebuilds
- **Code**: `backgroundColor: Theme.of(context).colorScheme.error,`

### Hardcoded colors
- **File**: `/lib/utils/image_utils.dart`
- **Line**: 12
- **Suggestion**: Use theme colors for consistency and dark mode support
- **Code**: `color: Colors.grey.shade200,`

### Repeated Theme.of calls
- **File**: `/lib/screens/collection_index_screen.dart`
- **Line**: 72
- **Suggestion**: Store Theme.of(context) in a local variable to avoid rebuilds
- **Code**: `color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),`

### Repeated MediaQuery.of calls
- **File**: `/lib/screens/analytics_screen.dart`
- **Line**: 1166
- **Suggestion**: Store MediaQuery.of(context) in a local variable to avoid rebuilds
- **Code**: `width: MediaQuery.of(context).size.width * progress,`

### Repeated Theme.of calls
- **File**: `/lib/screens/analytics_screen.dart`
- **Line**: 181
- **Suggestion**: Store Theme.of(context) in a local variable to avoid rebuilds
- **Code**: `style: Theme.of(context).textTheme.titleMedium,`

### Repeated MediaQuery.of calls
- **File**: `/lib/screens/scanner_screen.dart`
- **Line**: 186
- **Suggestion**: Store MediaQuery.of(context) in a local variable to avoid rebuilds
- **Code**: `final size = MediaQuery.of(context).size;`

### Repeated Theme.of calls
- **File**: `/lib/screens/scanner_screen.dart`
- **Line**: 341
- **Suggestion**: Store Theme.of(context) in a local variable to avoid rebuilds
- **Code**: `Theme.of(context).colorScheme.primary,`

### Repeated Theme.of calls
- **File**: `/lib/screens/home_overview.dart`
- **Line**: 128
- **Suggestion**: Store Theme.of(context) in a local variable to avoid rebuilds
- **Code**: `color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),`

### Repeated Theme.of calls
- **File**: `/lib/screens/settings_screen.dart`
- **Line**: 32
- **Suggestion**: Store Theme.of(context) in a local variable to avoid rebuilds
- **Code**: `color: Theme.of(context).colorScheme.primary,`

### Repeated Theme.of calls
- **File**: `/lib/screens/base_card_details_screen.dart`
- **Line**: 90
- **Suggestion**: Store Theme.of(context) in a local variable to avoid rebuilds
- **Code**: `backgroundColor: Theme.of(context).colorScheme.secondary,`

### Repeated MediaQuery.of calls
- **File**: `/lib/screens/profile_screen.dart`
- **Line**: 1473
- **Suggestion**: Store MediaQuery.of(context) in a local variable to avoid rebuilds
- **Code**: `width: MediaQuery.of(context).size.width * sliderValue,`

### Repeated Theme.of calls
- **File**: `/lib/screens/profile_screen.dart`
- **Line**: 158
- **Suggestion**: Store Theme.of(context) in a local variable to avoid rebuilds
- **Code**: `? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)`

### Repeated Theme.of calls
- **File**: `/lib/screens/root_navigator.dart`
- **Line**: 80
- **Suggestion**: Store Theme.of(context) in a local variable to avoid rebuilds
- **Code**: `selectedItemColor: Theme.of(context).colorScheme.primary,`

### Repeated Theme.of calls
- **File**: `/lib/screens/privacy_settings_screen.dart`
- **Line**: 120
- **Suggestion**: Store Theme.of(context) in a local variable to avoid rebuilds
- **Code**: `style: Theme.of(context).textTheme.titleMedium?.copyWith(`

### Repeated Theme.of calls
- **File**: `/lib/screens/debug_collection_screen.dart`
- **Line**: 200
- **Suggestion**: Store Theme.of(context) in a local variable to avoid rebuilds
- **Code**: `style: Theme.of(context).textTheme.titleLarge,`

### Repeated Theme.of calls
- **File**: `/lib/screens/add_to_collection_screen.dart`
- **Line**: 67
- **Suggestion**: Store Theme.of(context) in a local variable to avoid rebuilds
- **Code**: `style: Theme.of(context).textTheme.headlineSmall,`

### Repeated MediaQuery.of calls
- **File**: `/lib/screens/collections_screen.dart`
- **Line**: 112
- **Suggestion**: Store MediaQuery.of(context) in a local variable to avoid rebuilds
- **Code**: `_random.nextDouble() * MediaQuery.of(context).size.width,`

### Repeated Theme.of calls
- **File**: `/lib/screens/collections_screen.dart`
- **Line**: 118
- **Suggestion**: Store Theme.of(context) in a local variable to avoid rebuilds
- **Code**: `color: Theme.of(context).colorScheme.primary.withOpacity(0.15),`

### Repeated MediaQuery.of calls
- **File**: `/lib/screens/custom_collection_detail_screen.dart`
- **Line**: 112
- **Suggestion**: Store MediaQuery.of(context) in a local variable to avoid rebuilds
- **Code**: `maxHeight: MediaQuery.of(context).size.height * 0.25,`

### Repeated Theme.of calls
- **File**: `/lib/screens/custom_collection_detail_screen.dart`
- **Line**: 214
- **Suggestion**: Store Theme.of(context) in a local variable to avoid rebuilds
- **Code**: `color: Theme.of(context).colorScheme.onSurfaceVariant,`

### Repeated MediaQuery.of calls
- **File**: `/lib/screens/mtg_card_details_screen.dart`
- **Line**: 1225
- **Suggestion**: Store MediaQuery.of(context) in a local variable to avoid rebuilds
- **Code**: `height: MediaQuery.of(context).size.width * 1.4, // MTG cards are taller`

### Repeated Theme.of calls
- **File**: `/lib/screens/mtg_card_details_screen.dart`
- **Line**: 169
- **Suggestion**: Store Theme.of(context) in a local variable to avoid rebuilds
- **Code**: `final isDark = Theme.of(context).brightness == Brightness.dark;`

### Repeated Theme.of calls
- **File**: `/lib/screens/search_screen.dart`
- **Line**: 902
- **Suggestion**: Store Theme.of(context) in a local variable to avoid rebuilds
- **Code**: `color: Theme.of(context).colorScheme.secondary,`

### Repeated MediaQuery.of calls
- **File**: `/lib/screens/pokemon_card_details_screen.dart`
- **Line**: 1235
- **Suggestion**: Store MediaQuery.of(context) in a local variable to avoid rebuilds
- **Code**: `height: MediaQuery.of(context).size.height * 0.8,`

### Repeated Theme.of calls
- **File**: `/lib/screens/pokemon_card_details_screen.dart`
- **Line**: 128
- **Suggestion**: Store Theme.of(context) in a local variable to avoid rebuilds
- **Code**: `final isDark = Theme.of(context).brightness == Brightness.dark;`

### Repeated MediaQuery.of calls
- **File**: `/lib/screens/splash_screen.dart`
- **Line**: 58
- **Suggestion**: Store MediaQuery.of(context) in a local variable to avoid rebuilds
- **Code**: `final size = MediaQuery.of(context).size;`

### Repeated Theme.of calls
- **File**: `/lib/screens/splash_screen.dart`
- **Line**: 61
- **Suggestion**: Store Theme.of(context) in a local variable to avoid rebuilds
- **Code**: `backgroundColor: Theme.of(context).colorScheme.background,`

### Hardcoded colors
- **File**: `/lib/main.dart`
- **Line**: 164
- **Suggestion**: Use theme colors for consistency and dark mode support
- **Code**: `style: const TextStyle(color: Colors.red),`

### Repeated Theme.of calls
- **File**: `/lib/services/dialog_service.dart`
- **Line**: 33
- **Suggestion**: Store Theme.of(context) in a local variable to avoid rebuilds
- **Code**: `data: Theme.of(context).copyWith(`

### Repeated Theme.of calls
- **File**: `/lib/widgets/acquisition_timeline_chart.dart`
- **Line**: 25
- **Suggestion**: Store Theme.of(context) in a local variable to avoid rebuilds
- **Code**: `final colorScheme = Theme.of(context).colorScheme;`

### Repeated Theme.of calls
- **File**: `/lib/widgets/price_update_dialog.dart`
- **Line**: 54
- **Suggestion**: Store Theme.of(context) in a local variable to avoid rebuilds
- **Code**: `style: Theme.of(context).textTheme.titleLarge?.copyWith(`

### Hardcoded colors
- **File**: `/lib/widgets/price_update_button.dart`
- **Line**: 93
- **Suggestion**: Use theme colors for consistency and dark mode support
- **Code**: `color: Colors.green.withOpacity(0.2),`

### Repeated Theme.of calls
- **File**: `/lib/widgets/theme_switcher.dart`
- **Line**: 25
- **Suggestion**: Store Theme.of(context) in a local variable to avoid rebuilds
- **Code**: `color: Theme.of(context).colorScheme.primary,`

### Repeated Theme.of calls
- **File**: `/lib/widgets/pokemon_set_icon.dart`
- **Line**: 33
- **Suggestion**: Store Theme.of(context) in a local variable to avoid rebuilds
- **Code**: `final isDarkMode = Theme.of(context).brightness == Brightness.dark;`

### Repeated Theme.of calls
- **File**: `/lib/widgets/styled_toast.dart`
- **Line**: 33
- **Suggestion**: Store Theme.of(context) in a local variable to avoid rebuilds
- **Code**: `final bgColor = backgroundColor ?? Theme.of(context).colorScheme.primary;`

### Repeated MediaQuery.of calls
- **File**: `/lib/widgets/app_drawer.dart`
- **Line**: 67
- **Suggestion**: Store MediaQuery.of(context) in a local variable to avoid rebuilds
- **Code**: `width: MediaQuery.of(context).size.width * 0.6, // Changed from 0.75 to 0.6`

### Repeated Theme.of calls
- **File**: `/lib/widgets/app_drawer.dart`
- **Line**: 57
- **Suggestion**: Store Theme.of(context) in a local variable to avoid rebuilds
- **Code**: `final colorScheme = Theme.of(context).colorScheme;`

### Repeated MediaQuery.of calls
- **File**: `/lib/widgets/portfolio_value_chart.dart`
- **Line**: 377
- **Suggestion**: Store MediaQuery.of(context) in a local variable to avoid rebuilds
- **Code**: `final totalWidth = MediaQuery.of(context).size.width;`

### Repeated Theme.of calls
- **File**: `/lib/widgets/portfolio_value_chart.dart`
- **Line**: 161
- **Suggestion**: Store Theme.of(context) in a local variable to avoid rebuilds
- **Code**: `tooltipBgColor: Theme.of(context).colorScheme.surface,`

### Repeated Theme.of calls
- **File**: `/lib/widgets/avatar_picker_dialog.dart`
- **Line**: 16
- **Suggestion**: Store Theme.of(context) in a local variable to avoid rebuilds
- **Code**: `style: Theme.of(context).textTheme.titleLarge,`

### Repeated Theme.of calls
- **File**: `/lib/widgets/custom_collections_grid.dart`
- **Line**: 85
- **Suggestion**: Store Theme.of(context) in a local variable to avoid rebuilds
- **Code**: `color: Theme.of(context).colorScheme.error,`

### Repeated Theme.of calls
- **File**: `/lib/widgets/search/recent_searches.dart`
- **Line**: 70
- **Suggestion**: Store Theme.of(context) in a local variable to avoid rebuilds
- **Code**: `color: Theme.of(context).colorScheme.surface,`

### Repeated Theme.of calls
- **File**: `/lib/widgets/search/loading_indicators.dart`
- **Line**: 50
- **Suggestion**: Store Theme.of(context) in a local variable to avoid rebuilds
- **Code**: `final isDark = Theme.of(context).brightness == Brightness.dark;`

### Repeated Theme.of calls
- **File**: `/lib/widgets/search/search_categories.dart`
- **Line**: 64
- **Suggestion**: Store Theme.of(context) in a local variable to avoid rebuilds
- **Code**: `final brightness = Theme.of(context).brightness;`

### Repeated Theme.of calls
- **File**: `/lib/widgets/search/set_grid.dart`
- **Line**: 62
- **Suggestion**: Store Theme.of(context) in a local variable to avoid rebuilds
- **Code**: `color: Theme.of(context).colorScheme.primary,`

### Repeated Theme.of calls
- **File**: `/lib/widgets/search/card_grid_item.dart`
- **Line**: 29
- **Suggestion**: Store Theme.of(context) in a local variable to avoid rebuilds
- **Code**: `final isDark = Theme.of(context).brightness == Brightness.dark;`

### Repeated Theme.of calls
- **File**: `/lib/widgets/search/search_categories_header.dart`
- **Line**: 36
- **Suggestion**: Store Theme.of(context) in a local variable to avoid rebuilds
- **Code**: `? Theme.of(context).colorScheme.primary`

### Repeated Theme.of calls
- **File**: `/lib/widgets/search/loading_state.dart`
- **Line**: 25
- **Suggestion**: Store Theme.of(context) in a local variable to avoid rebuilds
- **Code**: `style: Theme.of(context).textTheme.bodyMedium?.copyWith(`

### Repeated Theme.of calls
- **File**: `/lib/widgets/search/card_skeleton_grid.dart`
- **Line**: 71
- **Suggestion**: Store Theme.of(context) in a local variable to avoid rebuilds
- **Code**: `final isDark = Theme.of(context).brightness == Brightness.dark;`

### Repeated Theme.of calls
- **File**: `/lib/widgets/search/search_app_bar.dart`
- **Line**: 54
- **Suggestion**: Store Theme.of(context) in a local variable to avoid rebuilds
- **Code**: `final isDark = Theme.of(context).brightness == Brightness.dark;`

### Repeated MediaQuery.of calls
- **File**: `/lib/widgets/create_collection_sheet.dart`
- **Line**: 135
- **Suggestion**: Store MediaQuery.of(context) in a local variable to avoid rebuilds
- **Code**: `MediaQuery.of(context).viewInsets.bottom + 16,`

### Repeated Theme.of calls
- **File**: `/lib/widgets/create_collection_sheet.dart`
- **Line**: 62
- **Suggestion**: Store Theme.of(context) in a local variable to avoid rebuilds
- **Code**: `final colorScheme = Theme.of(context).colorScheme;`

### Repeated Theme.of calls
- **File**: `/lib/widgets/card_grid_item.dart`
- **Line**: 36
- **Suggestion**: Store Theme.of(context) in a local variable to avoid rebuilds
- **Code**: `color: Theme.of(context).colorScheme.surface,`

### Repeated Theme.of calls
- **File**: `/lib/widgets/collection_grid.dart`
- **Line**: 176
- **Suggestion**: Store Theme.of(context) in a local variable to avoid rebuilds
- **Code**: `style: Theme.of(context).textTheme.titleLarge,`

### Repeated MediaQuery.of calls
- **File**: `/lib/widgets/empty_collection_view.dart`
- **Line**: 235
- **Suggestion**: Store MediaQuery.of(context) in a local variable to avoid rebuilds
- **Code**: `final isSmallScreen = MediaQuery.of(context).size.height < 700;`

### Repeated Theme.of calls
- **File**: `/lib/widgets/empty_collection_view.dart`
- **Line**: 234
- **Suggestion**: Store Theme.of(context) in a local variable to avoid rebuilds
- **Code**: `final colorScheme = Theme.of(context).colorScheme;`

### Hardcoded colors
- **File**: `/lib/widgets/card_back_fallback.dart`
- **Line**: 44
- **Suggestion**: Use theme colors for consistency and dark mode support
- **Code**: `color: Colors.black.withOpacity(0.5),`

### Repeated MediaQuery.of calls
- **File**: `/lib/widgets/sign_in_view.dart`
- **Line**: 172
- **Suggestion**: Store MediaQuery.of(context) in a local variable to avoid rebuilds
- **Code**: `final size = MediaQuery.of(context).size;`

### Repeated Theme.of calls
- **File**: `/lib/widgets/sign_in_view.dart`
- **Line**: 142
- **Suggestion**: Store Theme.of(context) in a local variable to avoid rebuilds
- **Code**: `backgroundColor: Theme.of(context).colorScheme.error,`

### Repeated Theme.of calls
- **File**: `/lib/widgets/rarity_distribution_chart.dart`
- **Line**: 16
- **Suggestion**: Store Theme.of(context) in a local variable to avoid rebuilds
- **Code**: `final colorScheme = Theme.of(context).colorScheme;`

### Repeated Theme.of calls
- **File**: `/lib/widgets/mtg_set_icon.dart`
- **Line**: 48
- **Suggestion**: Store Theme.of(context) in a local variable to avoid rebuilds
- **Code**: `color: Theme.of(context).colorScheme.primary.withOpacity(0.1),`

### Repeated Theme.of calls
- **File**: `/lib/widgets/market_scan_button.dart`
- **Line**: 97
- **Suggestion**: Store Theme.of(context) in a local variable to avoid rebuilds
- **Code**: `style: Theme.of(context).textTheme.titleMedium?.copyWith(`

### Repeated MediaQuery.of calls
- **File**: `/lib/widgets/create_binder_dialog.dart`
- **Line**: 60
- **Suggestion**: Store MediaQuery.of(context) in a local variable to avoid rebuilds
- **Code**: `final mediaQuery = MediaQuery.of(context);`

### Repeated Theme.of calls
- **File**: `/lib/widgets/create_binder_dialog.dart`
- **Line**: 61
- **Suggestion**: Store Theme.of(context) in a local variable to avoid rebuilds
- **Code**: `final isDark = Theme.of(context).brightness == Brightness.dark;`

### Hardcoded colors
- **File**: `/lib/widgets/animated_gradient_button.dart`
- **Line**: 122
- **Suggestion**: Use theme colors for consistency and dark mode support
- **Code**: `color: Colors.transparent,`

### Repeated Theme.of calls
- **File**: `/lib/widgets/premium_dialog.dart`
- **Line**: 25
- **Suggestion**: Store Theme.of(context) in a local variable to avoid rebuilds
- **Code**: `color: Theme.of(context).colorScheme.primary,`


## Summary of Best Practices
1. Use `ListView.builder` instead of `ListView` for potentially long lists
2. Add keys to list items for more efficient rebuilding
3. Cache `MediaQuery.of(context)` and `Theme.of(context)` in variables
4. Use `const` constructors wherever possible
5. Avoid expensive operations in `build` methods
6. Consider more granular state management solutions
7. Use `AnimatedOpacity` instead of `Opacity` when animating
8. Wrap long `Column`s with `SingleChildScrollView` to prevent overflow
