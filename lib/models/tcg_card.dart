class TcgCard {
  final String id;
  final String name;
  final String number;
  final String imageUrl;
  final String? rarity;
  final String? setName;
  final double? price;
  final List<PriceHistoryEntry> priceHistory;
  final SetInfo? set;  // Add this field

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
  });

  factory TcgCard.fromJson(Map<String, dynamic> json) {
    return TcgCard(
      id: json['id'] as String,
      name: json['name'] as String,
      number: json['number'] as String,
      imageUrl: json['images']?['small'] as String? ?? '',
      rarity: json['rarity'] as String?,
      setName: json['set']?['name'] as String?,
      price: (json['cardmarket']?['prices']?['averageSellPrice'] as num?)?.toDouble(),
      priceHistory: (json['priceHistory'] as List<dynamic>?)
          ?.map((e) => PriceHistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      set: json['set'] != null ? SetInfo.fromJson(json['set'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'number': number,
    'images': {'small': imageUrl},
    'rarity': rarity,
    'set': set?.toJson(),
    'cardmarket': {
      'prices': {
        'averageSellPrice': price,
      },
    },
    'priceHistory': priceHistory.map((e) => e.toJson()).toList(),
  };

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
    );
  }

  void addPriceHistoryEntry(double price) {
    priceHistory.add(PriceHistoryEntry(
      date: DateTime.now(),
      price: price,
    ));
    
    // Keep only last 30 days of history
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    priceHistory.removeWhere((entry) => entry.date.isBefore(thirtyDaysAgo));
  }
}

class PriceHistoryEntry {
  final DateTime date;
  final double price;

  PriceHistoryEntry({
    required this.date,
    required this.price,
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
  final String id;
  final String name;
  final String? series;
  final String? releaseDate;

  SetInfo({
    required this.id,
    required this.name,
    this.series,
    this.releaseDate,
  });

  factory SetInfo.fromJson(Map<String, dynamic> json) {
    return SetInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      series: json['series'] as String?,
      releaseDate: json['releaseDate'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'series': series,
    'releaseDate': releaseDate,
  };
}
