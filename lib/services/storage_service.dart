import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../models/tcg_card.dart';
import 'package:collection/collection.dart';  // Add this import at the top
import '../services/purchase_service.dart';  // Add this import

class StorageService {
  static const int _freeUserCardLimit = 10;
  final PurchaseService _purchaseService;
  static StorageService? _instance;

  // Private constructor with purchase service
  StorageService._(this._purchaseService);

  static Future<StorageService> init(PurchaseService? purchaseService) async {
    if (_instance == null) {
      final purchase = purchaseService ?? PurchaseService();
      if (purchaseService == null) {
        await purchase.initialize();
      }
      _instance = StorageService._(purchase);
      await _instance!._init();
    }
    return _instance!;
  }

  late final SharedPreferences _prefs;
  late final Database _db;
  final _cardsController = StreamController<List<TcgCard>>.broadcast();
  bool _isInitialized = false;
  String? _currentUserId;
  final Map<String, TcgCard> _cardCache = {};
  (String, TcgCard)? _lastRemovedCard;

  // Update the key format to be consistent
  String _getUserKey(String key) {
    return _currentUserId != null ? 'user_${_currentUserId}_$key' : key;
  }

  void setCurrentUser(String? userId) {
    print('Setting current user: $userId');
    _currentUserId = userId;
    
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

  Future<void> _init() async {
    if (!_isInitialized) {
      _prefs = await SharedPreferences.getInstance();
      _isInitialized = true;
      _loadInitialData();
    }
  }

  void _loadInitialData() {
    if (_currentUserId == null) {
      _cardsController.add([]);
      return;
    }
    final cards = _getCards();
    _cardsController.add(cards);
  }

  Stream<List<TcgCard>> watchCards() {
    if (!_isInitialized) {
      return Stream.value([]);
    }
    _loadCards(); // Refresh when stream is requested
    return _cardsController.stream;
  }

  Future<void> refreshCards() async {
    await _loadCards();
  }

  // Changed to synchronous internal method
  List<TcgCard> _getCards() {
    if (_currentUserId == null) return [];
    
    final cardsKey = _getUserKey('cards');
    print('Getting cards with key: $cardsKey');
    
    final cardsJson = _prefs.getStringList(cardsKey) ?? [];
    print('Found ${cardsJson.length} cards in storage');
    
    try {
      return cardsJson
          .map((json) => TcgCard.fromJson(jsonDecode(json)))
          .toList();
    } catch (e) {
      print('Error loading cards: $e');
      return [];
    }
  }

  // Keep async public method
  Future<List<TcgCard>> getCards() async {
    if (!_isInitialized) return [];
    return _getCards();
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
    if (_currentUserId == null) {
      print('No user ID when saving card');
      return;
    }

    try {
      final cardsKey = _getUserKey('cards');
      print('Saving card ${card.name} to key: $cardsKey');
      
      // Get existing cards
      final existingCardsJson = _prefs.getStringList(cardsKey) ?? [];
      final existingCards = existingCardsJson
          .map((json) => TcgCard.fromJson(jsonDecode(json)))
          .toList();
      
      // Check if card already exists
      if (!existingCards.any((c) => c.id == card.id)) {
        existingCards.add(card);
        
        // Save updated list
        final updatedCardsJson = existingCards
            .map((c) => jsonEncode(c.toJson()))
            .toList();
        
        await _prefs.setStringList(cardsKey, updatedCardsJson);
        
        // Update stream with new cards
        _cardsController.add(existingCards);
        
        print('Added card: ${card.name}. Total cards: ${existingCards.length}');
      } else {
        print('Card ${card.name} already exists in collection');
      }
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
      
      // Update the stream
      final updatedCards = await getCards();
      _cardsController.add(updatedCards);
      
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

  void dispose() {
    _cardsController.close();
  }
}
