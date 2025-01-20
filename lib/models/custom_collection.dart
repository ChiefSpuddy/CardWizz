class CustomCollection {
  final String id;
  final String name;
  final String description;
  final List<String> cardIds;
  final double? totalValue;
  final List<Map<String, dynamic>> priceHistory;
  final DateTime createdAt;
  final List<String> tags;
  final List<Map<String, dynamic>> notes;

  CustomCollection({
    required this.id,
    required this.name,
    this.description = '',
    this.cardIds = const [],
    this.totalValue,
    this.priceHistory = const [],
    DateTime? createdAt,
    this.tags = const [],
    this.notes = const [],
  }) : createdAt = createdAt ?? DateTime.now();

  factory CustomCollection.fromJson(Map<String, dynamic> json) {
    return CustomCollection(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      cardIds: List<String>.from(json['cardIds'] ?? []),
      totalValue: json['totalValue']?.toDouble(),
      priceHistory: List<Map<String, dynamic>>.from(json['priceHistory'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
      tags: List<String>.from(json['tags'] ?? []),
      notes: List<Map<String, dynamic>>.from(json['notes'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'cardIds': cardIds,
        'totalValue': totalValue,
        'priceHistory': priceHistory,
        'createdAt': createdAt.toIso8601String(),
        'tags': tags,
        'notes': notes,
      };
}
