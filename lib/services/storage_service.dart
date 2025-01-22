import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tcg_card.dart';

class StorageService {
  late final SharedPreferences _prefs;
  static StorageService? _instance;
  final _cardsController = StreamController<List<TcgCard>>.broadcast();
  bool _isInitialized = false;
  String? _currentUserId;

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

  StorageService._();

  static Future<StorageService> init() async {
    if (_instance == null) {
      _instance = StorageService._();
      await _instance!._init();
    }
    return _instance!;
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
    if (!_isInitialized) return;
    await _saveCard(card);
  }

  final Map<String, TcgCard> _removedCards = {};

  Future<void> removeCard(String cardId) async {
    if (!_isInitialized || _currentUserId == null) return;
    
    final List<String> existingCardsJson = _prefs.getStringList(_getUserKey('cards')) ?? [];
    final existingCards = existingCardsJson
        .map((json) => jsonDecode(json) as Map<String, dynamic>)
        .toList();
    
    final removedCardJson = existingCards.firstWhere(
      (card) => card['id'] == cardId,
      orElse: () => {},
    );
    if (removedCardJson.isNotEmpty) {
      _removedCards[cardId] = TcgCard.fromJson(removedCardJson);
    }
    
    existingCards.removeWhere((card) => card['id'] == cardId);
    
    final updatedCardsJson = existingCards
        .map((c) => jsonEncode(c))
        .cast<String>()
        .toList();
    await _prefs.setStringList(_getUserKey('cards'), updatedCardsJson);
    getCards().then((cards) => _cardsController.add(cards));
  }

  Future<void> undoRemoveCard(String cardId) async {
    if (!_isInitialized) return;
    final cardToRestore = _removedCards.remove(cardId);
    if (cardToRestore != null) {
      await saveCard(cardToRestore);
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

  void dispose() {
    _cardsController.close();
  }
}
