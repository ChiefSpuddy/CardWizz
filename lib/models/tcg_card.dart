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
  final List<PricePoint> priceHistory;
  final SetInfo? set;
  final String? setTotal;
  final DateTime? lastPriceUpdate;
  final DateTime? lastPriceCheck;

  TcgCard({
    required this.id,
    required this.name,
    required this.number,
    required this.imageUrl,
    this.rarity,
    this.setName,
    double? price,
    List<PricePoint>? priceHistory,
    this.set,
    this.setTotal,
    this.lastPriceUpdate,
    this.lastPriceCheck,
  }) : _price = price,
       priceHistory = priceHistory ?? [];

  double? get price => _price;

  set price(double? newPrice) {
    if (newPrice != _price) {
      _price = newPrice;
      if (newPrice != null) {
        priceHistory.add(PricePoint(
          price: newPrice,
          timestamp: DateTime.now(),
        ));
      }
    }
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
            ?.map((p) => PricePoint.fromJson(p as Map<String, dynamic>))
            .toList() ?? [],
        lastPriceUpdate: json['lastPriceUpdate'] != null 
            ? DateTime.parse(json['lastPriceUpdate'])
            : null,
        lastPriceCheck: json['lastPriceCheck'] != null
            ? DateTime.parse(json['lastPriceCheck'])
            : null,
      );
    } catch (e, stack) {
      print('Error creating TcgCard from JSON: $e');
      print('JSON data: $json');
      print('Stack trace: $stack');
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
  };

  void addPricePoint(double newPrice) {
    final roundedPrice = double.parse(newPrice.toStringAsFixed(2));
    if (priceHistory.isEmpty || priceHistory.last.price != roundedPrice) {
      priceHistory.add(PricePoint(
        price: roundedPrice,
        timestamp: DateTime.now(),
      ));
      
      // Keep only last 30 days of history
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      priceHistory.removeWhere((point) => point.timestamp.isBefore(thirtyDaysAgo));
    }
  }

  double? getPriceChange(Duration period) {
    if (priceHistory.length < 2) return null;
    
    final now = DateTime.now();
    final targetTime = now.subtract(period);
    
    // Find closest historical price point
    final oldPrice = priceHistory
        .where((point) => point.timestamp.isBefore(targetTime))
        .lastOrNull
        ?.price ?? priceHistory.first.price;
    
    final currentPrice = priceHistory.last.price;
    
    if (oldPrice == 0) return 0;
    return ((currentPrice - oldPrice) / oldPrice) * 100;
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

  PricePoint? _findClosestPricePoint(DateTime targetDate) {
    return priceHistory
        .where((pp) => pp.timestamp.isBefore(targetDate))
        .reduce((a, b) => 
          a.timestamp.difference(targetDate).abs() < 
          b.timestamp.difference(targetDate).abs() ? a : b);
  }

  TcgCard copyWith({
    String? id,
    String? name,
    String? number,
    String? imageUrl,
    String? rarity,
    String? setName,
    double? price,
    List<PricePoint>? priceHistory,
    SetInfo? set,
    String? setTotal,
    DateTime? lastPriceCheck,
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
    );
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
    } catch (e, stack) {
      print('Error creating SetInfo from JSON: $e');
      print('JSON data: $json');
      print('Stack trace: $stack');
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

class PricePoint {
  final double price;
  final DateTime timestamp;
  final String source;
  final String? currency;

  PricePoint({
    required this.price, 
    required this.timestamp,
    this.source = 'TCG',
    this.currency = 'USD',
  });

  Map<String, dynamic> toJson() => {
    'price': price,
    'timestamp': timestamp.toIso8601String(),
    'source': source,
    'currency': currency,
  };

  factory PricePoint.fromJson(Map<String, dynamic> json) => PricePoint(
    price: json['price'] as double,
    timestamp: DateTime.parse(json['timestamp'] as String),
    source: json['source'] as String? ?? 'TCG',
    currency: json['currency'] as String? ?? 'USD',
  );
}
