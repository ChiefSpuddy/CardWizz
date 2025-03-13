import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/ebay_api_service.dart';
import '../services/logging_service.dart';
import 'package:flutter/foundation.dart';  // Add this for ChangeNotifier
import '../models/tcg_card.dart';  // Add this import for TcgCard

class EbaySearchService extends ChangeNotifier {
  final EbayApiService _ebayApi = EbayApiService();
  
  // Search state variables
  bool _isSearching = false;
  String _lastSearchQuery = '';
  List<Map<String, dynamic>> _searchResults = [];
  String? _errorMessage;
  
  // Price caching for performance
  final Map<String, _PriceData> _priceCache = {};
  
  // Getters
  bool get isSearching => _isSearching;
  String get lastSearchQuery => _lastSearchQuery;
  List<Map<String, dynamic>> get searchResults => _searchResults;
  String? get errorMessage => _errorMessage;
  
  // Search for completed listings
  Future<void> searchCompletedListings(String cardName, {
    String? setName,
    String? number,
    bool isMtg = false,
  }) async {
    try {
      _isSearching = true;
      _errorMessage = null;
      _lastSearchQuery = cardName;
      notifyListeners();
      
      _searchResults = await _ebayApi.getRecentSales(
        cardName, 
        setName: setName, 
        number: number,
        isMtg: isMtg,
      );
      
      _isSearching = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to search eBay: $e';
      _isSearching = false;
      notifyListeners();
    }
  }
  
  // Reset search
  void resetSearch() {
    _isSearching = false;
    _searchResults = [];
    _errorMessage = null;
    notifyListeners();
  }
  
  // Generate eBay URL for the card
  String getEbayUrl(TcgCard card, {bool isMtg = false}) {
    if (isMtg) {
      return _ebayApi.getEbayMtgSearchUrl(
        card.name, 
        setName: card.setName, 
        number: card.number
      );
    } else {
      final queryParts = [card.name, 'pokemon card'];
      if (card.setName != null) queryParts.add(card.setName!);
      if (card.number != null) queryParts.add(card.number!);
      
      return 'https://www.ebay.com/sch/i.html?_nkw=${Uri.encodeComponent(queryParts.join(' '))}&_sacat=183454';
    }
  }
  
  // Get accurate price based on eBay sold data with caching
  Future<double?> getCardPrice(TcgCard card) async {
    final cacheKey = '${card.id}_${card.name}';
    
    // Check if we have a cached price that hasn't expired
    if (_priceCache.containsKey(cacheKey)) {
      final cachedData = _priceCache[cacheKey]!;
      if (DateTime.now().difference(cachedData.timestamp) < const Duration(hours: 24)) {
        return cachedData.price;
      }
    }
    
    try {
      final isMtg = _isMtgCard(card);
      final price = await _ebayApi.getAveragePrice(
        card.name,
        setName: card.setName,
        number: card.number,
        isMtg: isMtg,
      );
      
      // Cache the price if we got a valid result
      if (price != null) {
        _priceCache[cacheKey] = _PriceData(
          price: price,
          timestamp: DateTime.now(),
        );
      }
      
      return price ?? card.price; // Fall back to card.price if no eBay data
    } catch (e) {
      LoggingService.error('Error fetching eBay price data: $e', tag: 'eBay');
      return card.price; // Fall back to card.price on error
    }
  }
  
  // Helper to determine if a card is an MTG card
  bool _isMtgCard(TcgCard card) {
    if (card.isMtg != null) {
      return card.isMtg!;
    }
    
    // Check ID pattern
    if (card.id.startsWith('mtg_')) {
      return true;
    }
    
    // Check for Pokemon set IDs
    const pokemonSetPrefixes = ['sv', 'swsh', 'sm', 'xy', 'bw', 'dp', 'cel'];
    for (final prefix in pokemonSetPrefixes) {
      if (card.set.id.toLowerCase().startsWith(prefix)) {
        return false; // Definitely Pokemon
      }
    }
    
    return false; // Default to non-MTG
  }
}

// Price data class for caching
class _PriceData {
  final double price;
  final DateTime timestamp;
  
  _PriceData({required this.price, required this.timestamp});
}
