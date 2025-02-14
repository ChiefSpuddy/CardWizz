import 'package:intl/intl.dart';
import 'dart:math';

class TcgCard {
  final String id;
  final String name;
  final String number;
  final String imageUrl;
  final String largeImageUrl;
  final String? rarity;
  final TcgSet? set;
  final double? price;
  final List<PriceHistoryEntry> priceHistory;
  final String? setTotal;
  final DateTime? dateAdded;
  final DateTime? addedToCollection;
  final DateTime? lastPriceUpdate;

  TcgCard({
    required this.id,
    required this.name,
    required this.number,
    required this.imageUrl,
    required this.largeImageUrl,
    this.rarity,
    this.set,
    this.price,
    List<PriceHistoryEntry>? priceHistory,
    this.setTotal,
    this.dateAdded,
    this.addedToCollection,
    this.lastPriceUpdate,
  }) : priceHistory = priceHistory ?? [];

  String? get setName => set?.name;

  double? getPriceChange(Duration period) {
    if (priceHistory.length < 2) return null;
    
    final now = DateTime.now();
    final cutoff = now.subtract(period);
    
    final currentPrice = price ?? priceHistory.last.price;
    final oldestInPeriod = priceHistory
        .where((entry) => entry.date.isAfter(cutoff))
        .fold<PriceHistoryEntry?>(
          null,
          (oldest, entry) => oldest == null || entry.date.isBefore(oldest.date)
              ? entry
              : oldest,
        );

    if (oldestInPeriod == null) return null;
    
    if (oldestInPeriod.price == 0) return 0;
    return ((currentPrice - oldestInPeriod.price) / oldestInPeriod.price) * 100;
  }

  String getPriceChangePeriod() {
    final change = getPriceChange(const Duration(days: 1));
    if (change != null) return '24h';
    
    final weekChange = getPriceChange(const Duration(days: 7));
    if (weekChange != null) return '7d';
    
    final monthChange = getPriceChange(const Duration(days: 30));
    if (monthChange != null) return '30d';
    
    return '';
  }

  void addPriceHistoryPoint(double price, DateTime date) {
    priceHistory.add(PriceHistoryEntry(
      price: price,
      date: date,
    ));
    
    // Keep only last 30 days of history
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    priceHistory.removeWhere((entry) => entry.date.isBefore(thirtyDaysAgo));
  }

  factory TcgCard.fromJson(Map<String, dynamic> json) {
    try {
      final setData = json['set'] as Map<String, dynamic>?;
      final TcgSet? setInfo = setData != null ? TcgSet.fromJson(setData) : null;
      
      return TcgCard(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        number: json['number']?.toString() ?? '',
        imageUrl: json['images']?['small']?.toString() ?? '',
        largeImageUrl: json['images']?['large']?.toString() ?? '',
        rarity: json['rarity']?.toString(),
        set: setInfo,
        setTotal: json['set']?['total']?.toString(),
        price: (json['cardmarket']?['prices']?['averageSellPrice'] as num?)?.toDouble(),
        priceHistory: (json['priceHistory'] as List<dynamic>?)
            ?.map((p) => PriceHistoryEntry.fromJson(p as Map<String, dynamic>))
            .toList(),
        dateAdded: json['dateAdded'] != null 
            ? DateTime.parse(json['dateAdded'] as String)
            : null,
        addedToCollection: json['addedToCollection'] != null 
            ? DateTime.parse(json['addedToCollection'] as String)
            : null,
        lastPriceUpdate: json['lastPriceUpdate'] != null
            ? DateTime.parse(json['lastPriceUpdate'] as String)
            : null,
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
    'images': {
      'small': imageUrl,
      'large': largeImageUrl,
    },
    'rarity': rarity,
    'set': set?.toJson(),
    'setTotal': setTotal,
    'cardmarket': {
      'prices': {
        'averageSellPrice': price,
      },
    },
    'priceHistory': priceHistory.map((p) => p.toJson()).toList(),
    'dateAdded': dateAdded?.toIso8601String(),
    'addedToCollection': addedToCollection?.toIso8601String(),
    'lastPriceUpdate': lastPriceUpdate?.toIso8601String(),
  };

  TcgCard copyWith({
    String? id,
    String? name,
    String? number,
    String? imageUrl,
    String? largeImageUrl,
    String? rarity,
    TcgSet? set,
    double? price,
    List<PriceHistoryEntry>? priceHistory,
    String? setTotal,
    DateTime? dateAdded,
    DateTime? addedToCollection,
    DateTime? lastPriceUpdate,
  }) {
    return TcgCard(
      id: id ?? this.id,
      name: name ?? this.name,
      number: number ?? this.number,
      imageUrl: imageUrl ?? this.imageUrl,
      largeImageUrl: largeImageUrl ?? this.largeImageUrl,
      rarity: rarity ?? this.rarity,
      set: set ?? this.set,
      price: price ?? this.price,
      priceHistory: priceHistory ?? this.priceHistory,
      setTotal: setTotal ?? this.setTotal,
      dateAdded: dateAdded ?? this.dateAdded,
      addedToCollection: addedToCollection ?? this.addedToCollection,
      lastPriceUpdate: lastPriceUpdate ?? this.lastPriceUpdate,
    );
  }
}

class TcgSet {
  final String id;
  final String name;
  final String series;
  final int total;

  TcgSet({
    required this.id,
    required this.name,
    required this.series,
    required this.total,
  });

  factory TcgSet.fromJson(Map<String, dynamic> json) {
    // Fix the total field parsing
    final totalRaw = json['total'];
    final total = totalRaw is String ? int.parse(totalRaw) : totalRaw as int;
    
    return TcgSet(
      id: json['id'] as String,
      name: json['name'] as String,
      series: json['series'] as String,
      total: total,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'series': series,
    'total': total,
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
    'timestamp': date.toIso8601String(),
    'source': source,
    'currency': currency,
  };

  factory PriceHistoryEntry.fromJson(Map<String, dynamic> json) {
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

  DateTime get timestamp => date;
}
