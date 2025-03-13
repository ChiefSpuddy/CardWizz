import 'dart:convert';
import 'package:crypto/crypto.dart'; // Import for SHA-1 function if not already imported
import '../models/tcg_card.dart';  // Add this import

/// Utility class for managing hero tags in a consistent way throughout the app.
/// 
/// This prevents hero tag collisions by ensuring each card has a unique tag based
/// on its source context and ID.
class HeroTags {
  /// Creates a hero tag for a card in a search context.
  static String forSearchResult(TcgCard card) {
    return 'search_${card.id}';
  }

  /// Creates a hero tag for a card in a collection context.
  static String forCollection(TcgCard card) {
    return 'collection_${card.id}';
  }

  /// Creates a hero tag for a card in a details view context.
  static String forDetails(TcgCard card) {
    return 'details_${card.id}';
  }

  /// Creates a hero tag for a card in a custom context.
  static String forCustomContext(String context, TcgCard card) {
    return '${context}_${card.id}';
  }

  /// Creates a hero tag for a card with a base tag and ensures uniqueness.
  static String withBase(String baseTag, TcgCard card) {
    if (baseTag.contains(card.id)) {
      // Already contains the card ID, no need to add it again
      return baseTag;
    }
    return '${baseTag}_${card.id}';
  }

  /// Creates a hero tag specifically for a card image.
  /// 
  /// @param cardId The unique identifier of the card
  /// @param context The source context where the card is displayed
  /// @return A unique hero tag for the card image
  static String cardImage(String cardId, {String context = 'default'}) {
    return 'card_image_$cardId:$context';
  }

  /// Create a tag for card search results
  static String searchResult(String query, int index) {
    return 'search_result_${_hashString(query)}_$index';
  }

  /// Create a tag for collection items
  static String collectionItem(String collectionId, String cardId) {
    return 'collection_$collectionId:$cardId';
  }

  /// Create a tag for binder items
  static String binderItem(String binderId, String cardId) {
    return 'binder_$binderId:$cardId';
  }

  /// Create a tag for set icons
  static String setIcon(String setId) {
    return 'set_icon_$setId';
  }

  /// Create a hash string for long values to keep tag length manageable
  static String _hashString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha1.convert(bytes);
    return digest.toString().substring(0, 8);
  }

  /// Create a tag for animating card prices
  static String priceTag(String cardId) {
    return 'price_$cardId';
  }

  /// Create a tag for rarity indicators
  static String rarityIndicator(String cardId) {
    return 'rarity_$cardId';
  }

  /// Creates a hero tag specifically for an MTG card image.
  /// 
  /// @param cardId The unique identifier of the card
  /// @param context The source context where the card is displayed
  /// @return A unique hero tag for the MTG card image
  static String mtgCardImage(String cardId, {String context = 'default'}) {
    return 'mtg_${context}_img_$cardId';
  }
  
  /// Creates a hero tag for any card type based on whether it's an MTG card or not
  /// 
  /// @param cardId The unique identifier of the card
  /// @param isMtgCard Whether the card is an MTG card or not
  /// @param context The source context where the card is displayed
  /// @return A unique hero tag for the card appropriate to its type
  static String cardImageByType(String cardId, {bool isMtgCard = false, String context = 'default'}) {
    return isMtgCard ? mtgCardImage(cardId, context: context) : cardImage(cardId, context: context);
  }
}
