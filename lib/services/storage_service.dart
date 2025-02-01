import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../models/tcg_card.dart';
import 'package:collection/collection.dart';
import '../services/purchase_service.dart';
import '../services/tcg_api_service.dart';
import '../services/background_service.dart';

class StorageService {
  static const int _freeUserCardLimit = 25;  // Changed from 10 to 25
  final PurchaseService _purchaseService;
  static StorageService? _instance;

  // Change from late final to nullable
  BackgroundService? backgroundService;

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
      await _instance!._initializeBackgroundService();  // Then initialize background service
    }
    return _instance!;
  }

  // Rename method to be more specific
  Future<void> _initializeBackgroundService() async {
    try {
      final apiService = TcgApiService();
      backgroundService = BackgroundService(this, apiService);
      // Don't await the startPriceUpdates, let it run in the background
      backgroundService?.startPriceUpdates();
    } catch (e) {
      print('Error initializing background service: $e');
      // Don't rethrow - we want the app to work even if background service fails
    }
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
      print('No user ID during load');
      _cardsController.add([]);
      return;
    }

    final cardsKey = _getUserKey('cards');
    print('Loading cards with key: $cardsKey');
    
    final cardsJson = _prefs.getStringList(cardsKey) ?? [];
    print('Found ${cardsJson.length} cards in storage');

    try {
      final cards = cardsJson.map((json) {
        try {
          final data = jsonDecode(json);
          if (data == null) return null;
          
          // Convert to Map<String, dynamic> and validate
          final cardData = Map<String, dynamic>.from(data);
          if (cardData['id'] == null || cardData['name'] == null) {
            print('Invalid card data, skipping: $cardData');
            return null;
          }
          
          return TcgCard.fromJson(cardData);
        } catch (e) {
          print('Error parsing card JSON: $e');
          return null;
        }
      })
      .where((card) => card != null)
      .cast<TcgCard>()
      .toList();

      _cardsController.add(cards);
    } catch (e) {
      print('Error loading cards: $e');
      _cardsController.add([]);
    }
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
      return cardsJson.map((json) {
        try {
          if (json.isEmpty) {
            print('Empty JSON string found');
            return null;
          }
          
          final dynamic decoded = jsonDecode(json);
          if (decoded == null) {
            print('Null JSON data found');
            return null;
          }
          
          if (decoded is! Map<String, dynamic>) {
            print('Invalid JSON format: $decoded');
            return null;
          }
          
          // Validate required fields
          if (decoded['id'] == null || decoded['name'] == null) {
            print('Missing required fields in card data: $decoded');
            return null;
          }
          
          // Ensure all string fields are actually strings
          final sanitizedData = Map<String, dynamic>.fromEntries(
            decoded.entries.map((e) {
              if (e.value == null && (
                  e.key == 'id' || 
                  e.key == 'name' || 
                  e.key == 'imageUrl' ||
                  e.key == 'setName' ||
                  e.key == 'number'
                )) {
                return MapEntry(e.key, '');  // Convert null to empty string for required string fields
              }
              return e;
            }),
          );
          
          return TcgCard.fromJson(sanitizedData);
        } catch (e, stack) {
          print('Error parsing card JSON: $e');
          print('JSON data: $json');
          print('Stack trace: $stack');
          return null;
        }
      })
      .where((card) => card != null)
      .cast<TcgCard>()
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

  // Remove the await from dispose since dispose is synchronous
  @override
  void dispose() {
    _cardsController.close();
    _cardChangeController.close();
    backgroundService?.dispose();
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
}
