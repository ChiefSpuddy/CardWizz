import 'package:flutter/material.dart';
import '../services/purchase_service.dart';
import '../widgets/premium_dialog.dart';
import 'package:provider/provider.dart';

/// Helper class to easily check premium status and show upgrade dialogs
class PremiumFeaturesHelper {
  /// Checks if a premium feature is available
  /// Returns true if the feature is available (premium or within free limits)
  static bool canUseFeature({
    required BuildContext context,
    required bool isPremiumFeature,
    bool showDialog = true,
    int? currentCount,
    int? freeLimit,
  }) {
    final purchaseService = Provider.of<PurchaseService>(context, listen: false);
    
    // Always available if user has premium
    if (purchaseService.isPremium) {
      return true;
    }
    
    // If it's not a premium feature, it's always available
    if (!isPremiumFeature) {
      return true;
    }
    
    // If counting feature (like collection size), check the limits
    if (currentCount != null && freeLimit != null) {
      final canUse = currentCount < freeLimit;
      
      if (!canUse && showDialog) {
        _showUpgradeDialog(context);
      }
      
      return canUse;
    }
    
    // Premium feature that's not available in free tier
    if (showDialog) {
      _showUpgradeDialog(context);
    }
    
    return false;
  }
  
  /// Shows the premium upgrade dialog
  static Future<bool> _showUpgradeDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const PremiumDialog(),
    );
    
    return result ?? false;
  }
  
  /// Shows the premium dialog and returns whether they subscribed
  static Future<bool> showPremiumDialog(BuildContext context) async {
    return await _showUpgradeDialog(context);
  }
}
