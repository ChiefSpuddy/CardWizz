import 'package:flutter/foundation.dart';
import './tcg_set.dart';
import './price_history_entry.dart';

class TcgCard {
  final String id;
  final String name;
  final String? number;
  final String? imageUrl;
  final String? largeImageUrl;
  final TcgSet set;
  final String? rarity;
  final String? setName;
  final List<String>? types;
  final List<String>? subtypes;
  final String? artist;
  final Map<String, dynamic>? cardmarket;
  final double? price;
  final double? ebayPrice; // Add ebayPrice field
  final Map<String, dynamic>? rawData;
  final DateTime? dateAdded;
  final DateTime? addedToCollection;
  final List<PriceHistoryEntry> priceHistory;
  final bool? isMtg;
  final int? setTotal;  // Add this property

  // These fields are mutable and updated after construction
  double? previousPrice;
  DateTime? lastPriceChange;
  DateTime? lastPriceUpdate;

  TcgCard({
    required this.id,
    required this.name,
    this.number,
    this.imageUrl,
    this.largeImageUrl,
    required this.set,
    this.rarity,
    this.setName,
    this.types,
    this.subtypes,
    this.artist,
    this.cardmarket,
    this.price,
    this.ebayPrice, // Add ebayPrice parameter
    this.rawData,
    this.dateAdded,
    this.addedToCollection,
    List<PriceHistoryEntry>? priceHistory,
    this.isMtg,
    this.setTotal,
  }) : this.priceHistory = priceHistory ?? [];

  // Crucial method to ensure price data is properly extracted during serialization
  factory TcgCard.fromJson(Map<String, dynamic> json) {
    // Make sure we extract image URLs from both direct fields and nested 'images' object
    String? imageUrl = json['imageUrl'];
    String? largeImageUrl = json['largeImageUrl'];
    
    // If we don't have URLs but have images data, extract from there
    if ((imageUrl == null || largeImageUrl == null) && 
        json['images'] != null && json['images'] is Map) {
      final images = json['images'] as Map<String, dynamic>;
      imageUrl ??= images['small'] as String?;
      largeImageUrl ??= images['large'] as String?;
    }

    // Fix URLs that start with //
    if (imageUrl != null && imageUrl.startsWith('//')) {
      imageUrl = 'https:$imageUrl';
    }
    if (largeImageUrl != null && largeImageUrl.startsWith('//')) {
      largeImageUrl = 'https:$largeImageUrl';
    }
    
    // Extract and handle price information correctly
    double? price;
    
    // First try direct price field
    if (json['price'] != null) {
      price = (json['price'] as num).toDouble();
    } 
    // Then try cardmarket.prices.averageSellPrice for Pokemon cards
    else if (json['cardmarket'] != null && 
             json['cardmarket']['prices'] != null && 
             json['cardmarket']['prices']['averageSellPrice'] != null) {
      price = (json['cardmarket']['prices']['averageSellPrice'] as num).toDouble();
    }
    // For MTG cards, look in usd field (scryfall format)
    else if (json['prices'] != null && json['prices']['usd'] != null) {
      final priceStr = json['prices']['usd'] as String?;
      price = priceStr != null ? double.tryParse(priceStr) : null;
    }
    // Also check raw data for price info
    else if (json['rawData'] != null) {
      var rawData = json['rawData'] as Map<String, dynamic>;
      if (rawData['cardmarket'] != null && 
          rawData['cardmarket']['prices'] != null && 
          rawData['cardmarket']['prices']['averageSellPrice'] != null) {
        price = (rawData['cardmarket']['prices']['averageSellPrice'] as num).toDouble();
      }
      else if (rawData['prices'] != null && rawData['prices']['usd'] != null) {
        final priceStr = rawData['prices']['usd'] as String?;
        price = priceStr != null ? double.tryParse(priceStr) : null;
      }
    }
    
    // Set up price history
    final List<PriceHistoryEntry> priceHistory = [];
    if (json['priceHistory'] != null) {
      priceHistory.addAll((json['priceHistory'] as List)
          .map((e) => PriceHistoryEntry.fromJson(e))
          .toList());
    }
    
    // Add a price history entry if we have a price but no history
    if (price != null && price > 0 && priceHistory.isEmpty) {
      priceHistory.add(PriceHistoryEntry(
        price: price,
        timestamp: json['dateAdded'] != null 
            ? DateTime.parse(json['dateAdded']) 
            : DateTime.now(),
      ));
    }

    final setData = json['set'] ?? {};
    
    return TcgCard(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      number: json['number']?.toString(),
      imageUrl: imageUrl,
      largeImageUrl: largeImageUrl,
      set: TcgSet.fromJson(setData is Map<String, dynamic> ? setData : {}),
      rarity: json['rarity'],
      setName: json['setName'] ?? json['set']?['name'],
      types: json['types'] != null 
          ? List<String>.from(json['types'])
          : null,
      subtypes: json['subtypes'] != null
          ? List<String>.from(json['subtypes'])
          : null,
      artist: json['artist'],
      cardmarket: json['cardmarket'],
      price: price, // Use the extracted price
      ebayPrice: _extractEbayPrice(json), // Add ebayPrice extraction
      rawData: json['rawData'] ?? json, // Store the raw data for future use
      dateAdded: json['dateAdded'] != null
          ? DateTime.parse(json['dateAdded']) 
          : null,
      addedToCollection: json['addedToCollection'] != null
          ? DateTime.parse(json['addedToCollection'])
          : null,
      priceHistory: priceHistory,
      isMtg: json['isMtg'] ?? false,
      setTotal: json['setTotal'] ?? json['set']?['total'],
    );
  }

