import 'package:intl/intl.dart';
import 'dart:math';

class TcgCard {
  final String id;
  final String name;
  final String imageUrl;
  final String? largeImageUrl; // Added field
  final String? number;
  final String? rarity;
  final TcgSet set;
  final double? price;
  final String? types;
  final String? subtypes;
  final String? artist;
  final Map<String, dynamic>? cardmarket;
  final Map<String, dynamic>? rawData;
  final DateTime? dateAdded; // Added field
  final DateTime? addedToCollection; // Added field
  final List<PriceHistoryEntry> priceHistory; // Added field
  final DateTime? lastPriceUpdate; // Added field
  final bool? isMtg; // Added field
  double? previousPrice;
  DateTime? lastPriceChange;

  // Added getters for backwards compatibility
  String? get setName => set.name;
  int? get setTotal => set.total;

  TcgCard({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.largeImageUrl, // Added parameter
    this.number,
    this.rarity,
    required this.set,
    this.price,
    this.types,
    this.subtypes,
    this.artist,
    this.cardmarket,
    this.rawData,
    this.dateAdded, // Added parameter
    this.addedToCollection, // Added parameter
    List<PriceHistoryEntry>? priceHistory, // Added parameter
    this.lastPriceUpdate, // Added parameter
    this.isMtg, // Added parameter
  }) : this.priceHistory = priceHistory ?? []; // Initialize priceHistory

  // Add method to add price history point
  TcgCard addPriceHistoryPoint(double price, DateTime timestamp) {
    // Create a new price history entry
    final entry = PriceHistoryEntry(
      price: price,
      timestamp: timestamp,
      source: PriceSource.tcg,
      currency: 'USD',
    );
    
    // Create a new list with the entry added
    final updatedHistory = List<PriceHistoryEntry>.from(priceHistory)..add(entry);
    
    // Return a new card with the updated price history
    return copyWith(
      priceHistory: updatedHistory,
      lastPriceUpdate: timestamp,
    );
  }

