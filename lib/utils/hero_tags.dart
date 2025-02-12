class HeroTags {
  static final Map<String, int> _counters = {};

  static String cardImage(String cardId, {required String context}) {
    _counters[cardId] = (_counters[cardId] ?? 0) + 1;
    return '${context}_${cardId}_${_counters[cardId]}';
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
