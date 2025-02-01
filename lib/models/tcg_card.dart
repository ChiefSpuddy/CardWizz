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
  final String? setTotal;  // Add this property

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
    this.setTotal,  // Add this to constructor
  });

  factory TcgCard.fromJson(Map<String, dynamic> json) {
    try {
      final setData = json['set'] as Map<String, dynamic>?;
      final SetInfo? setInfo = setData != null ? SetInfo.fromJson(setData) : null;

      // Handle null values in constructor
      return TcgCard(
        id: json['id']?.toString() ?? '',  // Provide default empty string
        name: json['name']?.toString() ?? '',  // Provide default empty string
        number: json['number']?.toString() ?? '',  // Provide default empty string
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
    'set': set?.toJson() ?? {
      'total': setTotal,
    },
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

  void addPriceHistoryEntry(double price) {
    // Round price to 2 decimal places when adding to history
    final roundedPrice = double.parse(price.toStringAsFixed(2));
    priceHistory.add(PriceHistoryEntry(
      date: DateTime.now(),
      price: roundedPrice,
    ));
    
    // Keep only last 30 days of history
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    priceHistory.removeWhere((entry) => entry.date.isBefore(thirtyDaysAgo));
  }

  // Add method to calculate price change
  double? getPriceChange(Duration period) {
    if (priceHistory.isEmpty || price == null) return null;
    
    final now = DateTime.now();
    final comparison = priceHistory
        .where((entry) => now.difference(entry.date) <= period)
        .fold<double?>(null, (prev, entry) => 
          prev == null || entry.date.isBefore(DateTime.fromMillisecondsSinceEpoch(prev.toInt()))
              ? entry.price
              : prev);
              
    if (comparison == null) return null;
    
    return ((price! - comparison) / comparison) * 100;
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
      // Convert total to string only if it's not null
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
      // Return a SetInfo with null values rather than throwing
      return SetInfo();
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'series': series,
    'total': total?.toString(),  // Only convert to string if not null
    'releaseDate': releaseDate,
  };
}
