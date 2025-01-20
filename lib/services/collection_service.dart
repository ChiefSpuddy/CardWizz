import 'dart:convert';
import 'package:shared_preferences.dart';
import '../models/tcg_card.dart';
import '../models/custom_collection.dart';

class CollectionService {
  static const String _collectionsKey = 'user_collections';
  static const String _cardsKey = 'collection_cards';
  final SharedPreferences _prefs;

  CollectionService(this._prefs);

  Future<List<TcgCard>> getCollectionCards(String collectionId) async {
    final cardsJson = _prefs.getStringList(_cardsKey) ?? [];
    return cardsJson
        .map((json) => TcgCard.fromJson(jsonDecode(json)))
        .where((card) => true) // TODO: Add collection filtering
        .toList();
  }

  Future<List<CustomCollection>> getCustomCollections() async {
    final collectionsJson = _prefs.getStringList(_collectionsKey) ?? [];
    return collectionsJson
        .map((json) => CustomCollection.fromJson(jsonDecode(json)))
        .toList();
  }

  Future<void> addCardToCollection(TcgCard card, String collectionId) async {
    final cards = await getCollectionCards(collectionId);
    cards.add(card);
    await _saveCards(cards);
  }

  Future<void> _saveCards(List<TcgCard> cards) async {
    final cardsJson = cards
        .map((card) => jsonEncode(card.toJson()))
        .toList();
    await _prefs.setStringList(_cardsKey, cardsJson);
  }
}
