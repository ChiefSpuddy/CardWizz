import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyProvider extends ChangeNotifier {
  static const String _currencyKey = 'selected_currency';
  String _currentCurrency = 'EUR';
  
  final Map<String, (String, double)> _currencies = {
    'EUR': ('€', 1.0),
    'USD': ('\$', 1.09),
    'GBP': ('£', 0.86),
    'CAD': ('C\$', 1.47),
    'AUD': ('A\$', 1.65),
    'JPY': ('¥', 157.78),
  };

  CurrencyProvider() {
    _loadSavedCurrency();
  }

  Future<void> _loadSavedCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCurrency = prefs.getString(_currencyKey);
    if (savedCurrency != null && _currencies.containsKey(savedCurrency)) {
      _currentCurrency = savedCurrency;
      notifyListeners();
    }
  }

  Future<void> setCurrency(String currency) async {
    if (_currencies.containsKey(currency)) {
      _currentCurrency = currency;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currencyKey, currency);
      notifyListeners();
    }
  }

  String get currentCurrency => _currentCurrency;
  String get symbol => _currencies[_currentCurrency]!.$1;
  double get rate => _currencies[_currentCurrency]!.$2;
  Map<String, (String, double)> get currencies => _currencies;

  // For general use (exact values)
  String formatValue(double value) {
    return '$symbol${value.toStringAsFixed(2)}';
  }

  // For chart axes (with K/M formatting)
  String formatChartValue(double value) {
    if (value >= 1000) {
      return '$symbol${(value / 1000).round()}k';  // Changed to round() instead of toStringAsFixed(1)
    }
    return '$symbol${value.round()}';  // Changed to round() instead of toStringAsFixed(2)
  }
}
