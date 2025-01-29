import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import 'package:flutter/material.dart';  // Add this import for Color
import 'package:shared_preferences/shared_preferences.dart';  // Add this import
import 'package:provider/provider.dart';  // Add this
import '../models/custom_collection.dart';
import '../services/storage_service.dart';  // Add this import
import '../providers/sort_provider.dart';  // Add this

class CollectionService {
  static CollectionService? _instance;
  final Database _db;
  final _collectionsController = StreamController<List<CustomCollection>>.broadcast();
  String? _currentUserId;

  CollectionService._(this._db) {
    _refreshCollections();
  }

  Future<void> setCurrentUser(String? userId) async {
    print('Setting collection service user: $userId');
    _currentUserId = userId;
    
    // If signing out, don't clear collections from database
    if (userId == null) {
      _collectionsController.add([]);
      return;
    }

    // Handle existing collections migration if needed
    final unassignedCollections = await _db.query(
      'collections',
      where: 'user_id IS NULL OR user_id = ""',
    );

    if (unassignedCollections.isNotEmpty) {
      // Migrate existing collections to the current user
      for (final collection in unassignedCollections) {
        await _db.update(
          'collections',
          {'user_id': userId},
          where: 'id = ?',
          whereArgs: [collection['id']],
        );
      }
    }

    // Refresh collections after migration
    await _refreshCollections();
  }

  Future<void> clearUserData() async {
    // Remove this method or modify it to not delete data
    _currentUserId = null;
    _collectionsController.add([]);
  }

