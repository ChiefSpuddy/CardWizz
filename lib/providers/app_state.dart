import 'package:flutter/foundation.dart';
import '../services/storage_service.dart';

class AppState extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  bool _isDarkMode = false;
  final StorageService _storage;

  AppState(this._storage);

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isDarkMode => _isDarkMode;

  // Methods
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _storage.savePreference('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  Future<void> loadPreferences() async {
    _isDarkMode = _storage.getPreference('isDarkMode') ?? false;
    notifyListeners();
  }
}
