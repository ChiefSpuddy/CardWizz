class TcgCard {
  final String id;
  final String name;
  final String imageUrl;
  final String? setName;
  final String? number;
  final double? price;
  final Map<String, dynamic>? cardmarket;
  final String? rarity;

  TcgCard({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.setName,
    this.number,
    this.price,
    this.cardmarket,
    this.rarity,
  });

  String get setNumber => number != null ? '#$number' : '';

  factory TcgCard.fromJson(Map<String, dynamic> json) {
    // Handle both API response and stored data formats
    final images = json['images'] as Map<String, dynamic>?;
    final set = json['set'] as Map<String, dynamic>?;
    final market = json['cardmarket'] as Map<String, dynamic>?;
    final prices = market?['prices'] as Map<String, dynamic>?;

    // If imageUrl is directly stored, use it; otherwise get it from images map
    final imageUrl = json['imageUrl'] as String? ?? images?['small'] as String?;
    
    if (imageUrl == null) {
      throw ArgumentError('Card data must include an image URL');
    }

    return TcgCard(
      id: json['id'] as String,
      name: json['name'] as String,
      imageUrl: imageUrl,
      setName: json['setName'] as String? ?? set?['name'] as String?,
      number: json['number']?.toString(),
      price: json['price']?.toDouble() ?? prices?['averageSellPrice']?.toDouble(),
      cardmarket: market,
      rarity: json['rarity'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'imageUrl': imageUrl,
    'setName': setName,
    'number': number,
    'price': price,
    'cardmarket': cardmarket,
    'rarity': rarity,
  };
}
