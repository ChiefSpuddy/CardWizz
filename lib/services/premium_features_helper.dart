import 'package:flutter/material.dart';
import '../widgets/premium_dialog.dart';
import '../services/logging_service.dart';

/// Helper class to manage premium feature-related functionality.
class PremiumFeaturesHelper {
  /// Shows the premium subscription dialog.
  static Future<bool?> showPremiumDialog(BuildContext context) async {
    LoggingService.debug('Showing premium subscription dialog');
    return await showDialog<bool>(
      context: context,
      builder: (context) => const PremiumDialog(),
    );
  }
  
  /// Shows a premium upgrade dialog when a user tries to access a premium feature.
  static Future<bool?> showPremiumUpgradeDialog(
    BuildContext context, {
    String title = 'Premium Feature',
    String message = 'This feature requires CardWizz Premium subscription.\nUnlock all premium features for just £0.99/month.', // Updated from £1.99 to £0.99
  }) async {
    LoggingService.debug('Showing premium upgrade dialog');
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context, true);
              await showPremiumDialog(context);
            },
            child: const Text('Upgrade Now'),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }
}
