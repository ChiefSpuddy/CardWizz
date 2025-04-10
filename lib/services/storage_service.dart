import '../services/logging_service.dart';
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:collection/collection.dart';
import '../services/purchase_service.dart';
import '../services/tcg_api_service.dart';
import 'package:rxdart/rxdart.dart'; // Add this import
import 'package:path/path.dart' show join;
import 'package:sqflite/sqflite.dart' show Database, openDatabase, getDatabasesPath;
import '../services/background_price_update_service.dart';  // Add this import
import '../utils/logger.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode and debugPrint
import '../models/tcg_card.dart';  // For TcgCard model
import '../models/tcg_set.dart';   // For TcgSet model
import '../models/price_history_entry.dart'; // For PriceHistoryEntry

class StorageService {
  static const int _freeUserCardLimit = 25;  // Changed from 10 to 25
  final PurchaseService _purchaseService;
  static StorageService? _instance;

  // Change from late final to nullable

  // Add these fields
  late final SharedPreferences _prefs;
  final _cardsController = StreamController<List<TcgCard>>.broadcast();
  bool _isInitialized = false;
  String? _currentUserId;
  final Map<String, TcgCard> _cardCache = {};
  (String, TcgCard)? _lastRemovedCard;
  List<TcgCard>? _cachedCards; // Add this missing field

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
    }
    return _instance!;
  }

  // This method only clears in-memory state
  Future<void> clearSessionState() async {
    _cardCache.clear();
    _lastRemovedCard = null;
    _cardsController.add([]);
    _currentUserId = null;
  }

  // Modify the setCurrentUser method
  void setCurrentUser(String? userId) {
    AppLogger.d('Setting current user ID: $userId (was: $_currentUserId)', tag: 'Storage');
    _currentUserId = userId;
    
    if (userId == null) {
      // Just clear in-memory state
      clearSessionState();
      return;
    }
    
    // Save userId to SharedPreferences for persistence across app restarts
    _prefs.setString('current_storage_user', userId);
    
    // Load data immediately to ensure it's available
    _loadInitialData();
    
    // Explicitly print card count to verify it worked
    final cardCount = _getCards().length;
    AppLogger.d('Storage loaded $cardCount cards for user $userId', tag: 'Storage');
    
    // Force emit to stream
    _cardsController.add(_getCards());
  }

  // Only used during account deletion
  Future<void> permanentlyDeleteUserData() async {
    if (_currentUserId == null) return;

    try {
      final userId = _currentUserId;
      
      // Delete all data for this user
      final userKeys = _prefs.getKeys()
          .where((key) => key.startsWith('user_${userId}_'))
          .toList();

      for (final key in userKeys) {
        await _prefs.remove(key);
      }

      await clearSessionState();
      
      AppLogger.d('Permanently deleted all data for user: $userId', tag: 'Storage');
      
    } catch (e) {
      AppLogger.e('Error deleting user data', tag: 'Storage', error: e);
      rethrow;
    }
  }

  final _isReadyNotifier = ValueNotifier<bool>(false);
  ValueNotifier<bool> get isReady => _isReadyNotifier;

  Future<void> _init() async {
    if (!_isInitialized) {
      try {
        // First load SharedPreferences as it's critical
        _prefs = await SharedPreferences.getInstance();
        
        // Set initialized flag early - actual data can load in background
        _isInitialized = true;
        _isReadyNotifier.value = true;
        
        // Look for stored user ID and restore it
        final savedUserId = _prefs.getString('current_user_id') ?? 
                           _prefs.getString('user_id');
        
        if (savedUserId != null) {
          AppLogger.d('StorageService found saved user ID: $savedUserId', tag: 'Storage');
          _currentUserId = savedUserId;
          
          // Load data in background to avoid blocking UI
          Future.microtask(() => _loadInitialData());
        }
        
        _isSyncEnabled = _prefs.getBool('sync_enabled') ?? false;
        
        // Don't wait for sync to finish initialization
        if (_isSyncEnabled) {
          // Start sync in background
          Future.delayed(
            const Duration(seconds: 2),
            () => _doSync(force: false),
          );
        }
      } catch (e) {
        AppLogger.e('Error initializing storage service', tag: 'Storage', error: e);
        // Still mark as initialized to avoid blocking app startup
        _isInitialized = true;
        _isReadyNotifier.value = true;
        rethrow;
      }
    }
  }

  void _loadInitialData() {
    if (_currentUserId == null) {
      AppLogger.d('No user ID during load', tag: 'Storage');
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
      AppLogger.e('Error loading cards', tag: 'Storage', error: e);
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

  // Make sure watchCards() always emits current data
  Stream<List<TcgCard>> watchCards({bool verbose = false}) {
    // Only log if verbose is true to reduce log spam
    if (verbose) {
      debugPrint('watchCards called, currentUserId: $_currentUserId, initialized: $_isInitialized');
      
      if (!_isInitialized || _currentUserId == null) {
        return Stream.value([]);
      }
      
      // Always load fresh cards from storage
      final cards = _getCards();
      debugPrint('watchCards: returning ${cards.length} cards for user $_currentUserId');
      
      // Create a new stream that emits current cards immediately then listens for updates
      return _cardsController.stream.startWith(cards);
    } else {
      // Same functionality but without the logging
      if (!_isInitialized || _currentUserId == null) {
        return Stream.value([]);
      }
      
      final cards = _getCards();
      return _cardsController.stream.startWith(cards);
    }
  }

  Future<void> refreshCards() async {
  // Only load cards, don't trigger other UI updates
  try {
    if (_currentUserId == null) {
      AppLogger.d('Cannot refresh cards: No current user ID', tag: 'Storage');
      return;
    }
    
    final cards = _getCards();
    _cardsController.add(cards);
    
    // Don't call _notifyCardChange() to avoid cascading UI updates
    AppLogger.d('Cards refreshed: ${cards.length} cards loaded', tag: 'Storage');
  } catch (e) {
    AppLogger.e('Error refreshing cards', tag: 'Storage', error: e);
  }
}

  // Simplify the card storage/retrieval methods
  List<TcgCard> _getCards() {
    if (_currentUserId == null) return [];
    
    final cardsKey = _getUserKey('cards');
    
    try {
      // Try to get the cards JSON string
      final cardsJson = _prefs.getString(cardsKey);
      if (cardsJson != null) {
        try {
          final List<dynamic> decoded = jsonDecode(cardsJson);
          _cachedCards = decoded
              .map((item) => TcgCard.fromJson(item as Map<String, dynamic>))
              .toList();
          return _cachedCards!;
        } catch (e) {
          AppLogger.e('Error decoding cards JSON', tag: 'Storage', error: e);
        }
      }
    } catch (e) {
      AppLogger.e('Error loading cards', tag: 'Storage', error: e);
    }
    
    _cachedCards = [];
    return [];
  }

  // Keep async public method
  Future<List<TcgCard>> getCards() async {
    try {
      // Cache optimization: if we have loaded cards in memory and there are some,
      // return them immediately to speed up first render
      final cachedCards = _getCards();
      if (cachedCards.isNotEmpty) {
        return cachedCards;
      }
      
      // Otherwise continue with normal loading
      return _getCards();
    } catch (e) {
      AppLogger.e('❌ Storage error', tag: 'Storage', error: e);
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

  // Update save method to use consistent format
  Timer? _syncDebounceTimer;
  static const _syncDebounceTime = Duration(seconds: 3);

  // Enhanced version of saveCard with better preventNavigation handling
  Future<void> saveCard(TcgCard card, {bool preventNavigation = false}) async {
    if (_currentUserId == null) return;

    try {
      // IMPORTANT: Always ensure dateAdded is set for analytics
      final now = DateTime.now();
      final cardWithDate = card.copyWith(
        dateAdded: card.dateAdded ?? now,  // Use existing date if present, otherwise use now
        addedToCollection: card.addedToCollection ?? now,
        price: card.price,
        priceHistory: card.priceHistory.isEmpty && card.price != null ? 
          [PriceHistoryEntry(price: card.price!, timestamp: now)] : 
          card.priceHistory,
      );

      // Get current cards
      final cardsKey = _getUserKey('cards');
      final currentCards = _getCards();
      
      // Remove existing version if any
      currentCards.removeWhere((c) => c.id == card.id);
      currentCards.add(cardWithDate);

      // Save all cards as a single JSON string
      final cardsJson = jsonEncode(currentCards.map((c) => c.toJson()).toList());
      await _prefs.setString(cardsKey, cardsJson);

      // Update portfolio value
      final totalValue = currentCards.fold<double>(
        0, 
        (sum, card) => sum + (card.price ?? 0)
      );
      await savePortfolioValue(totalValue);

      // Update the stream - all listeners will still get this
      _cardsController.add(currentCards);
      
      // CRITICAL FIX: Don't call notifyCardChange when preventNavigation is true
      // Instead just use the direct stream notification that has no navigation logic
      if (preventNavigation) {
        // Just notify simple subscribers without app-level navigation triggers
        _cardChangeController.add(null);
        LoggingService.debug('Card saved with navigation prevention');
      } else {
        // Normal path with potential navigation
        _notifyCardChange();
        LoggingService.debug('Card saved with standard notification');
      }

    } catch (e) {
      AppLogger.e('Error saving card', tag: 'Storage', error: e);
      rethrow;
    }
  }

  Future<void> addCard(TcgCard card) async {
    final cards = await getCards();
    final currentCount = cards.length;
    
    AppLogger.d('DEBUG: Adding card when count=$currentCount, limit=$_freeUserCardLimit, isPremium=${_purchaseService.isPremium}', tag: 'Storage');
    AppLogger.d('DEBUG: Current user ID: $_currentUserId', tag: 'Storage');
    
    if (!_purchaseService.isPremium && currentCount >= _freeUserCardLimit) {
      throw 'Free users can only add up to $_freeUserCardLimit cards. Upgrade to Premium for unlimited cards!';
    }

    await saveCard(card);
    
    // Verify the card was saved correctly
    final updatedCards = await getCards();
    if (updatedCards.any((c) => c.id == card.id)) {
      AppLogger.d('DEBUG: Card ${card.name} successfully added to storage', tag: 'Storage');
    } else {
      AppLogger.d('DEBUG: ERROR - Card ${card.name} NOT found in storage after save!', tag: 'Storage');
    }
    
    await refreshState();
  }

  bool canAddMoreCards() {
    if (_purchaseService.isPremium) return true;
    final currentCount = _getCards().length;
    AppLogger.d('Can add more cards? Current count: $currentCount, Limit: $_freeUserCardLimit', tag: 'Storage'); // Debug print
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
      final remainingCards = cards.where((card) => card.id != cardId).toList();
      
      // Calculate new total value after removal
      final totalValue = remainingCards.fold<double>(
        0, 
        (sum, card) => sum + (card.price ?? 0)
      );

      // Save the portfolio value point
      await _savePortfolioValuePoint(totalValue, DateTime.now());

      // Save remaining cards using consistent JSON string format
      final cardsKey = _getUserKey('cards');
      final cardsJson = jsonEncode(remainingCards.map((c) => c.toJson()).toList());
      await _prefs.setString(cardsKey, cardsJson);
      
      // Update the stream and notify listeners
      final updatedCards = await getCards();
      _cardsController.add(updatedCards);
      
      // Make sure to notify card changes
      _notifyCardChange();
      
      // Recalculate portfolio history
      await recalculatePortfolioHistory();
      await refreshState(); // Add this line

    } catch (e) {
      AppLogger.e('Error removing card', tag: 'Storage', error: e);
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
          AppLogger.e('Error parsing card', tag: 'Storage', error: e);
          return null;
        }
      })
      .whereType<TcgCard>() // Filter out null values
      .toList();
    } catch (e) {
      AppLogger.e('Error loading cards', tag: 'Storage', error: e);
      return [];
    }
  }

  // Update the debug method to use proper stream handling
  Future<void> debugStorage() async {
    AppLogger.d('Current user ID: $_currentUserId', tag: 'Storage');
    final cardsKey = _getUserKey('cards');
    final cards = _prefs.getStringList(cardsKey) ?? [];
    AppLogger.d('Total cards in storage: ${cards.length}', tag: 'Storage');
    
    // Get current cards from storage instead of trying to access stream value
    final currentCards = _getCards();
    AppLogger.d('Current cards in memory: ${currentCards.length}', tag: 'Storage');
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
    _syncDebounceTimer?.cancel();  // Add this
    _syncStatusController.close();
    _syncProgressController.close();
    _isReadyNotifier.dispose();  // Add this
    _cardsController.close();
    _cardChangeController.close();
    _priceUpdateController.close();
    _priceUpdateCompleteController.close();
  }

  // Add public getter for premium status
  bool get isPremium => _purchaseService.isPremium;

  Future<void> updateCard(TcgCard card) async {
    if (_currentUserId == null) return;

    final cards = await getCards();
    final index = cards.indexWhere((c) => c.id == card.id);
    
    if (index != -1) {
      final existingCard = cards[index];
      
      // Only add price history if price has changed
      if (card.price != null && card.price! > 0 && card.price != existingCard.price) {
        final now = DateTime.now();
        final updatedCard = existingCard.copyWith(
          price: card.price,
          lastPriceUpdate: now,
        );
        
        // Add new price point to history
        updatedCard.addPriceHistoryPoint(card.price!, now);
        
        cards[index] = updatedCard;
        
        // Save all cards as a single JSON string
        final cardsKey = _getUserKey('cards');
        final cardsJson = jsonEncode(cards.map((c) => c.toJson()).toList());
        await _prefs.setString(cardsKey, cardsJson);
        _cardsController.add(cards);
      }
    }
  }

  // Replace all other similar occurrences of setString with JSON array
  Future<void> saveCards(List<TcgCard> cards) async {
    if (_currentUserId == null) return;
    
    final cardsKey = _getUserKey('cards');
    final cardsJson = jsonEncode(cards.map((c) => c.toJson()).toList());
    await _prefs.setString(cardsKey, cardsJson);
  }

  String _getCardsKey() {
    return _getUserKey('cards');
  }

  // Add this field at the top of the class
  List<TcgCard>? _lastEmittedCards;

  void _debugLog(String message, {bool verbose = false}) {
    if (kDebugMode && !verbose) {
      LoggingService.debug(message);
    }
  }

  Future<void> refreshPrices() async {
    _debugLog('Starting price refresh...', verbose: true);
    // ...existing code...
  }

  // Add this getter
  String getUserKey(String key) => _getUserKey(key);

  // Add this getter
  SharedPreferences get prefs => _prefs;

  Future<void> addPriceHistoryPoint(String cardId, double price, DateTime timestamp) async {
    if (_currentUserId == null) return;

    try {
      final cards = await getCards();
      final cardIndex = cards.indexWhere((c) => c.id == cardId);
      
      if (cardIndex != -1) {
        final card = cards[cardIndex];
        
        // Ensure we don't add duplicate entries for the same day
        final today = DateTime(timestamp.year, timestamp.month, timestamp.day);
        final hasTodayEntry = card.priceHistory
            .any((entry) => entry.timestamp.day == today.day && 
                          entry.timestamp.month == today.month &&
                          entry.timestamp.year == today.year);
        
        if (!hasTodayEntry) {
          card.priceHistory.add(PriceHistoryEntry(
            price: price,
            timestamp: timestamp,
          ));
          
          // Keep only last 30 days of history
          final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
          card.priceHistory.removeWhere((entry) => 
            entry.timestamp.isBefore(thirtyDaysAgo));
            
          // Sort by date
          card.priceHistory.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          
          await saveCard(card);
        }
      }
    } catch (e) {
      AppLogger.e('Error adding price history point', tag: 'Storage', error: e);
    }
  }

  // Add these database-related fields at the top of the class
  static const String _dbName = 'cardwizz.db';
  static const int _dbVersion = 1;
  Database? _db;

  // Add this method to get database instance
  Future<Database> _getDb() async {
    if (_db != null) return _db!;

    // Initialize the database
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    _db = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: (Database db, int version) async {
        // Create price history table
        await db.execute('''
          CREATE TABLE price_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            card_id TEXT NOT NULL,
            price REAL NOT NULL,
            timestamp TEXT NOT NULL,
            source TEXT NOT NULL,
            UNIQUE(card_id, timestamp)
          )
        ''');
      },
    );

    return _db!;
  }

  Future<void> updateCardPrice(TcgCard card, double newPrice) async {
    if (_currentUserId == null) return;
    
    try {
      final cards = await getCards();
      final index = cards.indexWhere((c) => c.id == card.id);
      
      if (index != -1) {
        final now = DateTime.now();
        final existingCard = cards[index];
        
        if (newPrice != existingCard.price) {
          // Store previous price before updating
          final previousPrice = existingCard.price;
          
          // Create updated card with new price - DON'T use lastPriceUpdate in constructor
          final updatedCard = existingCard.copyWith(
            price: newPrice,
          );
          
          // Set the timestamp fields AFTER creating the card
          updatedCard.lastPriceUpdate = now;
          updatedCard.previousPrice = previousPrice;
          updatedCard.lastPriceChange = now;
          
          // Add new price point to history
          updatedCard.priceHistory.add(
            PriceHistoryEntry(price: newPrice, timestamp: now)
          );
          
          cards[index] = updatedCard;
          
          // Save updated cards and portfolio value
          final cardsKey = _getUserKey('cards');
          final cardsJson = jsonEncode(cards.map((c) => c.toJson()).toList());
          await _prefs.setString(cardsKey, cardsJson);
          
          // Calculate and save new portfolio value
          final totalValue = cards.fold<double>(
            0, 
            (sum, card) => sum + (card.price ?? 0)
          );
          await savePortfolioValue(totalValue);
          
          _cardsController.add(cards);
          _notifyCardChange();
        }
      }
    } catch (e) {
      AppLogger.e('Error updating card price', tag: 'Storage', error: e);
      rethrow;
    }
  }

  Future<void> recalculatePortfolioHistory() async {
    if (_currentUserId == null) return;

    final cards = _getCards();
    final totalValue = cards.fold<double>(0, (sum, card) => sum + (card.price ?? 0));
    await _addPortfolioValuePoint(totalValue, DateTime.now());
  }

  // Add this method to save portfolio history
  Future<void> savePortfolioValue(double value) async {
    if (_currentUserId == null) return;

    try {
      final now = DateTime.now();
      await _addPortfolioValuePoint(value, now);
      AppLogger.d('Saved new portfolio value point: $value at ${now.toIso8601String()}', tag: 'Storage');
      _notifyCardChange();  // Make sure to notify listeners
    } catch (e) {
      AppLogger.e('Error saving portfolio value', tag: 'Storage', error: e);
    }
  }

  BackgroundPriceUpdateService? backgroundService;

  Future<void> initializeBackgroundService() async {
    if (backgroundService != null) return; // Already initialized
    
    try {
      final apiService = TcgApiService();
      backgroundService = BackgroundPriceUpdateService(this);
      await backgroundService!.initialize();  // Initialize after creation
      AppLogger.d('Background service initialized successfully', tag: 'Storage');
    } catch (e) {
      AppLogger.e('Error initializing background service', tag: 'Storage', error: e);
      backgroundService = null;  // Reset on error
    }
  }

  // Add this getter
  bool get isBackgroundServiceEnabled => backgroundService?.isEnabled ?? false;

  Future<void> _savePortfolioValuePoint(double value, DateTime timestamp) async {
    final portfolioHistoryKey = _getUserKey('portfolio_history');
    List<Map<String, dynamic>> history = [];

    try {
      final historyJson = _prefs.getString(portfolioHistoryKey);
      if (historyJson != null) {
        history = (jsonDecode(historyJson) as List)
            .cast<Map<String, dynamic>>();
      }

      // Add new point
      history.add({
        'timestamp': timestamp.toIso8601String(),
        'value': value,
      });

      // Sort by timestamp
      history.sort((a, b) => DateTime.parse(a['timestamp'])
          .compareTo(DateTime.parse(b['timestamp'])));

      // Save back to storage
      await _prefs.setString(portfolioHistoryKey, jsonEncode(history));
      
    } catch (e) {
      AppLogger.e('Error saving portfolio value point', tag: 'Storage', error: e);
    }
  }

  Future<void> _addPortfolioValuePoint(double value, DateTime timestamp) async {
    if (_currentUserId == null) return;

    // Always store values in EUR (base currency)
    final portfolioHistoryKey = _getUserKey('portfolio_history');
    List<Map<String, dynamic>> history = [];

    try {
      final historyJson = _prefs.getString(portfolioHistoryKey);
      if (historyJson != null) {
        history = (jsonDecode(historyJson) as List)
            .cast<Map<String, dynamic>>();
      }

      // Add new point (storing in EUR)
      history.add({
        'timestamp': timestamp.toIso8601String(),
        'value': value,  // Value should already be in EUR when passed to this method
      });

      // Keep only last 30 days and sort
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      history.removeWhere((point) => DateTime.parse(point['timestamp']).isBefore(thirtyDaysAgo));
      history.sort((a, b) => DateTime.parse(a['timestamp']).compareTo(DateTime.parse(b['timestamp'])));

      // Save and notify
      await _prefs.setString(portfolioHistoryKey, jsonEncode(history));
      _notifyCardChange();
      
      AppLogger.d('Added portfolio value point: \$${value.toStringAsFixed(2)} at ${timestamp.toIso8601String()}', tag: 'Storage');
    } catch (e) {
      AppLogger.e('Error saving portfolio value point', tag: 'Storage', error: e);
    }
  }

  Future<void> updatePortfolioHistory(double currentValue) async {
    if (_currentUserId == null) return;  // Use _currentUserId instead of currentUserId

    // Ensure value is in EUR before storing
    final portfolioHistoryKey = getUserKey('portfolio_history');
    final historyJson = prefs.getString(portfolioHistoryKey);
    
    List<Map<String, dynamic>> history = [];
    if (historyJson != null) {
      history = List<Map<String, dynamic>>.from(json.decode(historyJson));
    }

    // Add new data point with current timestamp
    final newDataPoint = {
      'timestamp': DateTime.now().toIso8601String(),
      'value': currentValue,  // Store in EUR
    };

    history.add(newDataPoint);

    // Keep only last 30 days of data
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    history.removeWhere((point) => 
      DateTime.parse(point['timestamp']).isBefore(thirtyDaysAgo));

    await prefs.setString(portfolioHistoryKey, json.encode(history));
  }

  // Add this getter
  String? get currentUserId => _currentUserId;

  void notifyCardChange() {
    _cardChangeController.add(null);
  }

  Future<void> savePortfolioValuePoint(double value, DateTime timestamp) async {
    if (_currentUserId == null) return;

    try {
      // Always add new point without checking for duplicates
      final portfolioHistoryKey = _getUserKey('portfolio_history');
      List<Map<String, dynamic>> history = [];

      final historyJson = _prefs.getString(portfolioHistoryKey);
      if (historyJson != null) {
        history = (jsonDecode(historyJson) as List).cast<Map<String, dynamic>>();
      }

      // Add new point
      history.add({
        'timestamp': timestamp.toIso8601String(),
        'value': value,
      });

      // Keep only last 30 days and sort
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      history.removeWhere((point) => DateTime.parse(point['timestamp']).isBefore(thirtyDaysAgo));
      history.sort((a, b) => DateTime.parse(a['timestamp']).compareTo(DateTime.parse(b['timestamp'])));

      // Save and notify
      await _prefs.setString(portfolioHistoryKey, jsonEncode(history));
      _notifyCardChange();
      
      AppLogger.d('Added portfolio value point: \$${value.toStringAsFixed(2)} at ${timestamp.toIso8601String()}', tag: 'Storage');
    } catch (e) {
      AppLogger.e('Error saving portfolio value point', tag: 'Storage', error: e);
    }
  }

  // Add these fields at top of class with other fields
  bool _isSyncEnabled = false;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  DateTime? _lastSyncAttempt;
  final _syncStatusController = StreamController<String>.broadcast();
  final _syncProgressController = StreamController<double>.broadcast();
  final List<DateTime> _lastModifiedDates = [];
  static const Duration _minSyncInterval = Duration(minutes: 15);
  static const Duration _maxSyncInterval = Duration(hours: 4);

  // Add these getters
  bool get isSyncEnabled => _isSyncEnabled;
  Stream<String> get syncStatus => _syncStatusController.stream;
  Stream<double> get syncProgress => _syncProgressController.stream;

  // Add sync control methods
  void startSync() {
    if (_isSyncEnabled) return;
    _isSyncEnabled = true;
    _prefs.setBool('sync_enabled', true);  // Save sync state
    _syncStatusController.add('Sync enabled');
    _doSync(force: true);
  }

  void stopSync() {
    _isSyncEnabled = false;
    _prefs.setBool('sync_enabled', false);  // Save sync state
    _syncStatusController.add('Sync disabled');
  }

  Future<bool> syncNow() async {
    if (_currentUserId == null) return false;

    final now = DateTime.now();
    if (_lastSyncTime != null) {
      final timeSinceLastSync = now.difference(_lastSyncTime!);
      if (timeSinceLastSync < const Duration(seconds: 3)) {
        AppLogger.d('🕒 Last sync was ${timeSinceLastSync.inSeconds}s ago, waiting...', tag: 'Storage');
        return false;
      }
    }

    return _doSync(force: true);
  }

  Future<bool> _doSync({bool force = false}) async {
    if (_currentUserId == null) return false;

    try {
      if (_isSyncing && !force) {
        AppLogger.d('🔄 Sync already in progress, skipping', tag: 'Storage');
        return false;
      }
      
      _isSyncing = true;
      _syncStatusController.add('Syncing...');
      _syncProgressController.add(0.0);

      final cards = await getCards();
      AppLogger.d('📤 Syncing ${cards.length} cards to cloud...', tag: 'Storage');
      _syncProgressController.add(0.5);
      
      await _saveToCloud(cards);
      _syncProgressController.add(1.0);
      
      _lastSyncTime = DateTime.now();
      final message = 'Last synced: just now (${cards.length} cards)';
      AppLogger.d('✅ $message', tag: 'Storage');
      _syncStatusController.add(message);
      
      _isSyncing = false;
      return true;
    } catch (e) {
      AppLogger.e('❌ Sync error', tag: 'Storage', error: e);
      _syncStatusController.add('Sync failed: $e');
      _isSyncing = false;
      return false;
    }
  }

  Future<void> _saveToCloud(List<TcgCard> cards) async {
    try {
      AppLogger.d('📦 Preparing cloud save...', tag: 'Storage');
      final cardsJson = cards.map((card) => card.toJson()).toList();
      final key = 'user_${_currentUserId}_cards';
      await _prefs.setString(key, jsonEncode(cardsJson));
      
      _lastModifiedDates.add(DateTime.now());
      if (_lastModifiedDates.length > 100) {
        _lastModifiedDates.removeAt(0);
      }
      AppLogger.d('✅ Successfully saved to cloud storage', tag: 'Storage');
    } catch (e) {
      AppLogger.e('❌ Error saving to cloud', tag: 'Storage', error: e);
      rethrow;
    }
  }

  Duration _calculateNextSyncInterval() {
    final changes = _lastModifiedDates.length;
    if (changes > 10) {
      return _minSyncInterval;
    } else if (changes > 5) {
      return Duration(minutes: 30);
    } else {
      return _maxSyncInterval;
    }
  }

  Future<void> debugSyncStatus() async {
    if (_currentUserId == null) {
      AppLogger.e('❌ No user logged in', tag: 'Storage');
      return;
    }

    AppLogger.d('📊 Sync Status Debug:', tag: 'Storage');
    AppLogger.d('--------------------', tag: 'Storage');
    AppLogger.d('Sync Enabled: $_isSyncEnabled', tag: 'Storage');
    AppLogger.d('Currently Syncing: $_isSyncing', tag: 'Storage');
    AppLogger.d('Last Sync: ${_lastSyncTime?.toLocal() ?? 'Never'}', tag: 'Storage');
    AppLogger.d('User ID: $_currentUserId', tag: 'Storage');
    
    final cards = await getCards();
    final cardsKey = _getUserKey('cards');
    final cloudData = _prefs.getString(cardsKey);
    
    AppLogger.d('\n📱 Local Data:', tag: 'Storage');
    AppLogger.d('Cards in memory: ${cards.length}', tag: 'Storage');
    AppLogger.d('Cards in cloud storage: ${cloudData != null ? jsonDecode(cloudData).length : 0}', tag: 'Storage');
    
    if (_lastSyncTime != null) {
      final timeSinceSync = DateTime.now().difference(_lastSyncTime!);
      AppLogger.d('\n⏱️ Time since last sync:', tag: 'Storage');
      AppLogger.d('${timeSinceSync.inMinutes} minutes ago', tag: 'Storage');
    }
    
    AppLogger.d('\n🔄 Recent Changes:', tag: 'Storage');
    AppLogger.d('Changes in queue: ${_lastModifiedDates.length}', tag: 'Storage');
    AppLogger.d('Next sync interval: ${_calculateNextSyncInterval().inMinutes} minutes', tag: 'Storage');
  }

  // Add this simple method near your other card management methods
  Future<void> refreshState() async {
    if (_currentUserId == null) {
      debugPrint('Cannot refresh state: No current user ID');
      return;
    }
    
    try {
      final cards = await getCards();
      _cardsController.add(cards);
      _notifyCardChange();
      debugPrint('State refreshed with ${cards.length} cards');
    } catch (e) {
      debugPrint('Error refreshing state: $e');
    }
  }

  /// Gets cards synchronously from local storage without waiting for async operations
  /// Returns cached cards or empty list if none are available
  List<TcgCard> getCardsSync() {
    try {
      // Return the cached cards if available
      if (_cachedCards != null) {
        return _cachedCards!;
      }
      
      // If no cached cards, try to load them synchronously
      return _getCards();
    } catch (e) {
      debugPrint('Error in getCardsSync: $e');
      return [];
    }
  }

  // Get a stream of cards specific to a user
  Stream<List<TcgCard>> watchUserCards(String userId) {
    if (userId.isEmpty) {
      return Stream.value([]);
    }
    
    // In our storage architecture, cards are already filtered by user via the storage keys
    // So we just need to return all cards if this is the current user
    if (userId == _currentUserId) {
      final cards = _getCards();
      // Return a stream that emits the current cards followed by any updates
      return _cardsController.stream.startWith(cards);
    } else {
      // If asking for a different user's cards, we can't access them in this storage model
      LoggingService.debug('Attempted to watch cards for user $userId but current user is $_currentUserId');
      return Stream.value([]);
    }
  }
}
