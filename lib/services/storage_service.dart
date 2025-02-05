import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';  // Add this for ValueNotifier
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../models/tcg_card.dart';
import 'package:collection/collection.dart';
import '../services/purchase_service.dart';
import '../services/tcg_api_service.dart';
import '../services/background_service.dart';
import 'package:rxdart/rxdart.dart'; // Add this import

class StorageService {
  static const int _freeUserCardLimit = 25;  // Changed from 10 to 25
  final PurchaseService _purchaseService;
  static StorageService? _instance;

  // Change from late final to nullable
  BackgroundService? backgroundService;

  // Add these fields
  late final SharedPreferences _prefs;
  final _cardsController = StreamController<List<TcgCard>>.broadcast();
  bool _isInitialized = false;
  String? _currentUserId;
  final Map<String, TcgCard> _cardCache = {};
  (String, TcgCard)? _lastRemovedCard;

  // Add these controllers
  final _priceUpdateController = StreamController<(int, int)>.broadcast();
  final _priceUpdateCompleteController = StreamController<int>.broadcast();

  Stream<(int, int)> get priceUpdateProgress => _priceUpdateController.stream;
  Stream<int> get priceUpdateComplete => _priceUpdateCompleteController.stream;

  // Add this helper method for user-specific keys
  String _getUserKey(String key) {
    return _currentUserId != null ? 'user_${_currentUserId}_$key' : key;
  }

  // Private constructor with purchase service
  StorageService._(this._purchaseService);

  static Future<StorageService> init(PurchaseService? purchaseService) async {
    if (_instance == null) {
      final purchase = purchaseService ?? PurchaseService();
      if (purchaseService == null) {
        await purchase.initialize();
      }
      _instance = StorageService._(purchase);
      
      // Initialize in sequence
      await _instance!._init();  // First initialize storage
      await _instance!.initializeBackgroundService();  // Then initialize background service
    }
    return _instance!;
  }

  // Change from private to public
  Future<void> initializeBackgroundService() async {
    if (backgroundService != null) return; // Already initialized
    
    try {
      final apiService = TcgApiService();
      backgroundService = BackgroundService(this, apiService);
      await backgroundService!.initialize();  // Initialize after creation
      print('Background service initialized successfully');
    } catch (e) {
      print('Error initializing background service: $e');
      backgroundService = null;  // Reset on error
    }
  }

  void setCurrentUser(String? userId) {
    print('Setting current user: $userId');
    _currentUserId = userId;
    
    // Initialize background service when user is set
    initializeBackgroundService().then((_) {
      if (userId != null) {
        backgroundService?.startPriceUpdates();
      } else {
        backgroundService?.stopPriceUpdates();
      }
    });
    
    // Remove await since _loadInitialData is void
    Future.delayed(const Duration(milliseconds: 100), () {
      _loadInitialData();
      final cards = _getCards();
      print('Loading cards with key: ${_getUserKey('cards')}');
      _cardsController.add(cards);
    });
  }

  // Add method to clear user data
  Future<void> clearUserData() async {
    if (_currentUserId == null) return;

    // Store the current user ID before clearing
    final currentId = _currentUserId;  // Save the ID before clearing
    
    // Don't clear the actual data, just remove the current user reference
    _currentUserId = null;
    _cardsController.add([]);
    
    print('Cleared current user, data remains in storage for: $currentId');
  }

  final _isReadyNotifier = ValueNotifier<bool>(false);
  ValueNotifier<bool> get isReady => _isReadyNotifier;

  Future<void> _init() async {
    if (!_isInitialized) {
      _prefs = await SharedPreferences.getInstance();
      _isInitialized = true;
      _isReadyNotifier.value = true;  // Add this
      _loadInitialData();
    }
  }

  void _loadInitialData() {
    if (_currentUserId == null) {
      print('No user ID during load');
      _cardsController.add([]);
      return;
    }

    try {
      final cards = _getCards();
      // Only emit if cards are different from last emission
      if (_lastEmittedCards == null || !_areCardListsEqual(_lastEmittedCards!, cards)) {
        _lastEmittedCards = cards;
        _cardsController.add(cards);
      }
    } catch (e) {
      print('Error loading cards: $e');
      _cardsController.add([]);
    }
  }

  // Add helper method to compare card lists
  bool _areCardListsEqual(List<TcgCard> list1, List<TcgCard> list2) {
    if (list1.length != list2.length) return false;
    for (var i = 0; i < list1.length; i++) {
      if (list1[i].id != list2[i].id) return false;
    }
    return true;
  }

  Stream<List<TcgCard>> watchCards() {
    if (!_isInitialized) {
      return Stream.value([]);
    }
    
    final cards = _getCards();
    return _cardsController.stream.startWith(cards);
  }

  Future<void> refreshCards() async {
    await _loadCards();
  }

