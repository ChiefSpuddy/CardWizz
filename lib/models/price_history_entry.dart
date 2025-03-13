class PriceHistoryEntry {
  final double price;
  final DateTime timestamp;

  PriceHistoryEntry({
    required this.price, 
    required this.timestamp
  });

  factory PriceHistoryEntry.fromJson(Map<String, dynamic> json) {
    return PriceHistoryEntry(
      price: (json['price'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'price': price,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
