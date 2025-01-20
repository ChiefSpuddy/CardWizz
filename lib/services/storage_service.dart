import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static late SharedPreferences _prefs;
  
  static Future<StorageService> init() async {
    _prefs = await SharedPreferences.getInstance();
    return StorageService();
  }

  Future<void> savePreference(String key, dynamic value) async {
    if (value is bool) {
      await _prefs.setBool(key, value);
    } else if (value is String) {
      await _prefs.setString(key, value);
    } else if (value is int) {
      await _prefs.setInt(key, value);
    } else if (value is double) {
      await _prefs.setDouble(key, value);
    }
  }

  T? getPreference<T>(String key) {
    return _prefs.get(key) as T?;
  }
}
