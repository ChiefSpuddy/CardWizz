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
import '../services/purchase_service.dart';
import 'package:flutter/foundation.dart';  // Add this import for kDebugMode

class CollectionService {
  static const int _freeUserBinderLimit = 10;  // Add this constant
  static CollectionService? _instance;
  final Database _db;
  final StorageService _storage;  // Add this
  final _collectionsController = StreamController<List<CustomCollection>>.broadcast();
  String? _currentUserId;
  List<CustomCollection> _collections = [];  // Add this field
  bool _isInitialized = false;  // Add this field
  bool _isRefreshing = false;  // Add this field

  // Update constructor to take both dependencies
  CollectionService._(this._db, this._storage);

  // Single initialization method that others will use
  static Future<CollectionService> getInstance() async {
    if (_instance == null) {
      final purchaseService = PurchaseService();
      await purchaseService.initialize();
      
      final storage = await StorageService.init(purchaseService);
      
      final db = await openDatabase(
        'collections.db',
        version: 2,  // Increase version number from 1 to 2
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
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            // Check if color column exists before adding it
            var tableInfo = await db.rawQuery('PRAGMA table_info(collections)');
            bool hasColorColumn = tableInfo.any((column) => column['name'] == 'color');
            
            if (!hasColorColumn) {
              await db.execute('''
                ALTER TABLE collections 
                ADD COLUMN color INTEGER DEFAULT 4282682873
              ''');
            }
          }
        },
      );

      _instance = CollectionService._(db, storage);
    }
    return _instance!;
  }

  Future<void> initialize() async {
    if (_isInitialized) {
      print('Collection already initialized, skipping');
      return;
    }
    
    try {
      print('Collection service initializing...');
      await _refreshCollections();  // Load initial collections
      _isInitialized = true;
      
      // Use current collections length instead of non-existent _cards
      final collections = await getCustomCollections();
      print('Collection service initialized with ${collections.length} collections');
    } catch (e) {
      print('Error initializing collection service: $e');
      rethrow;
    }
  }

  // This method only clears in-memory state
  Future<void> clearSessionState() async {
    _collections = [];
    _collectionsController.add([]);
    _currentUserId = null;
  }

  Future<void> setCurrentUser(String? userId) async {
    // Add check to prevent duplicate initialization
    if (_currentUserId == userId) {
      print('Collection service: Same user, skipping initialization');
      return;
    }
    
    print('Setting collection service user: $userId');
    _currentUserId = userId;
    
    if (userId == null) {
      await clearSessionState();
      return;
    }

    // Save user ID to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user_id', userId);

    // Load the collections for this user
    await _refreshCollections();
  }

  // Add this method to initialize user on app start
  Future<void> initializeLastUser() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUserId = prefs.getString('current_user_id');
    if (savedUserId != null) {
      await setCurrentUser(savedUserId);
    }
  }

  Future<void> clearUserData() async {
    if (_currentUserId == null) return;
    
    try {
      final userId = _currentUserId;
      _currentUserId = null;

      // Delete all collections for the user from the database
      await _db.delete(
        'collections',
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      // Clear in-memory collections
      _collections = [];
      _collectionsController.add([]);

      print('Cleared all collections for user: $userId');
    } catch (e) {
      print('Error clearing collections: $e');
      rethrow;
    }
  }

  Future<void> _refreshCollections() async {
    // Add guard to prevent multiple simultaneous refreshes
    if (_isRefreshing) return;
    _isRefreshing = true;

    try {
      if (_currentUserId == null) {
        _collectionsController.add([]);
        return;
      }
      
      final collections = await getCustomCollections();
      if (_currentUserId != null) { // Check again in case user changed during await
        _collectionsController.add(collections);
      }
    } catch (e) {
      _collectionsController.addError(e);
    } finally {
      _isRefreshing = false;
    }
  }

  // Add this method to control debug output
  void _debugLog(String message, {bool verbose = false}) {
    if (kDebugMode && !verbose) {
      print(message);
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
    
    final collections = maps.map((map) {
      final cardIdsStr = map['card_ids'] as String?;
      final cardIds = cardIdsStr == null || cardIdsStr.isEmpty 
          ? <String>[]
          : cardIdsStr.split(',').where((id) => id.isNotEmpty).toList();
      
      return CustomCollection(
        id: map['id'] as String,
        name: map['name'] as String,
        description: map['description'] as String? ?? '',
        cardIds: cardIds,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
        color: Color(map['color'] as int? ?? 0xFF90CAF9),
      );
    }).toList();

    // Add value calculation
    final enrichedCollections = await Future.wait(
      collections.map((collection) async {
        final value = await calculateCollectionValue(collection.id);
        return collection.copyWith(totalValue: value);
      }),
    );

    _debugLog('Found ${collections.length} collections', verbose: true);
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
      cardIds: (map['card_ids'] as String?)?.split(',')
          .where((id) => id.isNotEmpty)
          .toList() ?? [],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      color: Color(map['color'] as int? ?? 0xFF90CAF9),
    );
  }

  Future<String> createCustomCollection(  // Change return type to String
    String name,
    String description, {
    Color color = const Color(0xFF90CAF9),
  }) async {
    if (_currentUserId == null) throw 'No user logged in';

    final collections = await getCustomCollections();
    if (!_storage.isPremium && collections.length >= _freeUserBinderLimit) {
      throw 'Free users can only create up to $_freeUserBinderLimit binders. Upgrade to Premium for unlimited binders!';
    }

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    
    await _db.insert('collections', {
      'id': id,
      'name': name,
      'description': description,
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'card_ids': '',
      'user_id': _currentUserId,
      'color': color.value,
    });

    await _refreshCollections();
    return id;  // Return the collection ID
  }

  // Fix return type for binder limit methods
  Future<bool> canCreateMoreBinders() async {
    if (_storage.isPremium) return true;
    final collections = await getCustomCollections();
    return collections.length < _freeUserBinderLimit;
  }

  Future<int> get remainingBinderSlots async {
    if (_storage.isPremium) return -1; // -1 indicates unlimited
    final collections = await getCustomCollections();
    return _freeUserBinderLimit - collections.length;
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
      final currentIds = collection.cardIds;
      if (!currentIds.contains(cardId)) {
        final updatedCardIds = [...currentIds, cardId];
        
        await _db.update(
          'collections',
          {'card_ids': updatedCardIds.join(',')},
          where: 'id = ? AND user_id = ?',
          whereArgs: [collectionId, _currentUserId],
        );
        await _refreshCollections();
      }
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

  // Update calculateCollectionValue to use injected StorageService
  Future<double> calculateCollectionValue(String collectionId) async {
    final collection = await getCollection(collectionId);
    if (collection == null) return 0.0;
    
    final cards = await _storage.getCards();
    
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

  // Only used during account deletion
  Future<void> permanentlyDeleteUserData(String userId) async {
    try {
      // Actually delete from database
      await _db.delete(
        'collections',
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      await clearSessionState();
      
      print('Permanently deleted all collections for user: $userId');
    } catch (e) {
      print('Error deleting collections: $e');
      rethrow;
    }
  }

  void dispose() {
    _collectionsController.close();
  }
}
