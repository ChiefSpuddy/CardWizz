class TcgCard {
  final String id;
  final String name;
  final String imageUrl;
  final String? setName;
  final String? rarity;
  final double? price;

  TcgCard({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.setName,
    this.rarity,
    this.price,
  });

  factory TcgCard.fromJson(Map<String, dynamic> json) {
    return TcgCard(
      id: json['id'] as String,
      name: json['name'] as String,
      imageUrl: json['imageUrl'] as String,
      setName: json['setName'] as String?,
      rarity: json['rarity'] as String?,
      price: json['price']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'setName': setName,
      'rarity': rarity,
      'price': price,
    };
  }
}