  // Changed to synchronous internal method
  List<TcgCard> _getCards() {
    if (_currentUserId == null) return [];
    
    final cardsKey = _getUserKey('cards');
    final cardsJson = _prefs.getStringList(cardsKey) ?? [];
    
    final cards = cardsJson
        .where((json) => json.isNotEmpty)
        .map((json) {
          try {
            final data = jsonDecode(json);
            return TcgCard.fromJson(data);
          } catch (e) {
            return null;
          }
        })
        .where((card) => card != null)
        .cast<TcgCard>()
        .toList();
    
    return cards;
  }

  // Keep async public method
  Future<List<TcgCard>> getCards() async {
    try {
      final key = _getCardsKey();
      final jsonList = _prefs.getStringList(key) ?? [];
      return jsonList
          .map((json) => TcgCard.fromJson(jsonDecode(json)))
          .toList();
    } catch (e) {
      print('❌ Storage error: $e');
      return [];
    }
  }

  Future<void> _loadCards() async {
    try {
      final cards = await getAllCards();
      _cardsController.add(cards);
    } catch (e) {
      _cardsController.addError(e);
    }
  }

  // Add this method
  Future<List<TcgCard>> getAllCards() async {
    if (!_isInitialized) return [];
    return _getCards();
  }

  // Changed to internal sync method
  Future<void> _saveCard(TcgCard card) async {
    if (_currentUserId == null) return;
    
    final cardsKey = _getUserKey('cards');
    print('Saving card to key: $cardsKey');
    
    final existingCardsJson = _prefs.getStringList(cardsKey) ?? [];
    print('Found existing cards: ${existingCardsJson.length}');
    
    final existingCards = existingCardsJson
        .map((json) => jsonDecode(json) as Map<String, dynamic>)
        .toList();
    
    if (!existingCards.any((c) => c['id'] == card.id)) {
      existingCards.add(card.toJson());
      
      final updatedCardsJson = existingCards
          .map((c) => jsonEncode(c))
          .cast<String>()
          .toList();
      
      await _prefs.setStringList(cardsKey, updatedCardsJson);
      print('Saved cards. New total: ${existingCards.length}');
      
      // Ensure cards are reloaded
      final updatedCards = _getCards();
      _cardsController.add(updatedCards);
    }
  }

  // Make saveCard public method async
  Future<void> saveCard(TcgCard card) async {
    if (_currentUserId == null) return;

    try {
      final cardsKey = _getUserKey('cards');
      final existingCardsJson = _prefs.getStringList(cardsKey) ?? [];
      
      // Clean and validate existing cards
      final existingCards = existingCardsJson
          .map((json) {
            try {
              if (json.isEmpty) return null;
              
              final data = jsonDecode(json);
              if (data == null || data is! Map<String, dynamic>) return null;
              
              // Validate required fields
              if (data['id'] == null || data['name'] == null) return null;
              
              return TcgCard.fromJson(data);
            } catch (e) {
              print('Error parsing existing card: $e');
              return null;
            }
          })
          .where((card) => card != null)
          .cast<TcgCard>()
          .toList();
      
      // Remove any existing versions of this card
      existingCards.removeWhere((c) => c.id == card.id);
      
      // Add the new card
      existingCards.add(card);

      // Save back to storage with validation
      final updatedCardsJson = existingCards
          .map((c) {
            try {
              final json = jsonEncode(c.toJson());
              // Verify the JSON is valid
              jsonDecode(json);
              return json;
            } catch (e) {
              print('Error encoding card: $e');
              return null;
            }
          })
          .where((json) => json != null)
          .cast<String>()
          .toList();

      await _prefs.setStringList(cardsKey, updatedCardsJson);
      
      // Update stream and notify listeners
      _cardsController.add(existingCards);
      _notifyCardChange();
      
    } catch (e) {
      print('Error saving card: $e');
      rethrow;
    }
  }

  Future<void> addCard(TcgCard card) async {
    final cards = await getCards();
    final currentCount = cards.length;
    
    print('DEBUG: Adding card when count=$currentCount, limit=$_freeUserCardLimit, isPremium=${_purchaseService.isPremium}');
    
    if (!_purchaseService.isPremium && currentCount >= _freeUserCardLimit) {
      throw 'Free users can only add up to $_freeUserCardLimit cards. Upgrade to Premium for unlimited cards!';
    }

    await saveCard(card);
  }

  bool canAddMoreCards() {
    if (_purchaseService.isPremium) return true;
    final currentCount = _getCards().length;
    print('Can add more cards? Current count: $currentCount, Limit: $_freeUserCardLimit'); // Debug print
    return currentCount < _freeUserCardLimit;
  }

  int get remainingFreeSlots {
    if (_purchaseService.isPremium) return -1; // -1 indicates unlimited
    return _freeUserCardLimit - _getCards().length;  // This is correct
  }

  final Map<String, TcgCard> _removedCards = {};

