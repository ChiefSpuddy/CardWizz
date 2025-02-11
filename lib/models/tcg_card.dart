import 'package:intl/intl.dart';
import 'dart:math';

class TcgCard {
  final String id;
  final String name;
  final String number;
  final String imageUrl;
  final String? rarity;
  final String? setName;
  double? _price;
  final List<PriceHistoryEntry> priceHistory;
  final SetInfo? set;
  final String? setTotal;
  final DateTime? lastPriceUpdate;
  final DateTime? lastPriceCheck;
  final DateTime? addedToCollection;  // Make nullable

  TcgCard({
    required this.id,
    required this.name,
    required this.number,
    required this.imageUrl,
    this.rarity,
    this.setName,
    double? price,
    List<PriceHistoryEntry>? priceHistory,
    this.set,
    this.setTotal,
    this.lastPriceUpdate,
    this.lastPriceCheck,
    DateTime? addedToCollection,
  }) : _price = price,
       priceHistory = priceHistory ?? [],
       addedToCollection = addedToCollection ?? DateTime.now();  // Set default value

  double? get price => _price;

  set price(double? newPrice) {
    if (newPrice != _price) {
      _price = newPrice;
      if (newPrice != null) {
        priceHistory.add(PriceHistoryEntry(
          price: newPrice,
          date: DateTime.now(),
        ));
      }
    }
  }

  TcgCard updatePrice(double? newPrice) {
    if (newPrice == null || newPrice == price) return this;
    
    final now = DateTime.now();
    final updatedHistory = List<PriceHistoryEntry>.from(priceHistory)
      ..add(PriceHistoryEntry(
        price: newPrice,
        date: now,
      ));
    
    // Keep only last 30 days of history
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    updatedHistory.removeWhere((entry) => entry.date.isBefore(thirtyDaysAgo));
    
    return copyWith(
      price: newPrice,
      priceHistory: updatedHistory,
      lastPriceUpdate: now,
    );
  }

