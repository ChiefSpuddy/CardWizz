import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/business_card_model.dart';
import '../services/storage_service.dart';

class AppState extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;
  bool _isDarkMode = false;
  final StorageService _storage;
  List<BusinessCard> _cards = [];

  AppState(this._storage) {
    _loadCards();
  }

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isDarkMode => _isDarkMode;
  List<BusinessCard> get cards => _cards;

  // Methods
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void setUser(UserModel? user) {
    _currentUser = user;
    notifyListeners();
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void updateUser({
    String? name,
    String? email,
    String? profileImage,
  }) {
    if (_currentUser != null) {
      _currentUser = UserModel(
        id: _currentUser!.id,
        name: name ?? _currentUser!.name,
        email: email ?? _currentUser!.email,
        profileImage: profileImage ?? _currentUser!.profileImage,
        createdAt: _currentUser!.createdAt,
      );
      notifyListeners();
    }
  }

  Future<void> clearState() async {
    _currentUser = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  // Error handling helper
  Future<T?> handleError<T>(Future<T> Function() operation) async {
    try {
      setError(null);
      setLoading(true);
      final result = await operation();
      return result;
    } catch (e) {
      setError(e.toString());
      return null;
    } finally {
      setLoading(false);
    }
  }

  Future<void> _loadCards() async {
    _cards = await _storage.getCards();
    notifyListeners();
  }

  Future<void> addCard(BusinessCard card) async {
    await _storage.saveCard(card);
    await _loadCards();
  }
}
