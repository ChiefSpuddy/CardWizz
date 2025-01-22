class TcgCard {
  final String id;
  final String name;
  final String imageUrl;
  final String? setName;
  final String? number;
  final double? price;
  final Map<String, dynamic>? cardmarket;
  final String? rarity;
  final String? type;    // Add this field

  TcgCard({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.setName,
    this.number,
    this.price,
    this.cardmarket,
    this.rarity,
    this.type,    // Add this
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
      type: json['type'] as String?,      // Add this
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
    'type': type,      // Add this
  };

  TcgCard copyWith({
    String? id,
    String? name,
    String? imageUrl,
    String? setName,
    String? number,
    double? price,
    Map<String, dynamic>? cardmarket,
    String? rarity,  // Add this
    String? type,    // Add this
  }) {
    return TcgCard(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      setName: setName ?? this.setName,
      number: number ?? this.number,
      price: price ?? this.price,
      cardmarket: cardmarket ?? this.cardmarket,
      rarity: rarity ?? this.rarity,  // Add this
      type: type ?? this.type,        // Add this
    );
  }
}
