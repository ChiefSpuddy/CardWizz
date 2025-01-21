import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tcg_card.dart';
import '../models/custom_collection.dart';

class CollectionService {
  static const String _collectionsKey = 'custom_collections';
  final _collectionsController = StreamController<List<CustomCollection>>.broadcast();
  static CollectionService? _instance;
  late final SharedPreferences _prefs;

  CollectionService._();

  static Future<CollectionService> getInstance() async {
    if (_instance == null) {
      _instance = CollectionService._();
      _instance!._prefs = await SharedPreferences.getInstance();
      await _instance!._loadCollections();
    }
    return _instance!;
  }

  Stream<List<CustomCollection>> getCustomCollectionsStream() {
    _loadCollections();
    return _collectionsController.stream;
  }

  Future<void> _loadCollections() async {
    final collections = await getCustomCollections();
    _collectionsController.add(collections);
  }

  Future<List<CustomCollection>> getCustomCollections() async {
    final collectionsJson = _prefs.getStringList(_collectionsKey) ?? [];
    return collectionsJson
        .map((json) => CustomCollection.fromJson(jsonDecode(json)))
        .toList();
  }

  Future<void> createCustomCollection(String name, String description) async {
    final collections = await getCustomCollections();
    final newCollection = CustomCollection(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
    );
    collections.add(newCollection);
    await _saveCollections(collections);
  }

  Future<void> updateCollectionDetails(String collectionId, String name, String description) async {
    final collections = await getCustomCollections();
    final index = collections.indexWhere((c) => c.id == collectionId);
    if (index != -1) {
      collections[index] = collections[index].copyWith(
        name: name,
        description: description,
      );
      await _saveCollections(collections);
    }
  }

  Future<void> deleteCollection(String collectionId) async {
    final collections = await getCustomCollections();
    collections.removeWhere((c) => c.id == collectionId);
    await _saveCollections(collections);
  }

  Future<void> addCardToCollection(String collectionId, String cardId) async {
    final collections = await getCustomCollections();
    final index = collections.indexWhere((c) => c.id == collectionId);
    if (index != -1) {
      final cardIds = List<String>.from(collections[index].cardIds);
      if (!cardIds.contains(cardId)) {
        cardIds.add(cardId);
        collections[index] = collections[index].copyWith(cardIds: cardIds);
        await _saveCollections(collections);
      }
    }
  }

  Future<void> removeCardFromCollection(String collectionId, String cardId) async {
    final collections = await getCustomCollections();
    final index = collections.indexWhere((c) => c.id == collectionId);
    if (index != -1) {
      final cardIds = List<String>.from(collections[index].cardIds);
      cardIds.remove(cardId);
      collections[index] = collections[index].copyWith(cardIds: cardIds);
      await _saveCollections(collections);
    }
  }

  Future<void> _saveCollections(List<CustomCollection> collections) async {
    final collectionsJson = collections
        .map((collection) => jsonEncode(collection.toJson()))
        .toList();
    await _prefs.setStringList(_collectionsKey, collectionsJson);
    _collectionsController.add(collections);
  }

  void dispose() {
    _collectionsController.close();
  }
}