  factory TcgCard.fromJson(Map<String, dynamic> json) {
    // Improved MTG detection logic
    bool isMtg;
    
    // First check for explicit flag
    if (json['isMtg'] != null) {
      isMtg = json['isMtg'] == true;
    } else {
      // Check for MTG-specific data patterns
      isMtg = (json['id'] as String).startsWith('mtg_') ||
             json.containsKey('oracle_text') ||
             json.containsKey('mana_cost');
      
      // Check set_id - Pokemon sets usually have longer codes with numbers
      final setId = json['set']?['id'] ?? json['setCode'] ?? '';
      
      // If still undetermined, check if it looks like a Pokemon set ID
      if (!isMtg && setId is String) {
        if (setId.toLowerCase().startsWith('sv') || 
            setId.toLowerCase().startsWith('swsh') ||
            setId.toLowerCase().startsWith('sm') ||
            setId.toLowerCase().startsWith('xy') ||
            setId.toLowerCase().startsWith('bw') ||
            RegExp(r'sv\d').hasMatch(setId.toLowerCase())) {
          isMtg = false;  // Definitely Pokemon
        } else if (setId.length <= 3 && 
                  !setId.toLowerCase().startsWith('sv') &&
                  !setId.toLowerCase().startsWith('sm')) {
          isMtg = true;  // Likely MTG with short set code
        }
      }
    }

    // Handle set data safely
    TcgSet cardSet;
    try {
      // For MTG cards from Scryfall, handle their set format
      if (json['set'] is Map<String, dynamic>) {
        cardSet = TcgSet.fromJson(json['set'] as Map<String, dynamic>);
      } else {
        // For Pokemon TCG API format
        cardSet = TcgSet.fromJson({
          'id': json['set']?['id'] ?? json['setCode'] ?? '',
          'name': json['set']?['name'] ?? json['setName'] ?? 'Unknown Set',
          'series': json['set']?['series'] ?? '',
          'printedTotal': json['set']?['printedTotal'] ?? 0,
          'total': json['set']?['total'] ?? 0,
          'releaseDate': json['set']?['releaseDate'] ?? '',
          'images': json['set']?['images'] ?? {},
        });
      }
    } catch (e) {
      print('Error creating TcgSet from JSON: $e');
      // Provide a fallback set with minimal required fields
      cardSet = TcgSet(
        id: json['set']?['id'] ?? '',
        name: json['set']?['name'] ?? 'Unknown Set',
        series: json['set']?['series'] ?? '',
        printedTotal: 0,
        total: 0,
        releaseDate: json['set']?['releaseDate'] ?? '',
        images: {},
      );
    }

    // Handle price safely (could come from different sources)
    double? cardPrice;
    try {
      if (json['price'] != null) {
        cardPrice = json['price'] is double 
          ? json['price'] 
          : double.tryParse(json['price'].toString()) ?? 0.0;
      } else if (json['cardmarket'] != null && json['cardmarket']['prices'] != null) {
        final prices = json['cardmarket']['prices'];
        cardPrice = prices['averageSellPrice'] ?? 
                    prices['lowPrice'] ?? 
                    prices['trendPrice'] ?? 0.0;
      }
    } catch (e) {
      print('Error parsing price: $e');
      cardPrice = 0.0;
    }

    // Parse price history if available
    List<PriceHistoryEntry>? priceHistory;
    try {
      if (json['priceHistory'] != null) {
        priceHistory = (json['priceHistory'] as List)
            .map((entry) => PriceHistoryEntry.fromJson(entry))
            .toList();
      }
    } catch (e) {
      print('Error parsing price history: $e');
      priceHistory = [];
    }

    // Parse dates
    DateTime? dateAdded;
    if (json['dateAdded'] != null) {
      dateAdded = DateTime.tryParse(json['dateAdded']);
    }

    DateTime? addedToCollection;
    if (json['addedToCollection'] != null) {
      addedToCollection = DateTime.tryParse(json['addedToCollection']);
    }

    DateTime? lastPriceUpdate;
    if (json['lastPriceUpdate'] != null) {
      lastPriceUpdate = DateTime.tryParse(json['lastPriceUpdate']);
    }

    return TcgCard(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown Card',
      imageUrl: json['imageUrl'] ?? json['image'] ?? json['images']?['small'] ?? '',
      largeImageUrl: json['largeImageUrl'] ?? json['images']?['large'] ?? '',
      number: json['number'] != null ? json['number'].toString() : null,
      rarity: json['rarity'] ?? '',
      set: cardSet,
      price: cardPrice,
      types: json['types'] is List ? (json['types'] as List).join(', ') : json['types']?.toString(),
      subtypes: json['subtypes'] is List ? (json['subtypes'] as List).join(', ') : json['subtypes']?.toString(),
      artist: json['artist'] ?? '',
      cardmarket: json['cardmarket'] as Map<String, dynamic>?,
      rawData: json,
      dateAdded: dateAdded,
      addedToCollection: addedToCollection,
      priceHistory: priceHistory,
      lastPriceUpdate: lastPriceUpdate,
      isMtg: isMtg, // Added field
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'largeImageUrl': largeImageUrl,
      'number': number,
      'rarity': rarity,
      'set': set.toJson(),
      'price': price,
      'types': types,
      'subtypes': subtypes,
      'artist': artist,
      'cardmarket': cardmarket,
      'dateAdded': dateAdded?.toIso8601String(),
      'addedToCollection': addedToCollection?.toIso8601String(),
      'priceHistory': priceHistory.map((entry) => entry.toJson()).toList(),
      'lastPriceUpdate': lastPriceUpdate?.toIso8601String(),
      'isMtg': isMtg, // Added field
    };
  }

  TcgCard copyWith({
    String? id,
    String? name,
    String? imageUrl,
    String? largeImageUrl,
    String? number,
    String? rarity,
    TcgSet? set,
    double? price,
    String? types,
    String? subtypes,
    String? artist,
    Map<String, dynamic>? cardmarket,
    Map<String, dynamic>? rawData,
    DateTime? dateAdded,
    DateTime? addedToCollection,
    List<PriceHistoryEntry>? priceHistory,
    DateTime? lastPriceUpdate,
    bool? isMtg, // Added parameter
  }) {
    return TcgCard(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      largeImageUrl: largeImageUrl ?? this.largeImageUrl,
      number: number ?? this.number,
      rarity: rarity ?? this.rarity,
      set: set ?? this.set,
      price: price ?? this.price,
      types: types ?? this.types,
      subtypes: subtypes ?? this.subtypes,
      artist: artist ?? this.artist,
      cardmarket: cardmarket ?? this.cardmarket,
      rawData: rawData ?? this.rawData,
      dateAdded: dateAdded ?? this.dateAdded,
      addedToCollection: addedToCollection ?? this.addedToCollection,
      priceHistory: priceHistory ?? List.from(this.priceHistory),
      lastPriceUpdate: lastPriceUpdate ?? this.lastPriceUpdate,
      isMtg: isMtg ?? this.isMtg, // Added parameter
    );
  }

