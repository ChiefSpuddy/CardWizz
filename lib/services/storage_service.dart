import 'dart:convert';  // Add this for jsonEncode/jsonDecode
import 'dart:async';  // Add this for StreamController
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tcg_card.dart';  // Add this for TcgCard model

class StorageService {
  static late SharedPreferences _prefs;
  
  static Future<StorageService> init() async {
    _prefs = await SharedPreferences.getInstance();
    return StorageService();
  }

  Future<void> savePreference(String key, dynamic value) async {
    if (value is bool) {
      await _prefs.setBool(key, value);
    } else if (value is String) {
      await _prefs.setString(key, value);
    } else if (value is int) {
      await _prefs.setInt(key, value);
    } else if (value is double) {
      await _prefs.setDouble(key, value);
    }
  }

  T? getPreference<T>(String key) {
    return _prefs.get(key) as T?;
  }

  final _cardsController = StreamController<List<TcgCard>>.broadcast();

  Stream<List<TcgCard>> watchCards() {
    // Initial load
    getCards().then((cards) => _cardsController.add(cards));
    return _cardsController.stream;
  }

  Future<void> saveCard(TcgCard card) async {
    final List<String> existingCardsJson = _prefs.getStringList('cards') ?? [];
    final existingCards = existingCardsJson
        .map((json) => jsonDecode(json) as Map<String, dynamic>)
        .toList();
    
    // Check if card already exists
    if (!existingCards.any((c) => c['id'] == card.id)) {
      existingCards.add(card.toJson());
      
      final updatedCardsJson = existingCards
          .map((c) => jsonEncode(c))
          .cast<String>()  // Use cast instead of toList<String>
          .toList();
      
      await _prefs.setStringList('cards', updatedCardsJson);
      // Notify listeners
      getCards().then((cards) => _cardsController.add(cards));
    }
  }

  // Add this method to store removed cards temporarily for undo
  final Map<String, TcgCard> _removedCards = {};

  Future<void> removeCard(String cardId) async {
    final List<String> existingCardsJson = _prefs.getStringList('cards') ?? [];
    final existingCards = existingCardsJson
        .map((json) => jsonDecode(json) as Map<String, dynamic>)
        .toList();
    
    // Store the removed card for potential undo
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
    
    await _prefs.setStringList('cards', updatedCardsJson);
    // Notify listeners
    getCards().then((cards) => _cardsController.add(cards));
  }

  Future<void> undoRemoveCard(String cardId) async {
    final cardToRestore = _removedCards.remove(cardId);
    if (cardToRestore != null) {
      await saveCard(cardToRestore);
    }
  }

  Future<List<TcgCard>> getCards() async {
    final cardsJson = _prefs.getStringList('cards') ?? [];
    return cardsJson
        .map((json) => TcgCard.fromJson(jsonDecode(json)))
        .toList();
  }

  @override
  void dispose() {
    _cardsController.close();
  }
}
