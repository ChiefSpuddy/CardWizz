import 'dart:io';
import 'package:path/path.dart' as path;

void main() async {
  final projectPath = Directory.current.path;
  print('CardWizz Project Cleanup');
  print('=======================\n');

  // Load the list of potentially unused files from the previous analysis
  // You may want to edit this list before running the cleanup
  final potentiallyUnusedFiles = [
    // Focus on lib directory files - safer to clean up our own code first
    '/lib/background/background_service.dart',
    '/lib/constants/assets.dart',
    '/lib/constants/app_constants.dart',
    '/lib/constants/app_metadata.dart',
    '/lib/constants/store_config.dart',
    '/lib/constants/strings.dart',
    '/lib/constants/launch_config.dart',
    '/lib/providers/index.dart',
    '/lib/providers/language_provider.dart',
    '/lib/navigation/app_router.dart',
    '/lib/utils/haptics.dart',
    '/lib/utils/debug_controls.dart',
    '/lib/utils/animation_utils.dart',
    '/lib/utils/ui_helper.dart',
    '/lib/utils/grid_layout_calculator.dart',
    '/lib/utils/card_assets.dart',
    '/lib/utils/hero_disabler.dart',
    '/lib/utils/string_utils.dart',
    '/lib/utils/live_cards_notifier.dart',
    '/lib/utils/toast_helper.dart',
    '/lib/utils/set_validator_test.dart',
    '/lib/models/auth_user.dart',
    '/lib/models/binder.dart',
    '/lib/models/user_preferences.dart',
    '/lib/models/market_cache.dart',
    '/lib/screens/cards_screen.dart',
    '/lib/screens/set_browser_screen.dart',
    '/lib/screens/scan_screen.dart',
    '/lib/screens/scan_card_screen.dart',
    '/lib/screens/export_screen.dart',
    '/lib/screens/browse_screen.dart',
    '/lib/screens/custom_collections_screen.dart',
    '/lib/screens/add_card_screen.dart',
    '/lib/components/search/set_results_grid.dart',
    '/lib/app.dart',
    '/lib/services/analytics_service.dart',
    '/lib/services/deep_link_service.dart',
    '/lib/services/search_history_service_helper.dart',
    '/lib/services/cloud_sync_service.dart',
    '/lib/services/sync_service.dart',
    '/lib/services/cloud_service.dart',
    // Widgets
    '/lib/widgets/set_distribution_card.dart',
    '/lib/widgets/purchase_price_dialog.dart',
    '/lib/widgets/price_trend_indicator.dart',
    '/lib/widgets/card_collected_animation.dart',
    '/lib/widgets/price_refresh_button.dart',
    '/lib/widgets/sort_button.dart',
    '/lib/widgets/dev_menu.dart',
    '/lib/widgets/safe_hero.dart',
    '/lib/widgets/set_logo_widget.dart',
    '/lib/widgets/add_card_button.dart',
    '/lib/widgets/main_binder_toggle.dart',
    '/lib/widgets/card_image.dart',
    '/lib/widgets/core_imports.dart',
    '/lib/widgets/rarity_indicator.dart',
    '/lib/widgets/card_preview.dart',
    '/lib/widgets/loading_handler.dart',
    '/lib/widgets/search/sort_menu.dart',
    '/lib/widgets/search/empty_preview_fix.dart',
    '/lib/widgets/search/card_preview.dart',
    '/lib/widgets/search/card_results_grid.dart',
    '/lib/widgets/search/card_hero_wrapper.dart',
    '/lib/widgets/search/empty_card_preview.dart',
    '/lib/widgets/error_view.dart',
    '/lib/widgets/chart_debug_widget.dart',
    '/lib/widgets/home_preview_card.dart',
    '/lib/widgets/particle_overlay.dart',
    '/lib/widgets/username_edit_dialog.dart',
    '/lib/widgets/search_filters.dart',
    '/lib/widgets/bottom_nav_bar.dart',
    '/lib/widgets/fixed_height_grid_item.dart',
    '/lib/widgets/shimmer_card.dart',
  ];

  // Create backup directory
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final backupDir = Directory('${projectPath}/backup_${timestamp}');
  if (!await backupDir.exists()) {
    await backupDir.create();
  }

  print('Creating backups of files in: ${backupDir.path}\n');

  // Process each file
  int totalMoved = 0;
  for (final relativePath in potentiallyUnusedFiles) {
    final fullPath = path.join(projectPath, relativePath.substring(1)); // Remove leading '/'
    final file = File(fullPath);
    
    if (await file.exists()) {
      try {
        // Create directory structure in backup
        final dirPath = path.dirname(relativePath);
        final backupFilePath = path.join(backupDir.path, relativePath.substring(1));
        final backupFileDir = Directory(path.dirname(backupFilePath));
        
        if (!await backupFileDir.exists()) {
          await backupFileDir.create(recursive: true);
        }
        
        // Copy file to backup
        await file.copy(backupFilePath);
        print('✓ Backed up: $relativePath');
        
        // Move to temporary location instead of deleting
        final tempFile = File('${fullPath}.unused');
        await file.rename(tempFile.path);
        totalMoved++;
      } catch (e) {
        print('✗ Error processing $relativePath: $e');
      }
    } else {
      print('! File not found: $relativePath');
    }
  }

  print('\nBackup complete. $totalMoved files moved to .unused extension.');
  print('\nIMPORTANT: Please test your app thoroughly before deleting files permanently.');
  print('\nTo restore all files:');
  print('dart tools/restore_files.dart');
  
  print('\nTo permanently delete all unused files (after testing):');
  print('dart tools/delete_unused_files.dart');
}
