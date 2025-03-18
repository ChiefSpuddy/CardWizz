import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Currency {
  final String code;
  final String symbol;
  final String name;
  final double conversionRate;

  Currency({
    required this.code,
    required this.symbol,
    required this.name,
    required this.conversionRate,
  });
}

class CurrencyProvider with ChangeNotifier {
  static const String _currencyPreferenceKey = 'selected_currency';
  
  // Default currency is USD
  final Map<String, Currency> _availableCurrencies = {
    'USD': Currency(code: 'USD', symbol: '\$', name: 'US Dollar', conversionRate: 1.0),
    'EUR': Currency(code: 'EUR', symbol: '€', name: 'Euro', conversionRate: 0.92),
    'GBP': Currency(code: 'GBP', symbol: '£', name: 'British Pound', conversionRate: 0.78),
    'CAD': Currency(code: 'CAD', symbol: 'C\$', name: 'Canadian Dollar', conversionRate: 1.35),
    'AUD': Currency(code: 'AUD', symbol: 'A\$', name: 'Australian Dollar', conversionRate: 1.48),
    'JPY': Currency(code: 'JPY', symbol: '¥', name: 'Japanese Yen', conversionRate: 145.0),
  };
  
  String _selectedCurrencyCode = 'USD';
  bool _isInitialized = false;

  CurrencyProvider() {
    _loadSelectedCurrency();
  }

  // Current currency getters
  Currency? get selectedCurrency => _availableCurrencies[_selectedCurrencyCode];
  String get currencyCode => _selectedCurrencyCode;
  String get currentCurrency => _selectedCurrencyCode;
  String get currencySymbol => selectedCurrency?.symbol ?? '\$';
  double get conversionRate => selectedCurrency?.conversionRate ?? 1.0;

  // Add missing getters and methods
  String get symbol => selectedCurrency?.symbol ?? '\$';
  Map<String, Currency> get currencies => _availableCurrencies;

  // Status getter
  bool get isInitialized => _isInitialized;

  // Format methods
  String formatValue(double? price) {
    if (price == null || price == 0) return '$currencySymbol${0.00}';
    
    // Convert the value to the selected currency
    final convertedValue = price * conversionRate;
    
    // Format based on currency
    if (_selectedCurrencyCode == 'JPY') {
      // JPY doesn't typically use decimal places
      return '$currencySymbol${convertedValue.round()}';
    } else {
      // Most currencies use 2 decimal places
      return '$currencySymbol${convertedValue.toStringAsFixed(2)}';
    }
  }

  String formatChartValue(double value) {
    final formattedValue = value.toStringAsFixed(2);
    return '$symbol$formattedValue';
  }

  double convertFromEur(double eurPrice) {
    // Convert EUR price to selected currency
    final eurToUsd = 1.09; // Hard-coded EUR to USD rate
    final usdPrice = eurPrice * eurToUsd;
    return usdPrice * conversionRate;
  }

  // Convert price from USD to selected currency
  double convertPrice(double priceInUsd) {
    return priceInUsd * conversionRate;
  }

  // Load saved currency preference
  Future<void> _loadSelectedCurrency() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCurrency = prefs.getString(_currencyPreferenceKey);
      
      if (savedCurrency != null && _availableCurrencies.containsKey(savedCurrency)) {
        _selectedCurrencyCode = savedCurrency;
      }
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      // Default to USD if there's an error
      _selectedCurrencyCode = 'USD';
      _isInitialized = true;
      notifyListeners();
    }
  }

  // Change currency
  Future<void> setCurrency(String currencyCode) async {
    if (_availableCurrencies.containsKey(currencyCode)) {
      _selectedCurrencyCode = currencyCode;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currencyPreferenceKey, currencyCode);
      
      notifyListeners();
    }
  }

  // Update conversion rates (e.g., from an API)
  void updateConversionRates(Map<String, double> rates) {
    // Convert the incoming rates to Currency objects
    rates.forEach((code, rate) {
      if (_availableCurrencies.containsKey(code)) {
        final currency = _availableCurrencies[code]!;
        _availableCurrencies[code] = Currency(
          code: currency.code,
          symbol: currency.symbol,
          name: currency.name,
          conversionRate: rate,
        );
      }
    });
    notifyListeners();
  }
}
