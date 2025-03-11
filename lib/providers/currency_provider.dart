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

  // Improve currency formatting consistency
  String formatValue(double eurValue) {
    if (eurValue == 0) return '$symbol 0';  // Fix: Added space between symbol and 0
    
    final convertedValue = eurValue * rate;
    
    // Use consistent formatting for values of different sizes
    if (convertedValue >= 10000) {
      return '$symbol${convertedValue.round()}'; // No decimal places for very large values
    } else if (convertedValue >= 1000) {
      return '$symbol${convertedValue.round()}'; // No decimal places for large values
    } else if (convertedValue >= 100) {
      return '$symbol${convertedValue.toStringAsFixed(0)}'; // No decimal places
    } else if (convertedValue >= 10) {
      return '$symbol${convertedValue.toStringAsFixed(1)}'; // One decimal place
    } else {
      return '$symbol${convertedValue.toStringAsFixed(2)}'; // Two decimal places for small values
    }
  }

  // Convert EUR to current currency
  double convertFromEur(double eurValue) {
    return eurValue * rate;
  }
  
  // For chart axes (with K/M formatting)
  String formatChartValue(double eurValue) {
    final convertedValue = eurValue * rate;
    if (convertedValue >= 1000000) {
      return '$symbol${(convertedValue / 1000000).toStringAsFixed(1)}M';
    } else if (convertedValue >= 1000) {
      return '$symbol${(convertedValue / 1000).toStringAsFixed(1)}k';
    }
    return '$symbol${convertedValue.toInt()}';
  }

  // Add a short format option that's more concise for space-constrained UIs
  String formatShortValue(double eurValue) {
    final convertedValue = eurValue * rate;
    
    if (convertedValue >= 1000000) {
      return '$symbol${(convertedValue / 1000000).toStringAsFixed(1)}M';
    } else if (convertedValue >= 1000) {
      return '$symbol${(convertedValue / 1000).toStringAsFixed(1)}k';
    } else if (convertedValue >= 100) {
      // No decimal places needed for larger values
      return '$symbol${convertedValue.toInt()}';
    } else if (convertedValue >= 10) {
      // One decimal place for medium values
      return '$symbol${convertedValue.toStringAsFixed(1)}';
    }
    
    // Two decimal places for small values
    return '$symbol${convertedValue.toStringAsFixed(2)}';
  }
}
