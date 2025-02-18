import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';  // Add this for ValueNotifier
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../models/tcg_card.dart';
import 'package:collection/collection.dart';
import '../services/purchase_service.dart';
import '../services/tcg_api_service.dart';
import 'package:rxdart/rxdart.dart'; // Add this import
import 'package:path/path.dart' show join;
import 'package:sqflite/sqflite.dart' show Database, openDatabase, getDatabasesPath;
import '../services/background_price_update_service.dart';  // Add this import

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

  void setCurrentUser(String? userId) {
    print('Setting current user: $userId');
    _currentUserId = userId;
    
    if (userId == null) {
      // Just clear in-memory state
      clearSessionState();
      return;
    }
    
    // Load the user's data
    Future.delayed(const Duration(milliseconds: 100), () async {
      await _loadSyncState(); // Add this
      _loadInitialData();
      final cards = _getCards();
      print('Loading cards with key: ${_getUserKey('cards')}');
      _cardsController.add(cards);
    });
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
      
      print('Permanently deleted all data for user: $userId');
      
    } catch (e) {
      print('Error deleting user data: $e');
      rethrow;
    }
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

  // Make saveCard public method async
  Future<void> saveCard(TcgCard card) async {
    if (_currentUserId == null) return;

    try {
      final now = DateTime.now();
      final cardWithDate = card.copyWith(
        dateAdded: card.dateAdded ?? now,
        addedToCollection: card.addedToCollection ?? now,
        price: card.price,
        priceHistory: card.priceHistory.isEmpty && card.price != null ? 
          [PriceHistoryEntry(price: card.price!, timestamp: now)] : 
          card.priceHistory,
      );

      final cardsKey = _getUserKey('cards');
      final existingCardsJson = _prefs.getStringList(cardsKey) ?? [];
      final existingCards = existingCardsJson
          .map((json) => jsonDecode(json))
          .whereType<Map<String, dynamic>>()
          .map((data) => TcgCard.fromJson(data))
          .toList();

      // Remove any existing versions of this card
      existingCards.removeWhere((c) => c.id == card.id);
      existingCards.add(cardWithDate);

      // Calculate and save new portfolio value
      final totalValue = existingCards.fold<double>(
        0, 
        (sum, card) => sum + (card.price ?? 0)
      );
      await savePortfolioValue(totalValue);

      final updatedCardsJson = existingCards
          .map((c) => jsonEncode(c.toJson()))
          .toList();

      await _prefs.setStringList(cardsKey, updatedCardsJson);
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
      final remainingCards = cards.where((card) => card.id != cardId).toList();
      
      // Calculate new total value after removal
      final totalValue = remainingCards.fold<double>(
        0, 
        (sum, card) => sum + (card.price ?? 0)
      );

      // Save the portfolio value point
      await _savePortfolioValuePoint(totalValue, DateTime.now());

      final cardsKey = _getUserKey('cards');
      final updatedCardsJson = remainingCards
          .map((card) => jsonEncode(card.toJson()))
          .toList();

      await _prefs.setStringList(cardsKey, updatedCardsJson);
      
      // Update the stream and notify listeners
      final updatedCards = await getCards();
      _cardsController.add(updatedCards);
      
      // Make sure to notify card changes
      _notifyCardChange();
      
      // Recalculate portfolio history
      await recalculatePortfolioHistory();

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
    _syncTimer?.cancel();
    _isReadyNotifier.dispose();  // Add this
    _cardsController.close();
    _cardChangeController.close();
    _priceUpdateController.close();
    _priceUpdateCompleteController.close();
    _syncStatusController.close();
    _syncProgressController.close();
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
        
        final cardsKey = _getUserKey('cards');
        final updatedCardsJson = cards
            .map((c) => jsonEncode(c.toJson()))
            .toList();
         
        await _prefs.setStringList(cardsKey, updatedCardsJson);
        _cardsController.add(cards);
      }
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
      print('Error adding price history point: $e');
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
          final updatedCard = existingCard.copyWith(
            price: newPrice,
            lastPriceUpdate: now,
            priceHistory: [
              ...existingCard.priceHistory,
              PriceHistoryEntry(price: newPrice, timestamp: now),
            ],
          );
          
          cards[index] = updatedCard;
          
          // Save updated cards and portfolio value
          final cardsKey = _getUserKey('cards');
          final updatedCardsJson = cards.map((c) => jsonEncode(c.toJson())).toList();
          await _prefs.setStringList(cardsKey, updatedCardsJson);
          
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
      print('Error updating card price: $e');
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
      print('Saved new portfolio value point: $value at ${now.toIso8601String()}');
      _notifyCardChange();  // Make sure to notify listeners
    } catch (e) {
      print('Error saving portfolio value: $e');
    }
  }

  BackgroundPriceUpdateService? backgroundService;

  Future<void> initializeBackgroundService() async {
    if (backgroundService != null) return; // Already initialized
    
    try {
      final apiService = TcgApiService();
      backgroundService = BackgroundPriceUpdateService(this);
      await backgroundService!.initialize();  // Initialize after creation
      print('Background service initialized successfully');
    } catch (e) {
      print('Error initializing background service: $e');
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
      print('Error saving portfolio value point: $e');
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
      
      print('Added portfolio value point: \$${value.toStringAsFixed(2)} at ${timestamp.toIso8601String()}');
    } catch (e) {
      print('Error saving portfolio value point: $e');
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
      
      print('Added portfolio value point: \$${value.toStringAsFixed(2)} at ${timestamp.toIso8601String()}');
    } catch (e) {
      print('Error saving portfolio value point: $e');
    }
  }

  static const Duration _syncInterval = Duration(minutes: 30);
  DateTime? _lastSyncTime;
  bool _isSyncEnabled = false;
  Timer? _syncTimer;
  final _syncStatusController = StreamController<String>.broadcast();
  final _syncProgressController = StreamController<double>.broadcast();

  // Add these getters
  bool get isSyncEnabled => _isSyncEnabled;
  Stream<String> get syncStatus => _syncStatusController.stream;
  Stream<double> get syncProgress => _syncProgressController.stream;

  // Add this method to load saved sync state
  Future<void> _loadSyncState() async {
    if (_currentUserId != null) {
      _isSyncEnabled = _prefs.getBool('${_currentUserId}_sync_enabled') ?? false;
      if (_isSyncEnabled) {
        startSync();
      }
    }
  }

  void startSync() {
    if (_isSyncEnabled) return;
    _isSyncEnabled = true;
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(_syncInterval, (_) => _doSync());
    _syncStatusController.add('Sync enabled');
    if (_currentUserId != null) {
      _prefs.setBool('${_currentUserId}_sync_enabled', true); // Save state
    }
    _doSync(force: true); // Do initial sync
  }

  void stopSync() {
    _isSyncEnabled = false;
    _syncTimer?.cancel();
    _syncTimer = null;
    _syncStatusController.add('Sync disabled');
    if (_currentUserId != null) {
      _prefs.setBool('${_currentUserId}_sync_enabled', false); // Save state
    }
  }

  Future<bool> syncNow() async {
    if (!_isSyncEnabled) return false;
    return _doSync(force: true); // Return the sync result
  }

  // Update the _doSync method to return a completion status
  Future<bool> _doSync({bool force = false}) async {
    if (!_isSyncEnabled || _currentUserId == null) return false;

    try {
      _syncStatusController.add('Syncing...');
      _syncProgressController.add(0.0);

      final now = DateTime.now();
      if (!force && _lastSyncTime != null) {
        final timeSinceLastSync = now.difference(_lastSyncTime!);
        if (timeSinceLastSync < Duration(minutes: 5)) {
          print('🕒 Skipping auto-sync - too soon');
          return false;
        }
      }

      print('🔄 Starting sync...');
      final cards = await getCards();
      
      // TODO: Add actual cloud sync logic here
      await Future.delayed(Duration(milliseconds: 500)); // Simulate work
      
      _syncProgressController.add(1.0);
      print('✅ Sync completed: ${cards.length} cards');
      
      _lastSyncTime = now;
      _syncStatusController.add('Last synced: just now');

      // Notify UI of completion
      _notifyCardChange();
      return true;  // Return success
    } catch (e) {
      print('❌ Sync error: $e');
      _syncStatusController.add('Sync failed: $e');
      return false;  // Return failure
    }
  }
}
