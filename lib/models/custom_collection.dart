import 'package:flutter/material.dart';

class CustomCollection {
  final String id;
  final String name;
  final String description;
  final List<String> cardIds;
  final double? totalValue;
  final List<Map<String, dynamic>> priceHistory;
  final DateTime createdAt;
  final Color color;  // Add this

  CustomCollection({
    required this.id,
    required this.name,
    this.description = '',
    this.cardIds = const [],
    this.totalValue,
    this.priceHistory = const [],
    DateTime? createdAt,
    this.color = const Color(0xFF90CAF9),  // Default to light blue
  }) : createdAt = createdAt ?? DateTime.now();

  factory CustomCollection.fromJson(Map<String, dynamic> json) {
    return CustomCollection(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      cardIds: List<String>.from(json['cardIds'] ?? []),
      totalValue: json['totalValue']?.toDouble(),
      priceHistory: List<Map<String, dynamic>>.from(json['priceHistory'] ?? []),
      createdAt: DateTime.parse(json['createdAt'] as String),
      color: Color(json['color'] as int? ?? 0xFF90CAF9),
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
    'color': color.value,
  };

  CustomCollection copyWith({
    String? name,
    String? description,
    List<String>? cardIds,
    double? totalValue,
    List<Map<String, dynamic>>? priceHistory,
    Color? color,
  }) {
    return CustomCollection(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      cardIds: cardIds ?? this.cardIds,
      totalValue: totalValue ?? this.totalValue,
      priceHistory: priceHistory ?? this.priceHistory,
      createdAt: createdAt,
      color: color ?? this.color,
    );
  }
}