  // Add price change calculation methods
  double? getPriceChange(Duration duration) {
    if (priceHistory.isEmpty || price == null) return null;
    
    final now = DateTime.now();
    final pastDate = now.subtract(duration);
    
    // Find closest price point to the past date
    PriceHistoryEntry? pastEntry;
    double? smallestDiff;
    
    for (final entry in priceHistory) {
      if (entry.timestamp.isBefore(pastDate) || entry.timestamp.isAtSameMomentAs(pastDate)) {
        final diff = pastDate.difference(entry.timestamp).inSeconds.abs();
        if (smallestDiff == null || diff < smallestDiff) {
          smallestDiff = diff.toDouble();
          pastEntry = entry;
        }
      }
    }
    
    if (pastEntry == null) return null;
    
    // Calculate change
    final pastPrice = pastEntry.price;
    final change = price! - pastPrice;
    return change;
  }

  // Replace the duplicate getPriceChangePeriod methods with this single implementation
  MapEntry<String, double>? getPriceChangePeriod() {
    if (lastPriceChange != null && previousPrice != null && price != null) {
      final now = DateTime.now();
      final diff = now.difference(lastPriceChange!);
      final percentChange = ((price! - previousPrice!) / previousPrice!) * 100;
      
      if (diff.inDays < 1) {
        return MapEntry('24h', percentChange);
      } else if (diff.inDays < 7) {
        return MapEntry('${diff.inDays}d', percentChange);
      } else {
        return MapEntry('30d', percentChange);
      }
    }
    
    // Fall back to historical data if no direct change
    if (priceHistory.isEmpty || price == null) return null;
    
    // Find earliest price entry
    final earliestEntry = priceHistory.reduce((a, b) => 
      a.timestamp.isBefore(b.timestamp) ? a : b
    );
    
    // Calculate duration since earliest price
    final duration = DateTime.now().difference(earliestEntry.timestamp);
    final daysAgo = duration.inDays;
    
    // Calculate price change since then
    final startPrice = earliestEntry.price;
    // Explicitly cast the percentage to double
    final percentChange = startPrice > 0 
        ? (((price! - startPrice) / startPrice) * 100).toDouble() 
        : 0.0;
    
    // Map duration to appropriate label
    String timeLabel;
    if (daysAgo < 1) {
      timeLabel = '24h';
    } else if (daysAgo < 7) {
      timeLabel = '${daysAgo}d';
    } else {
      timeLabel = '30d';
    }
    
    return MapEntry(timeLabel, percentChange);
  }

  // Helper method to detect if this is an MTG card
  bool get isMagicCard => isMtg == true || set.id.length <= 3;

  @override
  String toString() {
    return 'TcgCard(name: $name, set: ${set.name})';
  }
}

/// Extension to add MTG-specific functionality to TcgCard
extension MtgCardExtension on TcgCard {
  /// Check if this is an MTG card based on the image URL or raw data
  bool get isMtgCard {
    // First check explicit flag
    if (isMtg == true) {
      return true;
    }
    
    // Check if image URL contains scryfall.io which is specific to MTG cards
    if (imageUrl.contains('scryfall.io') || imageUrl.contains('scryfall.com')) {
      return true;
    }
    
    // Check if rawData has MTG-specific fields
    if (rawData != null) {
      return rawData!.containsKey('set_type') || 
             rawData!.containsKey('oracle_text') ||
             rawData!.containsKey('mana_cost');
    }
    
    // Check if ID has MTG prefix
    if (id.startsWith('mtg_')) {
      return true;
    }
    
    return false;
  }
  
  /// Get the correct image URL based on card type
  String get effectiveImageUrl {
    if (isMtgCard) {
      // Ensure we have a valid image URL for MTG cards
      if (imageUrl.isEmpty && largeImageUrl != null && largeImageUrl!.isNotEmpty) {
        return largeImageUrl!;
      }
    }
    
    return imageUrl;
  }
  
  /// Get the correct large image URL based on card type
  String get effectiveLargeImageUrl {
    if (isMtgCard) {
      if (largeImageUrl != null && largeImageUrl!.isNotEmpty) {
        return largeImageUrl!;
      }
      return imageUrl;
    }
    
    return largeImageUrl ?? imageUrl;
  }
}

