import 'package:shared_preferences/shared_preferences.dart';  // Fixed import
import '../services/purchase_service.dart';

class PremiumService extends ChangeNotifier {
  final PurchaseService _purchaseService;
  final SharedPreferences _prefs;
  static const String _premiumStatusKey = 'premium_status';

  PremiumService(this._purchaseService, this._prefs);

  bool get isPremium => _prefs.getBool(_premiumStatusKey) ?? false;

  // Premium feature flags
  bool get hasUnlimitedCollections => isPremium;
  bool get hasAdvancedAnalytics => isPremium;
  bool get hasPriceAlerts => isPremium;
  bool get hasBackupRestore => isPremium;
  bool get hasCustomThemes => isPremium;
  bool get hasCardScanning => isPremium;
  bool get hasBulkImport => isPremium;
  bool get hasMarketData => isPremium;

  // Feature limits for free users
  static const int maxFreeCards = 200;  // Changed from 100
  static const int maxFreeCollections = 4;  // Changed from 3
  static const int maxFreeAlerts = 2;

  Future<bool> upgradeToPremium() async {
    try {
      final success = await _purchaseService.purchasePremium();
      if (success) {
        await _prefs.setBool(_premiumStatusKey, true);
        notifyListeners();
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  bool canAddMoreCards(int currentCount) {
    if (isPremium) return true;
    return currentCount < maxFreeCards;
  }

  bool canCreateCollection(int currentCollections) {
    if (isPremium) return true;
    return currentCollections < maxFreeCollections;
  }

  bool canCreatePriceAlert(int currentAlerts) {
    if (isPremium) return true;
    return currentAlerts < maxFreeAlerts;
  }
}
