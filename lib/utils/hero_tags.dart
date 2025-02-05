class HeroTags {
  // Store generated tags to prevent duplicates
  static final Map<String, String> _tagCache = {};
  
  /// Generates a unique hero tag for a card image
  /// 
  /// [cardId] - The unique identifier of the card
  /// [context] - A string indicating where the hero is used (e.g., 'collection', 'details')
  static String cardImage(String cardId, {
    required String context,
  }) {
    return 'card_${cardId}_${context}';  // Add context to make tag unique
  }
  
  static String cardName(String cardId, {String? context}) {
    return '${context ?? "default"}_name_$cardId${DateTime.now().millisecondsSinceEpoch}';
  }
  
  static String cardPrice(String cardId, {String? context}) {
    return '${context ?? "default"}_price_$cardId${DateTime.now().millisecondsSinceEpoch}';
  }

  static String collectionItem(String cardId, {String? context}) {
    return '${context ?? "default"}_collection_$cardId${DateTime.now().millisecondsSinceEpoch}';
  }
}