/// Extension to add Pokemon-specific functionality to TcgCard
extension PokemonCardExtension on TcgCard {
  /// Check if this is a Pokemon card based on various signals
  bool get isPokemonCard {
    // Check explicit flag first
    if (isMtg == false) return true;
    
    // Check for Pokemon set ID patterns
    const pokemonPrefixes = ['sv', 'swsh', 'sm', 'xy', 'bw', 'dp', 'ex', 'cel'];
    for (final prefix in pokemonPrefixes) {
      if (set.id.toLowerCase().startsWith(prefix)) {
        return true;
      }
    }
    
    // Check name patterns like "Pikachu V" or "Charizard ex"
    final nameLower = name.toLowerCase();
    if (nameLower.contains('pikachu') || 
        nameLower.contains('charizard') ||
        nameLower.endsWith(' ex') ||
        nameLower.endsWith(' v') ||
        nameLower.contains(' gx') ||
        nameLower.contains(' vmax')) {
      return true;
    }
    
    // Default to false if no Pokemon signals detected
    return false;
  }
}

class TcgSet {
  final String id;
  final String name;
  final String? series;
  final int? printedTotal;
  final int? total;
  final String? releaseDate;
  final Map<String, dynamic>? images;

  TcgSet({
    required this.id,
    required this.name,
    this.series, // Changed from required to optional
    this.printedTotal, // Changed from required to optional
    this.total, // Changed from required to optional
    this.releaseDate, // Changed from required to optional
    this.images, // Changed from required to optional
  });

  factory TcgSet.fromJson(Map<String, dynamic> json) {
    // Handle the various ways images might be provided
    Map<String, dynamic> imagesMap = {};
    if (json['images'] != null) {
      imagesMap = json['images'] as Map<String, dynamic>;
    } else {
      // Try to construct from individual fields that might be present
      if (json['logo'] != null) {
        imagesMap['logo'] = json['logo'];
      }
      if (json['symbol'] != null) {
        imagesMap['symbol'] = json['symbol'];
      }
    }

    // Handle printedTotal and total fields safely
    int? printedTotal;
    try {
      if (json['printedTotal'] != null) {
        printedTotal = json['printedTotal'] is int 
            ? json['printedTotal'] 
            : int.tryParse(json['printedTotal'].toString());
      }
    } catch (e) {
      print('Error parsing printedTotal: $e');
    }

    int? total;
    try {
      if (json['total'] != null) {
        total = json['total'] is int 
            ? json['total'] 
            : int.tryParse(json['total'].toString());
      }
    } catch (e) {
      print('Error parsing total: $e');
    }

    return TcgSet(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown Set',
      series: json['series'] ?? '',
      printedTotal: printedTotal,
      total: total,
      releaseDate: json['releaseDate'] ?? json['release_date'] ?? '',
      images: imagesMap,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'series': series,
      'printedTotal': printedTotal,
      'total': total,
      'releaseDate': releaseDate,
      'images': images,
    };
  }
}

class TcgCardCollection {
  final String id;
  final String name;
  final List<TcgCard> cards;
  final DateTime createdAt;
  final DateTime updatedAt;

  TcgCardCollection({
    required this.id,
    required this.name,
    required this.cards,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TcgCardCollection.fromJson(Map<String, dynamic> json) {
    return TcgCardCollection(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unnamed Collection',
      cards: (json['cards'] as List?)
              ?.map((cardJson) => TcgCard.fromJson(cardJson))
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'cards': cards.map((card) => card.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  TcgCardCollection copyWith({
    String? id,
    String? name,
    List<TcgCard>? cards,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TcgCardCollection(
      id: id ?? this.id,
      name: name ?? this.name,
      cards: cards ?? this.cards,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class PriceHistoryEntry {
  final double price;
  final DateTime timestamp;  // Changed from 'date' to 'timestamp'
  final String? currency;
  final PriceSource source;

  PriceHistoryEntry({
    required this.price, 
    required this.timestamp,  // Changed parameter name to match field
    this.source = PriceSource.tcg,  // Default to TCG API
    this.currency = 'USD',
  });

  Map<String, dynamic> toJson() => {
    'price': price,
    'timestamp': timestamp.toIso8601String(),
    'source': source.toString().split('.').last,
    'currency': currency,
  };

  factory PriceHistoryEntry.fromJson(Map<String, dynamic> json) {
    final timestampStr = json['timestamp'] ?? json['date'];
    if (timestampStr == null) {
      throw FormatException('Missing timestamp/date in price history entry');
    }
    
    return PriceHistoryEntry(
      price: (json['price'] as num).toDouble(),
      timestamp: DateTime.parse(timestampStr as String),
      source: PriceSource.values.firstWhere(
        (e) => e.toString().split('.').last == json['source'],
        orElse: () => PriceSource.tcg,
      ),
      currency: json['currency'] as String? ?? 'USD',
    );
  }
}

enum PriceSource {
  tcg,
  ebay,
}
