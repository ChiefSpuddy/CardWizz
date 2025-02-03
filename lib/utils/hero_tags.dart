class HeroTags {
  static String cardImage(String cardId, {String? context}) {
    return '${context ?? "card"}_image_$cardId';
  }
  
  static String cardName(String cardId, {String? context}) {
    return '${context ?? "card"}_name_$cardId';
  }
  
  static String cardPrice(String cardId, {String? context}) {
    return '${context ?? "card"}_price_$cardId';
  }
  
  // Add more tag generators as needed
}
