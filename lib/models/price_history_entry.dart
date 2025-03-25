class PriceHistoryEntry {
  final DateTime timestamp;
  final double price;
  final String? source;

  PriceHistoryEntry({
    required this.timestamp, 
    required this.price, 
    this.source,
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'price': price,
      'source': source,
    };
  }

  // Create from JSON
  factory PriceHistoryEntry.fromJson(Map<String, dynamic> json) {
    return PriceHistoryEntry(
      timestamp: DateTime.parse(json['timestamp']),
      price: json['price'] is num 
          ? (json['price'] as num).toDouble() 
          : double.tryParse(json['price'].toString()) ?? 0.0,
      source: json['source'],
    );
  }

  // Create a copy with updated data
  PriceHistoryEntry copyWith({
    DateTime? timestamp,
    double? price,
    String? source,
  }) {
    return PriceHistoryEntry(
      timestamp: timestamp ?? this.timestamp,
      price: price ?? this.price,
      source: source ?? this.source,
    );
  }
}
