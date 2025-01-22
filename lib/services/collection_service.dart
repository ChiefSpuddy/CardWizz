import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../models/custom_collection.dart';

class CollectionService {
  static CollectionService? _instance;
  final Database _db;
  final _collectionsController = StreamController<List<CustomCollection>>.broadcast();
  String? _currentUserId;

  CollectionService._(this._db) {
    _refreshCollections();
  }

  void setCurrentUser(String? userId) {
    _currentUserId = userId;
    _refreshCollections();
  }

  Future<void> clearUserData() async {
    if (_currentUserId != null) {
      await _db.delete(
        'collections',
        where: 'user_id = ?',
        whereArgs: [_currentUserId],
      );
      await _refreshCollections();
    }
    _currentUserId = null;
  }

  static Future<CollectionService> getInstance() async {
    if (_instance != null) return _instance!;

    final db = await openDatabase(
      'collections.db',
      version: 2, // Increment version
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE collections(
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            description TEXT,
            created_at INTEGER,
            card_ids TEXT,
            user_id TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE collections ADD COLUMN user_id TEXT');
        }
      },
    );

    _instance = CollectionService._(db);
    return _instance!;
  }

  Future<void> _refreshCollections() async {
    final collections = await getCustomCollections();
    _collectionsController.add(collections);
  }

  Stream<List<CustomCollection>> getCustomCollectionsStream() {
    _refreshCollections();
    return _collectionsController.stream;
  }

  Future<List<CustomCollection>> getCustomCollections() async {
    if (_currentUserId == null) return [];
    
    final List<Map<String, dynamic>> maps = await _db.query(
      'collections',
      where: 'user_id = ?',
      whereArgs: [_currentUserId],
    );
    
    return maps.map((map) => CustomCollection(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String? ?? '',
      cardIds: map['card_ids'].toString().split(',').where((id) => id.isNotEmpty).toList(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    )).toList();
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
    
    return CustomCollection(
      id: maps.first['id'] as String,
      name: maps.first['name'] as String,
      description: maps.first['description'] as String? ?? '',
      cardIds: maps.first['card_ids'].toString().split(',').where((id) => id.isNotEmpty).toList(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(maps.first['created_at'] as int),
    );
  }

  Future<void> createCustomCollection(String name, String description) async {
    if (_currentUserId == null) return;

    final collection = CustomCollection(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
      cardIds: [],
      createdAt: DateTime.now(),
    );

    await _db.insert('collections', {
      'id': collection.id,
      'name': name,
      'description': description,
      'created_at': collection.createdAt.millisecondsSinceEpoch,
      'card_ids': '',
      'user_id': _currentUserId,
    });

    await _refreshCollections();
  }

  Future<void> updateCollectionDetails(String collectionId, String name, String description) async {
    if (_currentUserId == null) return;
    
    await _db.update(
      'collections',
      {
        'name': name,
        'description': description,
      },
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

  void dispose() {
    _collectionsController.close();
  }
}
