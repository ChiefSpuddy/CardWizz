class TcgCard {
  final String id;
  final String name;
  final String imageUrl;
  final double? price;
  final String number;
  final CardSet? set;
  final String? rarity;
  final String? supertype;
  final List<String>? subtypes;
  final Map<String, String>? legalities;

  static const String DEFAULT_IMAGE = 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/items/poke-ball.png';

  String get setName => set?.name ?? 'Unknown Set';

  TcgCard({
    required this.id,
    required this.name,
    String? imageUrl,
    this.price,
    this.number = '',
    this.set,
    this.rarity,
    this.supertype,
    this.subtypes,
    this.legalities,
  }) : imageUrl = imageUrl ?? '';  // Simply use the provided URL or empty string

  factory TcgCard.fromJson(Map<String, dynamic> json) {
    String? imageUrl;
    
    // Handle different image URL formats
    if (json['images'] is Map<String, dynamic>) {
      imageUrl = json['images']['small'] ?? json['images']['large'];
    } else if (json['imageUrl'] is String) {
      // Handle old storage format
      imageUrl = json['imageUrl'];
    }
    
    return TcgCard(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      imageUrl: imageUrl,
      price: json['cardmarket']?['prices']?['averageSellPrice']?.toDouble(),
      number: json['number']?.toString() ?? '',
      set: json['set'] != null ? CardSet.fromJson(json['set']) : null,
      rarity: json['rarity'],
      supertype: json['supertype'],
      subtypes: json['subtypes'] != null 
          ? List<String>.from(json['subtypes'])
          : null,
      legalities: json['legalities'] != null 
          ? Map<String, String>.from(json['legalities'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'images': {
      'small': imageUrl,
      'large': imageUrl,
    },
    'cardmarket': {'prices': {'averageSellPrice': price}},
    'number': number,
    'set': set?.toJson(),
    'rarity': rarity,
    'supertype': supertype,
    'subtypes': subtypes,
    'legalities': legalities,
  };
}

class CardSet {
  final String id;
  final String name;
  final String? series;
  final String? releaseDate;

  CardSet({
    required this.id,
    required this.name,
    this.series,
    this.releaseDate,
  });

  factory CardSet.fromJson(Map<String, dynamic> json) {
    return CardSet(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      series: json['series'],
      releaseDate: json['releaseDate'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'series': series,
    'releaseDate': releaseDate,
  };
}
