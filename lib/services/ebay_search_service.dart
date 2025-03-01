import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/ebay_api_service.dart';
import '../models/tcg_card.dart';

class EbaySearchService extends ChangeNotifier {
  final EbayApiService _ebayApi = EbayApiService();
  
  // Search state variables
  bool _isSearching = false;
  String _lastSearchQuery = '';
  List<Map<String, dynamic>> _searchResults = [];
  String? _errorMessage;
  
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
}
