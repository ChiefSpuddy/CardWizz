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
  final String? setName;
  final String? rarity;
  
  // Price fields
  double? price; // Primary price used for display and sorting
  double? ebayPrice; // eBay-specific price
  double? previousPrice; // Previous recorded price for change calculation
  final Map<String, dynamic>? cardmarket; // Raw cardmarket data
  final Map<String, dynamic>? rawData; // Complete raw data
  final String? priceSource; // Track where the price came from
  final Map<String, double>? altPrices; // Alternate price sources
  
  // Collection tracking fields
  final DateTime? dateAdded; // When the card was first added to collection
  final DateTime? addedToCollection; // Same as dateAdded but explicitly named
  final DateTime? lastPriceUpdate; // When price was last updated
  final DateTime? lastPriceChange; // When price last changed
  final int? setTotal; // Total cards in the set
  
  // History tracking
  final List<PriceHistoryEntry> priceHistory; // Historical price entries
  
  // Type tracking
  final bool? isMtg;

  TcgCard({
    required this.id,
    required this.name,
    this.number,
    this.imageUrl,
    this.largeImageUrl,
    required this.set,
    this.rarity,
    this.setName,
    this.price,
    this.cardmarket,
    this.rawData,
    this.priceSource,
    this.altPrices,
    this.isMtg,
    this.dateAdded,
    this.addedToCollection,
    this.lastPriceUpdate,
    this.lastPriceChange,
    this.previousPrice,
    this.ebayPrice,
    this.setTotal,
    List<PriceHistoryEntry>? priceHistory,
  }) : this.priceHistory = priceHistory ?? [];

  // Helper method to get price from a specific source
  double? getPriceFromSource(String source) {
    if (source == priceSource) {
      return price;
    }
    return altPrices?[source];
  }

  // Get the API price specifically for sorting
  double? get apiPrice {
    if (cardmarket != null && cardmarket!['prices'] != null) {
      return cardmarket!['prices']['averageSellPrice'] as double?;
    }
    return null;
  }

  // Method to calculate price change over a specified duration
  double? getPriceChange(Duration period) {
    if (priceHistory.isEmpty || price == null) return null;

    // Sort history by timestamp to ensure order
    final sortedHistory = List<PriceHistoryEntry>.from(priceHistory)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    if (sortedHistory.isEmpty) return null;
    
    // Find oldest entry within the period
    final cutoffDate = DateTime.now().subtract(period);
    final oldestRelevantEntry = sortedHistory
        .lastWhere(
          (entry) => entry.timestamp.isAfter(cutoffDate),
          orElse: () => sortedHistory.first,
        );
    
    if (oldestRelevantEntry.price <= 0) return null;
    
    // Calculate percentage change
    return ((price! - oldestRelevantEntry.price) / oldestRelevantEntry.price) * 100;
  }

  // Get the period descriptor for price change
  String? getPriceChangePeriod() {
    if (priceHistory.isEmpty || price == null) return null;
    
    if (getPriceChange(const Duration(days: 1)) != null) {
      return '24 Hours';
    } else if (getPriceChange(const Duration(days: 7)) != null) {
      return '7 Days';
    } else if (getPriceChange(const Duration(days: 30)) != null) {
      return '30 Days';
    } else {
      return 'All Time';
    }
  }

  // Create a copy with updated fields
  TcgCard copyWith({
    String? id,
    String? name,
    String? number,
    String? imageUrl,
    String? largeImageUrl,
    TcgSet? set,
    String? rarity,
    String? setName,
    double? price,
    Map<String, dynamic>? cardmarket,
    Map<String, dynamic>? rawData,
    String? priceSource,
    Map<String, double>? altPrices,
    bool? isMtg,
    DateTime? dateAdded,
    DateTime? addedToCollection,
    DateTime? lastPriceUpdate,
    DateTime? lastPriceChange,
    double? previousPrice,
    double? ebayPrice,
    int? setTotal,
    List<PriceHistoryEntry>? priceHistory,
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
      price: price ?? this.price,
      cardmarket: cardmarket ?? this.cardmarket,
      rawData: rawData ?? this.rawData,
      priceSource: priceSource ?? this.priceSource,
      altPrices: altPrices ?? this.altPrices,
      isMtg: isMtg ?? this.isMtg,
      dateAdded: dateAdded ?? this.dateAdded,
      addedToCollection: addedToCollection ?? this.addedToCollection,
      lastPriceUpdate: lastPriceUpdate ?? this.lastPriceUpdate,
      lastPriceChange: lastPriceChange ?? this.lastPriceChange,
      previousPrice: previousPrice ?? this.previousPrice,
      ebayPrice: ebayPrice ?? this.ebayPrice,
      setTotal: setTotal ?? this.setTotal,
      priceHistory: priceHistory ?? List<PriceHistoryEntry>.from(this.priceHistory),
    );
  }

  // Method to get the specific price to use for API sorting
  double getPriceSortValue() {
    // Always use the API price for sorting if available
    return apiPrice ?? price ?? 0.0;
  }

  // Add a price history point and return a new card instance
  // This keeps the immutable pattern by returning a new card rather than modifying this one
  TcgCard addPriceHistoryPoint(double price, DateTime timestamp, {String? source}) {
    // Create a copy of the price history to avoid modifying the original
    final updatedHistory = List<PriceHistoryEntry>.from(priceHistory);
    
    // Add the new price point
    updatedHistory.add(PriceHistoryEntry(
      timestamp: timestamp,
      price: price,
      source: source ?? priceSource,
    ));
    
    // Return a new card with the updated history
    return copyWith(
      priceHistory: updatedHistory,
    );
  }

  // Instead of setters, provide methods to update specific fields
  TcgCard withLastPriceUpdate(DateTime timestamp) {
    return copyWith(lastPriceUpdate: timestamp);
  }

  TcgCard withLastPriceChange(DateTime timestamp) {
    return copyWith(lastPriceChange: timestamp);
  }

  TcgCard withPreviousPrice(double? previousPrice) {
    return copyWith(previousPrice: previousPrice);
  }

  // Convert card to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'number': number,
      'imageUrl': imageUrl,
      'largeImageUrl': largeImageUrl,
      'set': {
        'id': set.id,
        'name': set.name,
        'symbol': set.symbol,
        'releaseDate': set.releaseDate,
        'printedTotal': set.printedTotal,
        'total': set.total,
      },
      'rarity': rarity,
      'setName': setName,
      'price': price,
      'ebayPrice': ebayPrice,
      'previousPrice': previousPrice,
      'cardmarket': cardmarket,
      'rawData': rawData,
      'priceSource': priceSource,
      'altPrices': altPrices,
      'isMtg': isMtg,
      'dateAdded': dateAdded?.toIso8601String(),
      'addedToCollection': addedToCollection?.toIso8601String(),
      'lastPriceUpdate': lastPriceUpdate?.toIso8601String(),
      'lastPriceChange': lastPriceChange?.toIso8601String(),
      'setTotal': setTotal,
      'priceHistory': priceHistory.map((entry) => entry.toJson()).toList(),
    };
  }

  // Factory method from JSON with enhanced price handling
  factory TcgCard.fromJson(Map<String, dynamic> json) {
    // Extract the primary API price
    double? apiPrice;
    Map<String, double> priceSources = {};
    
    if (json['cardmarket'] != null && json['cardmarket']['prices'] != null) {
      final prices = json['cardmarket']['prices'];
      apiPrice = _parseDouble(prices['averageSellPrice']);
      
      // Store all available price sources
      if (prices['averageSellPrice'] != null) {
        priceSources['cardmarket'] = _parseDouble(prices['averageSellPrice']) ?? 0.0;
      }
      if (prices['trendPrice'] != null) {
        priceSources['trend'] = _parseDouble(prices['trendPrice']) ?? 0.0;
      }
      if (prices['lowPrice'] != null) {
        priceSources['low'] = _parseDouble(prices['lowPrice']) ?? 0.0;
      }
    }

    // Parse the price history entries if available
    List<PriceHistoryEntry>? priceHistory;
    if (json['priceHistory'] != null) {
      priceHistory = (json['priceHistory'] as List)
          .map((entry) => PriceHistoryEntry.fromJson(entry))
          .toList();
    }

    // Extract set information
    Map<String, dynamic> setData = json['set'] ?? {};
    
    // Create the set object
    final TcgSet cardSet = TcgSet(
      id: setData['id'] ?? json['setId'] ?? '',
      name: setData['name'] ?? json['setName'] ?? '',
      symbol: setData['symbol'],
      releaseDate: setData['releaseDate'],
      printedTotal: setData['printedTotal'],
      total: setData['total'],
    );
    
    return TcgCard(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      number: json['number']?.toString(),
      imageUrl: json['imageUrl'] ?? json['images']?['small'],
      largeImageUrl: json['largeImageUrl'] ?? json['images']?['large'],
      set: cardSet,
      rarity: json['rarity'],
      setName: json['setName'] ?? setData['name'],
      price: json['price'] != null ? _parseDouble(json['price']) : apiPrice,
      ebayPrice: json['ebayPrice'] != null ? _parseDouble(json['ebayPrice']) : null,
      previousPrice: json['previousPrice'] != null ? _parseDouble(json['previousPrice']) : null,
      cardmarket: json['cardmarket'],
      rawData: json['rawData'],
      priceSource: json['priceSource'] ?? 'cardmarket',
      altPrices: priceSources,
      isMtg: json['isMtg'] ?? false,
      dateAdded: json['dateAdded'] != null ? DateTime.parse(json['dateAdded']) : null,
      addedToCollection: json['addedToCollection'] != null ? DateTime.parse(json['addedToCollection']) : null,
      lastPriceUpdate: json['lastPriceUpdate'] != null ? DateTime.parse(json['lastPriceUpdate']) : null,
      lastPriceChange: json['lastPriceChange'] != null ? DateTime.parse(json['lastPriceChange']) : null,
      setTotal: json['setTotal'] != null ? int.tryParse(json['setTotal'].toString()) : null,
      priceHistory: priceHistory ?? [],
    );
  }
  
  // Helper method to parse doubles from various formats
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
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
