import 'dart:convert';

class MarketCache {
  final Map<String, dynamic> opportunities;
  final DateTime timestamp;
  static const Duration cacheValidity = Duration(hours: 12);

  MarketCache({
    required this.opportunities,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isValid {
    final now = DateTime.now();
    return now.difference(timestamp) < cacheValidity;
  }

  Map<String, dynamic> toJson() => {
    'opportunities': opportunities,
    'timestamp': timestamp.toIso8601String(),
  };

  factory MarketCache.fromJson(Map<String, dynamic> json) {
    return MarketCache(
      opportunities: json['opportunities'] as Map<String, dynamic>,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  static MarketCache? fromString(String? data) {
    if (data == null) return null;
    try {
      return MarketCache.fromJson(json.decode(data));
    } catch (e) {
      print('Error parsing market cache: $e');
      return null;
    }
  }

  String toJsonString() => json.encode(toJson());
}