  // Add helper method to extract eBay price
  static double? _extractEbayPrice(Map<String, dynamic> json) {
    // Try to extract from ebayPrice field
    if (json['ebayPrice'] != null) {
      final price = json['ebayPrice'];
      if (price is double) return price;
      if (price is int) return price.toDouble();
      if (price is String) return double.tryParse(price);
    }
    
    // Try to extract from ebay.price field if it exists
    if (json['ebay']?['price'] != null) {
      final price = json['ebay']['price'];
      if (price is double) return price;
      if (price is int) return price.toDouble();
      if (price is String) return double.tryParse(price);
    }
    
    return null;
  }

  // The rest of the methods remain unchanged
  double? getPriceChange(Duration period) {
    if (priceHistory.isEmpty) return null;

    final sortedHistory = List<PriceHistoryEntry>.from(priceHistory)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (sortedHistory.length < 2) return null;

    final now = DateTime.now();
    final cutoffDate = now.subtract(period);

    final oldEntry = sortedHistory.firstWhere(
      (entry) => entry.timestamp.isAfter(cutoffDate),
      orElse: () => sortedHistory.first,
    );

    final newEntry = sortedHistory.last;

    if (oldEntry.price == 0) return null;
    return ((newEntry.price - oldEntry.price) / oldEntry.price) * 100;
  }

  String? getPriceChangePeriod() {
    if (lastPriceChange == null) return null;

    final now = DateTime.now();
    final difference = now.difference(lastPriceChange!);

    if (difference.inHours < 24) {
      return 'Today';
    } else if (difference.inDays < 7) {
      return 'This week';
    } else if (difference.inDays < 30) {
      return 'This month';
    } else {
      return 'Older';
    }
  }

  // Make sure we properly save the price data
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'number': number,
      'imageUrl': imageUrl,
      'largeImageUrl': largeImageUrl,
      'set': set.toJson(),
      'rarity': rarity,
      'setName': setName,
      'types': types,
      'subtypes': subtypes,
      'artist': artist,
      'cardmarket': cardmarket,
      'price': price,
      'ebayPrice': ebayPrice, // Include ebayPrice
      'rawData': rawData,
      'dateAdded': dateAdded?.toIso8601String(),
      'addedToCollection': addedToCollection?.toIso8601String(),
      'priceHistory': priceHistory.map((e) => e.toJson()).toList(),
      'isMtg': isMtg ?? false,
      'setTotal': setTotal ?? set.total,
    };
  }

  // Add this method for convenience
  void addPriceHistoryPoint(double price, DateTime timestamp) {
    priceHistory.add(PriceHistoryEntry(
      price: price,
      timestamp: timestamp,
    ));
  }

  // Make sure we properly copy all fields including image URLs
  TcgCard copyWith({
    String? id,
    String? name,
    String? number,
    String? imageUrl,
    String? largeImageUrl,
    TcgSet? set,
    String? rarity,
    String? setName,
    List<String>? types,
    List<String>? subtypes,
    String? artist,
    Map<String, dynamic>? cardmarket,
    double? price,
    double? ebayPrice, // Add ebayPrice parameter
    Map<String, dynamic>? rawData,
    DateTime? dateAdded,
    DateTime? addedToCollection,
    List<PriceHistoryEntry>? priceHistory,
    DateTime? lastPriceUpdate,
    double? previousPrice,
    DateTime? lastPriceChange,
    bool? isMtg,
    int? setTotal,
  }) {
    return TcgCard(
      id: id ?? this.id,
      name: name ?? this.name,
      number: number ?? this.number,
      imageUrl: imageUrl ?? this.imageUrl,
      largeImageUrl: largeImageUrl ?? this.largeImageUrl,
      set: set ?? this.set,
      rarity: rarity ?? this.rarity,
      setName: setName ?? this.setName,
      types: types ?? this.types,
      subtypes: subtypes ?? this.subtypes,
      artist: artist ?? this.artist,
      cardmarket: cardmarket ?? this.cardmarket,
      price: price ?? this.price,
      ebayPrice: ebayPrice ?? this.ebayPrice, // Include ebayPrice
      rawData: rawData ?? this.rawData,
      dateAdded: dateAdded ?? this.dateAdded,
      addedToCollection: addedToCollection ?? this.addedToCollection,
      priceHistory: priceHistory ?? List.from(this.priceHistory),
      isMtg: isMtg ?? this.isMtg,
      setTotal: setTotal ?? this.setTotal,
    )
      ..lastPriceUpdate = lastPriceUpdate ?? this.lastPriceUpdate
      ..previousPrice = previousPrice ?? this.previousPrice
      ..lastPriceChange = lastPriceChange ?? this.lastPriceChange;
  }
}

class TcgCardCollection {
  final String id;
  final String name;
  final List<TcgCard> cards;
  final DateTime createdAt;
  final DateTime updatedAt;

  TcgCardCollection({
    required this.id,
    required this.name,
    required this.cards,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TcgCardCollection.fromJson(Map<String, dynamic> json) {
    return TcgCardCollection(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unnamed Collection',
      cards: (json['cards'] as List?)
              ?.map((cardJson) => TcgCard.fromJson(cardJson))
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'cards': cards.map((card) => card.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  TcgCardCollection copyWith({
    String? id,
    String? name,
    List<TcgCard>? cards,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TcgCardCollection(
      id: id ?? this.id,
      name: name ?? this.name,
      cards: cards ?? this.cards,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
