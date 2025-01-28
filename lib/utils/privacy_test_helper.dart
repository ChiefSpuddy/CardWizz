import 'package:shared_preferences/shared_preferences.dart';

class PrivacyTestHelper {
  static Future<bool> verifyPrivacySettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if all privacy settings are properly stored
    final analyticsEnabled = prefs.getBool('analytics_enabled');
    final searchHistoryEnabled = prefs.getBool('search_history_enabled');
    final profileVisible = prefs.getBool('profile_visible');
    final showPrices = prefs.getBool('show_prices');

    print('Privacy Settings Test:');
    print('Analytics Enabled: $analyticsEnabled');
    print('Search History Enabled: $searchHistoryEnabled');
    print('Profile Visible: $profileVisible');
    print('Show Prices: $showPrices');

    // Verify settings are being saved
    return analyticsEnabled != null &&
           searchHistoryEnabled != null &&
           profileVisible != null &&
           showPrices != null;
  }

  static Future<void> resetPrivacySettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('analytics_enabled');
    await prefs.remove('search_history_enabled');
    await prefs.remove('profile_visible');
    await prefs.remove('show_prices');
  }
}