  Future<void> removeCard(String cardId) async {
    if (_currentUserId == null) return;
    
    try {
      // First, get the card data before removing
      final cards = await getCards();
      final removedCard = cards.firstWhere((card) => card.id == cardId);
      
      // Store in removed cards cache
      _cardCache[cardId] = removedCard;
      _lastRemovedCard = (cardId, removedCard);

      // Remove from storage
      final cardsKey = _getUserKey('cards');
      final existingCardsJson = _prefs.getStringList(cardsKey) ?? [];
      final updatedCardsJson = existingCardsJson
          .where((json) {
            final card = TcgCard.fromJson(jsonDecode(json));
            return card.id != cardId;
          })
          .toList();

      await _prefs.setStringList(cardsKey, updatedCardsJson);
      
      // Update the stream and notify listeners
      final updatedCards = await getCards();
      _cardsController.add(updatedCards);
      
      // Make sure to notify card changes
      _notifyCardChange();
      
    } catch (e) {
      print('Error removing card: $e');
      rethrow;
    }
  }

  Future<void> undoRemoveCard(String cardId) async {
    if (_currentUserId == null || _lastRemovedCard == null) return;
    final (lastCardId, card) = _lastRemovedCard!;
    
    if (lastCardId == cardId) {
      await saveCard(card);
      _lastRemovedCard = null;
    }
  }

  Future<bool?> getBool(String key) async {
    if (!_isInitialized) return null;
    // Use user-specific key for theme preference
    final userKey = _getUserKey(key);
    return _prefs.getBool(userKey);
  }

  Future<bool> setBool(String key, bool value) async {
    if (!_isInitialized) return false;
    // Use user-specific key for theme preference
    final userKey = _getUserKey(key);
    return await _prefs.setBool(userKey, value);
  }

  Future<List<TcgCard>> _loadCardsFromJson(String jsonStr) async {
    try {
      final List<dynamic> jsonList = json.decode(jsonStr);
      return jsonList.map((cardJson) {
        try {
          return TcgCard.fromJson(cardJson);
        } catch (e) {
          print('Error parsing card: $e');
          return null;
        }
      })
      .whereType<TcgCard>() // Filter out null values
      .toList();
    } catch (e) {
      print('Error loading cards: $e');
      return [];
    }
  }

  // Update the debug method to use proper stream handling
  Future<void> debugStorage() async {
    print('Current user ID: $_currentUserId');
    final cardsKey = _getUserKey('cards');
    final cards = _prefs.getStringList(cardsKey) ?? [];
    print('Total cards in storage: ${cards.length}');
    
    // Get current cards from storage instead of trying to access stream value
    final currentCards = _getCards();
    print('Current cards in memory: ${currentCards.length}');
  }

  Future<void> setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<String?> getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  Future<void> clearSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('search_history');
  }

  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<Map<String, dynamic>> exportUserData() async {
    final prefs = await SharedPreferences.getInstance();
    // Implement data export logic
    return {
      'user_settings': {
        'analytics_enabled': prefs.getBool('analytics_enabled'),
        'search_history_enabled': prefs.getBool('search_history_enabled'),
        'profile_visible': prefs.getBool('profile_visible'),
        'show_prices': prefs.getBool('show_prices'),
      },
      'search_history': prefs.getStringList('search_history'),
      // Add other user data as needed
    };
  }

  // Add notification mechanism
  final _cardChangeController = StreamController<void>.broadcast();
  Stream<void> get onCardsChanged => _cardChangeController.stream;

  void _notifyCardChange() {
    _cardChangeController.add(null);
  }

  void notifyPriceUpdateProgress(int current, int total) {
    _priceUpdateController.add((current, total));
  }

  void notifyPriceUpdateComplete(int updatedCount) {
    _priceUpdateCompleteController.add(updatedCount);
  }

  // Remove the await from dispose since dispose is synchronous
  @override
  void dispose() {
    _isReadyNotifier.dispose();  // Add this
    _cardsController.close();
    _cardChangeController.close();
    backgroundService?.dispose();
    _priceUpdateController.close();
    _priceUpdateCompleteController.close();
  }

  // Add public getter for premium status
  bool get isPremium => _purchaseService.isPremium;

  Future<void> updateCard(TcgCard card) async {
    if (_currentUserId == null) return;  // Changed from _userId to _currentUserId

    final cards = await getCards();
    
    // Find and update the existing card
    final index = cards.indexWhere((c) => c.id == card.id);
    if (index != -1) {
      cards[index] = card;
      
      // Save all cards back to storage
      final cardsKey = _getUserKey('cards');
      final updatedCardsJson = cards
          .map((c) => jsonEncode(c.toJson()))
          .toList();
      
      await _prefs.setStringList(cardsKey, updatedCardsJson);
      
      // Notify listeners
      _cardsController.add(cards);
    }
  }

  String _getCardsKey() {
    return _getUserKey('cards');
  }

  // Add this field at the top of the class
  List<TcgCard>? _lastEmittedCards;

  void _debugLog(String message, {bool verbose = false}) {
    if (kDebugMode && !verbose) {
      print(message);
    }
  }

  Future<void> refreshPrices() async {
    _debugLog('Starting price refresh...', verbose: true);
    // ...existing code...
  }
}