  static Future<CollectionService> getInstance() async {
    if (_instance != null) return _instance!;

    // Open database without deleting
    final db = await openDatabase(
      'collections.db',
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE collections(
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            description TEXT,
            created_at INTEGER,
            card_ids TEXT,
            user_id TEXT,
            color INTEGER DEFAULT 4282682873
          )
        ''');
      },
    );

    _instance = CollectionService._(db);
    return _instance!;
  }

  Future<void> _refreshCollections() async {
    if (_currentUserId == null) {
      _collectionsController.add([]);
      return;
    }
    
    try {
      final collections = await getCustomCollections();
      print('Found ${collections.length} collections for user $_currentUserId');
      _collectionsController.add(collections);
    } catch (e) {
      print('Error refreshing collections: $e'); // Add debug print
      _collectionsController.addError(e);
    }
  }

  Stream<List<CustomCollection>> getCustomCollectionsStream() {
    _refreshCollections();
    return _collectionsController.stream;
  }

  Future<List<CustomCollection>> getCustomCollections([CollectionSortOption? sortOption]) async {
    if (_currentUserId == null) return [];
    
    final List<Map<String, dynamic>> maps = await _db.query(
      'collections',
      where: 'user_id = ?',
      whereArgs: [_currentUserId],
    );
    
    final collections = maps.map((map) => CustomCollection(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String? ?? '',
      cardIds: map['card_ids'].toString().split(',').where((id) => id.isNotEmpty).toList(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      color: Color(map['color'] as int? ?? 0xFF90CAF9),  // Add color here
    )).toList();

    // Add value calculation
    final enrichedCollections = await Future.wait(
      collections.map((collection) async {
        final value = await calculateCollectionValue(collection.id);
        return collection.copyWith(totalValue: value);
      }),
    );

    // Use provided sort option or default to newest
    return sortCollections(enrichedCollections, sortOption ?? CollectionSortOption.newest);
  }

  List<CustomCollection> sortCollections(
    List<CustomCollection> collections,
    CollectionSortOption sortOption,
  ) {
    switch (sortOption) {
      case CollectionSortOption.nameAZ:
        return collections..sort((a, b) => a.name.compareTo(b.name));
      case CollectionSortOption.nameZA:
        return collections..sort((a, b) => b.name.compareTo(a.name));
      case CollectionSortOption.valueHighLow:
        return collections..sort((a, b) => 
          (b.totalValue ?? 0).compareTo(a.totalValue ?? 0));
      case CollectionSortOption.valueLowHigh:
        return collections..sort((a, b) => 
          (a.totalValue ?? 0).compareTo(b.totalValue ?? 0));
      case CollectionSortOption.newest:
        return collections..sort((a, b) => 
          b.createdAt.compareTo(a.createdAt));
      case CollectionSortOption.oldest:
        return collections..sort((a, b) => 
          a.createdAt.compareTo(b.createdAt));
      case CollectionSortOption.countHighLow:
        return collections..sort((a, b) => 
          b.cardIds.length.compareTo(a.cardIds.length));
      case CollectionSortOption.countLowHigh:
        return collections..sort((a, b) => 
          a.cardIds.length.compareTo(b.cardIds.length));
    }
  }

  Future<CustomCollection?> getCollection(String id) async {
    if (_currentUserId == null) return null;
    
    final List<Map<String, dynamic>> maps = await _db.query(
      'collections',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, _currentUserId],
      limit: 1,
    );
    
    if (maps.isEmpty) return null;
    
    final map = maps.first;
    return CustomCollection(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String? ?? '',
      cardIds: map['card_ids'].toString().split(',').where((id) => id.isNotEmpty).toList(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      color: Color(map['color'] as int? ?? 0xFF90CAF9),
    );
  }

  Future<void> createCustomCollection(
    String name,
    String description, {
    Color color = const Color(0xFF90CAF9),  // Add default color parameter
  }) async {
    if (_currentUserId == null) return;

    await _db.insert('collections', {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'name': name,
      'description': description,
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'card_ids': '',
      'user_id': _currentUserId,
      'color': color.value,  // Make sure color value is stored
    });

    await _refreshCollections();
  }

  Future<void> updateCollectionDetails(
    String collectionId, 
    String name, 
    String description, {
    Color? color,
  }) async {
    if (_currentUserId == null) return;
    
    final Map<String, dynamic> updates = {
      'name': name,
      'description': description,
    };

    if (color != null) {
      updates['color'] = color.value;  // Make sure color value is stored
    }
    
    await _db.update(
      'collections',
      updates,
      where: 'id = ? AND user_id = ?',
      whereArgs: [collectionId, _currentUserId],
    );
    await _refreshCollections();
  }

  Future<void> updateCollectionColor(String collectionId, Color color) async {
    if (_currentUserId == null) return;
    
    await _db.update(
      'collections',
      {'color': color.value},
      where: 'id = ? AND user_id = ?',
      whereArgs: [collectionId, _currentUserId],
    );
    await _refreshCollections();
  }

  Future<void> deleteCollection(String collectionId) async {
    await _db.delete(
      'collections',
      where: 'id = ? AND user_id = ?',
      whereArgs: [collectionId, _currentUserId],
    );
    await _refreshCollections();
  }

  Future<void> addCardToCollection(String collectionId, String cardId) async {
    if (_currentUserId == null) return;
    
    final collection = await getCollection(collectionId);
    if (collection != null) {
      final updatedCardIds = [...collection.cardIds, cardId];
      await _db.update(
        'collections',
        {'card_ids': updatedCardIds.join(',')},
        where: 'id = ? AND user_id = ?',
        whereArgs: [collectionId, _currentUserId],
      );
      await _refreshCollections();
    }
  }

  Future<void> removeCardFromCollection(String collectionId, String cardId) async {
    if (_currentUserId == null) return;
    
    final collection = await getCollection(collectionId);
    if (collection != null) {
      final cardIds = collection.cardIds.where((id) => id != cardId).toList();
      await _db.update(
        'collections',
        {'card_ids': cardIds.join(',')},
        where: 'id = ? AND user_id = ?',
        whereArgs: [collectionId, _currentUserId],
      );
      await _refreshCollections();
    }
  }

  Future<double> calculateCollectionValue(String collectionId) async {
    final collection = await getCollection(collectionId);
    if (collection == null) return 0.0;
    
    final storage = await StorageService.init();
    final cards = await storage.getCards();
    
    double total = 0.0;
    for (final card in cards) {
      if (collection.cardIds.contains(card.id)) {
        total += card.price ?? 0.0;
      }
    }
    return total;
  }

  Future<void> deleteUserData(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    // Remove all collection data for the user
    await prefs.remove('${userId}_collections');
    await prefs.remove('${userId}_binders');
    await prefs.remove('${userId}_cards');
    // Add any other user-specific data that needs to be removed
  }

  void dispose() {
    _collectionsController.close();
  }
}
