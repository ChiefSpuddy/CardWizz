class TcgCard {
  final String id;
  final String name;
  final String number;
  final String imageUrl;
  final String? rarity;
  final String? setName;
  final double? price;
  final List<PriceHistoryEntry> priceHistory;
  final SetInfo? set;
  final String? setTotal;
  final List<PricePoint> _priceHistory;

  TcgCard({
    required this.id,
    required this.name,
    required this.number,
    required this.imageUrl,
    this.rarity,
    this.setName,
    this.price,
    this.priceHistory = const [],
    this.set,
    this.setTotal,
  }) : _priceHistory = [];

  List<PricePoint> get priceHistoryPoints => List.unmodifiable(_priceHistory);

  factory TcgCard.fromJson(Map<String, dynamic> json) {
    try {
      final setData = json['set'] as Map<String, dynamic>?;
      final SetInfo? setInfo = setData != null ? SetInfo.fromJson(setData) : null;
      final card = TcgCard(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        number: json['number']?.toString() ?? '',
        imageUrl: json['images']?['small']?.toString() ?? '',
        rarity: json['rarity']?.toString(),
        setName: json['set']?['name']?.toString(),
        price: (json['cardmarket']?['prices']?['averageSellPrice'] as num?)?.toDouble(),
        priceHistory: (json['priceHistory'] as List<dynamic>?)
            ?.map((e) => PriceHistoryEntry.fromJson(e as Map<String, dynamic>))
            .toList() ?? [],
        set: setInfo,
        setTotal: json['set']?['total']?.toString(),
      );

      // Load price history points
      final historyPoints = (json['priceHistoryPoints'] as List<dynamic>?)?.map(
        (p) => PricePoint.fromJson(p as Map<String, dynamic>)
      ).toList() ?? [];
      
      card._priceHistory.addAll(historyPoints);
      return card;
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
    'priceHistory': priceHistory.map((e) => e.toJson()).toList(),
    'priceHistoryPoints': _priceHistory.map((p) => p.toJson()).toList(),
    'set': set?.toJson() ?? {
      'total': setTotal,
    },
  };

  void addPriceHistoryEntry(double price) {
    final roundedPrice = double.parse(price.toStringAsFixed(2));
    priceHistory.add(PriceHistoryEntry(
      date: DateTime.now(),
      price: roundedPrice,
    ));
    
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    priceHistory.removeWhere((entry) => entry.date.isBefore(thirtyDaysAgo));
  }

  void addPricePoint(double newPrice) {
    if (_priceHistory.isEmpty || _priceHistory.last.price != newPrice) {
      _priceHistory.add(PricePoint(
        price: newPrice,
        timestamp: DateTime.now(),
      ));
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      _priceHistory.removeWhere((point) => point.timestamp.isBefore(thirtyDaysAgo));
    }
  }

  double? getPriceChange(Duration period) {
    if (_priceHistory.length < 2) return null;
    
    final now = DateTime.now();
    final targetTime = now.subtract(period);
    
    final oldPrice = _priceHistory
        .where((point) => point.timestamp.isBefore(targetTime))
        .lastOrNull
        ?.price ?? _priceHistory.first.price;
    
    final currentPrice = _priceHistory.last.price;
    
    if (oldPrice == 0) return 0;
    return ((currentPrice - oldPrice) / oldPrice) * 100;
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
    );
  }
}

class PriceHistoryEntry {
  final double price;
  final DateTime date;

  PriceHistoryEntry({
    required this.price,
    required this.date,
  });

  factory PriceHistoryEntry.fromJson(Map<String, dynamic> json) {
    return PriceHistoryEntry(
      date: DateTime.fromMillisecondsSinceEpoch(json['date'] as int),
      price: (json['price'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'date': date.millisecondsSinceEpoch,
    'price': price,
  };
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

  PricePoint({required this.price, required this.timestamp});

  Map<String, dynamic> toJson() => {
    'price': price,
    'timestamp': timestamp.toIso8601String(),
  };

  factory PricePoint.fromJson(Map<String, dynamic> json) => PricePoint(
    price: json['price'] as double,
    timestamp: DateTime.parse(json['timestamp'] as String),
  );
}