  factory TcgCard.fromJson(Map<String, dynamic> json) {
    try {
      final setData = json['set'] as Map<String, dynamic>?;
      final SetInfo? setInfo = setData != null ? SetInfo.fromJson(setData) : null;
      
      return TcgCard(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        number: json['number']?.toString() ?? '',
        imageUrl: json['images']?['small']?.toString() ?? '',
        rarity: json['rarity']?.toString(),
        setName: json['set']?['name']?.toString(),
        price: (json['cardmarket']?['prices']?['averageSellPrice'] as num?)?.toDouble(),
        set: setInfo,
        setTotal: json['set']?['total']?.toString(),
        priceHistory: (json['priceHistory'] as List<dynamic>?)
            ?.map((p) => PriceHistoryEntry.fromJson(p as Map<String, dynamic>))
            .toList() ?? [],
        lastPriceUpdate: json['lastPriceUpdate'] != null 
            ? DateTime.parse(json['lastPriceUpdate'])
            : null,
        lastPriceCheck: json['lastPriceCheck'] != null
            ? DateTime.parse(json['lastPriceCheck'])
            : null,
        addedToCollection: json['addedToCollection'] != null 
            ? DateTime.parse(json['addedToCollection'])
            : DateTime.now(),
      );
    } catch (e) {
      print('Error creating TcgCard from JSON: $e');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'number': number,
    'images': {'small': imageUrl},
    'rarity': rarity,
    'cardmarket': {
      'prices': {
        'averageSellPrice': price,
      },
    },
    'priceHistory': priceHistory.map((p) => p.toJson()).toList(),
    'lastPriceUpdate': lastPriceUpdate?.toIso8601String(),
    'lastPriceCheck': lastPriceCheck?.toIso8601String(),
    'set': set?.toJson() ?? {
      'total': setTotal,
    },
    'addedToCollection': addedToCollection?.toIso8601String(),  // Make nullable
  };

  void addPricePoint(double newPrice) {
    final roundedPrice = double.parse(newPrice.toStringAsFixed(2));
    if (priceHistory.isEmpty || priceHistory.last.price != roundedPrice) {
      priceHistory.add(PriceHistoryEntry(
        price: roundedPrice,
        date: DateTime.now(),
      ));
      
      // Keep only last 30 days of history
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      priceHistory.removeWhere((point) => point.date.isBefore(thirtyDaysAgo));
    }
  }

  double? getPriceChange(Duration period) {
    if (priceHistory.length < 2) return null;
    
    // Sort all prices by date
    final sortedPrices = priceHistory.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    
    final now = DateTime.now();
    final targetTime = now.subtract(period);
    
    // Find closest price point before target time
    PriceHistoryEntry? oldEntry;
    for (final entry in sortedPrices) {
      if (entry.date.isBefore(targetTime)) {
        oldEntry = entry;
      } else {
        break;  // Stop when we hit newer entries
      }
    }
    
    if (oldEntry == null) return null;  // No price found before target time
    
    // Get current/latest price
    final currentPrice = price ?? sortedPrices.last.price;
    if (oldEntry.price == 0 || currentPrice == 0) return null;
    
    // Calculate percentage change
    final change = ((currentPrice - oldEntry.price) / oldEntry.price) * 100;
    
    // Filter out unrealistic changes
    if (period.inDays <= 1 && change.abs() > 15) return null;  // Max 15% daily change
    if (period.inDays <= 7 && change.abs() > 30) return null;  // Max 30% weekly change
    if (change.abs() > 50) return null;  // Max 50% monthly change
    
    return change;
  }

  Map<String, double> getPriceStats() {
    if (priceHistory.isEmpty) return {};
    
    final prices = priceHistory.map((p) => p.price).toList();
    final avg = prices.reduce((a, b) => a + b) / prices.length;
    
    return {
      'min': prices.reduce(min),
      'max': prices.reduce(max),
      'avg': avg,
      'volatility': _calculateVolatility(prices, avg),
    };
  }

  double _calculateVolatility(List<double> prices, double mean) {
    if (prices.length < 2) return 0;
    final sumSquares = prices.map((p) => pow(p - mean, 2)).reduce((a, b) => a + b);
    return sqrt(sumSquares / (prices.length - 1));
  }

  PriceHistoryEntry? _findClosestPricePoint(DateTime targetDate) {
    return priceHistory
        .where((pp) => pp.date.isBefore(targetDate))
        .reduce((a, b) => 
          a.date.difference(targetDate).abs() < 
          b.date.difference(targetDate).abs() ? a : b);
  }

  TcgCard copyWith({
    String? id,
    String? name,
    String? number,
    String? imageUrl,
    String? rarity,
    String? setName,
    double? price,
    List<PriceHistoryEntry>? priceHistory,
    SetInfo? set,
    String? setTotal,
    DateTime? lastPriceCheck,
    DateTime? lastPriceUpdate,  // Add this parameter
    DateTime? addedToCollection,  // Add this parameter
  }) {
    return TcgCard(
      id: id ?? this.id,
      name: name ?? this.name,
      number: number ?? this.number,
      imageUrl: imageUrl ?? this.imageUrl,
      rarity: rarity ?? this.rarity,
      setName: setName ?? this.setName,
      price: price ?? this.price,
      priceHistory: priceHistory ?? this.priceHistory,
      set: set ?? this.set,
      setTotal: setTotal ?? this.setTotal,
      lastPriceCheck: lastPriceCheck ?? this.lastPriceCheck,
      lastPriceUpdate: lastPriceUpdate ?? this.lastPriceUpdate,  // Add this line
      addedToCollection: addedToCollection ?? this.addedToCollection,  // Add this line
    );
  }

  double? getPriceAtDate(DateTime date) {
    final historicalPrice = priceHistory
        .where((p) => p.timestamp.isBefore(date) || p.timestamp.isAtSameMomentAs(date))
        .lastOrNull;
    return historicalPrice?.price ?? price;
  }

  void addPriceHistoryPoint(double price, DateTime date) {
    // Normalize date to start of day
    final normalizedDate = DateTime(date.year, date.month, date.day);
    
    // Don't add duplicate prices for same day
    if (priceHistory.isNotEmpty && 
        priceHistory.last.date.isAtSameMomentAs(normalizedDate) &&
        priceHistory.last.price == price) {
      return;
    }

    priceHistory.add(PriceHistoryEntry(
      price: price,
      date: normalizedDate,
    ));

    // Keep only last 90 days of history
    final cutoff = DateTime.now().subtract(const Duration(days: 90));
    priceHistory.removeWhere((point) => point.date.isBefore(cutoff));
  }
}

class SetInfo {
  final String? id;
  final String? name;
  final String? series;
  final int? total;
  final String? releaseDate;

  SetInfo({
    this.id,
    this.name,
    this.series,
    this.total,
    this.releaseDate,
  });

  factory SetInfo.fromJson(Map<String, dynamic> json) {
    try {
      final totalValue = json['total'];
      final total = totalValue != null ? int.tryParse(totalValue.toString()) : null;
      
      return SetInfo(
        id: json['id']?.toString(),
        name: json['name']?.toString(),
        series: json['series']?.toString(),
        total: total,
        releaseDate: json['releaseDate']?.toString(),
      );
    } catch (e) {
      print('Error creating SetInfo from JSON: $e');
      return SetInfo();
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'series': series,
    'total': total?.toString(),
    'releaseDate': releaseDate,
  };
}

class PriceHistoryEntry {
  final double price;
  final DateTime date;
  final String source;
  final String? currency;

  PriceHistoryEntry({
    required this.price, 
    required this.date,
    this.source = 'TCG',
    this.currency = 'USD',
  });

  Map<String, dynamic> toJson() => {
    'price': price,
    'timestamp': date.toIso8601String(),  // Changed from 'date' to 'timestamp'
    'source': source,
    'currency': currency,
  };

  factory PriceHistoryEntry.fromJson(Map<String, dynamic> json) {
    // Handle both 'date' and 'timestamp' fields
    final dateStr = json['date'] ?? json['timestamp'];
    if (dateStr == null) {
      throw FormatException('Missing date/timestamp in price history entry');
    }
    
    return PriceHistoryEntry(
      price: (json['price'] as num).toDouble(),
      date: DateTime.parse(dateStr as String),
      source: json['source'] as String? ?? 'TCG',
      currency: json['currency'] as String? ?? 'USD',
    );
  }

  // Add getter for backward compatibility
  DateTime get timestamp => date;
}
