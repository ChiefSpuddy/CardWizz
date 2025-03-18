import 'package:flutter/material.dart';
import '../screens/mtg_card_details_screen.dart';
import '../screens/pokemon_card_details_screen.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../providers/app_state.dart';
import '../utils/notification_manager.dart';
import '../services/price_service.dart';
import '../services/logging_service.dart';
import 'dart:math';  // Add this import for min
import '../models/tcg_card.dart';  // Add this import for TcgCard
import '../services/tcg_api_service.dart';

class CardDetailsRouter {
  // Static instance of the price service
  static final PriceService _priceService = PriceService();
  
  /// Routes to the appropriate card details screen based on card type
  static Widget getDetailsScreen({
    required TcgCard card,
    String heroContext = 'details',
    bool isFromBinder = false,
    bool isFromCollection = false,
    Widget? marketActionButtons, // Keep this parameter for backward compatibility
  }) {
    // Check if this is an MTG card with improved detection
    final isMtgCard = _isMtgCard(card);
    LoggingService.log("Card ${card.name} detected as ${isMtgCard ? 'MTG' : 'Pokemon'} card");
    
    if (isMtgCard) {
      return MtgCardDetailsScreen(
        card: card,
        heroContext: heroContext,
        isFromBinder: isFromBinder,
        isFromCollection: isFromCollection,
      );
    } else {
      return PokemonCardDetailsScreen(
        card: card,
        heroContext: heroContext,
        isFromBinder: isFromBinder,
        isFromCollection: isFromCollection,
      );
    }
  }
  
  /// Helper method to determine if a card is MTG
  static bool _isMtgCard(TcgCard card) {
    // Force explicit log for debugging
    LoggingService.log("Evaluating card type for: ${card.name} (set: ${card.setName ?? 'Unknown'}, id: ${card.set.id})");
    
    // Known Pokemon sets that were wrongly classified
    const knownPokemonSets = {
      'swsh6', 'swsh6-201', 'swsh12', 'sv1', 'sv2', 'sv3', 'sv4',
      'sv5', 'sv6', 'sv7', 'sv8', 'sv9', 'sv10', 'sv11', 'sv12',
      'sv8pt5', 'sv9pt5', 'swsh1', 'swsh2', 'swsh3', 'swsh4', 'swsh5', 
      'swsh7', 'swsh8', 'swsh9', 'swsh10', 'swsh11',
      'sm1', 'sm2', 'sm3', 'sm4', 'sm5', 'sm6', 'sm7', 'sm8', 'sm9', 'sm10', 'sm11', 'sm12'
    };
    
    // Check if this is a known Pokemon set
    if (knownPokemonSets.contains(card.set.id)) {
      LoggingService.log("Card belongs to a known Pokemon set: ${card.set.id}");
      return false;
    }
    
    // Check explicit flag first - highest priority
    if (card.isMtg != null) {
      // Override for Pokemon-specific sets that might be marked incorrectly
      if (card.set.id.startsWith('swsh') || 
          card.set.id.startsWith('sv') || 
          card.set.id.startsWith('sm')) {
        LoggingService.log("Overriding isMtg flag for Pokemon set");
        return false;
      }
      
      LoggingService.log("Card has explicit isMtg flag: ${card.isMtg}");
      return card.isMtg!;
    }
    
    // Check ID pattern - very reliable
    if (card.id.startsWith('mtg_')) {
      LoggingService.log("Card ID starts with 'mtg_', detecting as MTG");
      return true;
    }
    
    // These set ID prefixes definitely identify Pokemon cards
    const pokemonSetPrefixes = [
      'sv', 'swsh', 'sm', 'xy', 'bw', 'dp', 'cel', 'cel25', 'pgo', 'svp',
      'sv8', 'sv8pt5', 'sv9', 'sv9pt5', 'sv10', 'sv11',
    ];
    
    // Check for Pokemon set ID prefixes
    for (final prefix in pokemonSetPrefixes) {
      if (card.set.id.toLowerCase().startsWith(prefix)) {
        LoggingService.log("Set ID starts with known Pokemon prefix '$prefix', detecting as Pokemon");
        return false; // Definitely Pokemon
      }
    }
    
    // Check for Pokemon set names
    const pokemonSetNames = [
      'scarlet', 'violet', 'astral', 'brilliant', 'fusion', 'evolving',
      'chilling', 'battle', 'darkness', 'rebel', 'champion', 'vivid',
      'sword', 'shield', 'sun', 'moon', 'team up', 'unbroken',
      'unified', 'lost origin', 'silver tempest', 'crown zenith',
      'paldea', 'obsidian', 'temporal', 'paradox', 'prismatic',
      'surging', 'sparks', 'burning', 'chilling reign'
    ];
    
    // Check if the set name contains a Pokemon set term
    final setNameLower = (card.setName ?? '').toLowerCase();
    for (final term in pokemonSetNames) {
      if (setNameLower.contains(term)) {
        LoggingService.log("Set name contains Pokemon term '$term', detecting as Pokemon");
        return false; // Pokemon set
      }
    }
    
    // Check MTG set naming patterns
    const mtgSetNames = [
      'magic', 'dominaria', 'innistrad', 'ravnica', 
      'zendikar', 'commander', 'modern', 'throne', 
      'kamigawa', 'ikoria', 'eldraine', 'phyrexia', 
      'brawl', 'horizon', 'strixhaven', 'kaldheim', 
      'capenna', 'brothers', 'karlov', 'urza', 
      'mirrodin', 'theros', 'amonkhet', 'ixalan'
    ];
    
    // Check for MTG set names
    for (final term in mtgSetNames) {
      if (setNameLower.contains(term)) {
        LoggingService.log("Set name contains MTG term '$term', detecting as MTG");
        return true; // MTG set
      }
    }
    
    // Check for Pokemon-specific card names
    final nameLower = card.name.toLowerCase();
    const pokemonNames = [
      'pikachu', 'charizard', 'mewtwo', 'mew', 'eevee', 'bulbasaur',
      'squirtle', 'charmander', 'greninja', 'rayquaza', 'gengar',
      'lucario', 'jigglypuff', 'snorlax', 'garchomp', 'gardevoir',
      'darkrai', 'umbreon', 'sylveon', 'arceus', 'scyther',
      'meowth', 'gyarados', 'blastoise', 'venusaur'
    ];
    
    // Check for Pokemon character names
    for (final name in pokemonNames) {
      if (nameLower.contains(name)) {
        LoggingService.log("Card name contains Pokemon character '$name', detecting as Pokemon");
        return false; // Contains Pokemon name
      }
    }
    
    // Check for typical Pokemon card type indicators
    if (nameLower.contains(' ex') || 
        nameLower.endsWith(' ex') || 
        nameLower.contains(' gx') || 
        nameLower.contains(' v ') ||
        nameLower.contains(' v-') || 
        nameLower.endsWith(' v') || 
        nameLower.contains(' vmax') || 
        nameLower.contains(' vstar')) {
      LoggingService.log("Card name has Pokemon card type suffix (ex, gx, v, vmax, vstar), detecting as Pokemon");
      return false;
    }
    
    // Check image URL for hints
    if (card.imageUrl?.contains('scryfall') == true || 
        card.imageUrl?.contains('gatherer.wizards.com') == true) {
      LoggingService.log("Image URL contains MTG source, detecting as MTG");
      return true;
    }
    
    // Check for Pokemon image URLs
    if (card.imageUrl?.toLowerCase().contains('pokemon') == true) {
      LoggingService.log("Image URL contains 'pokemon', detecting as Pokemon");
      return false;
    }
    
    // If all else fails, cards with sv or swsh in the set ID are Pokemon
    if (card.set.id.contains('swsh') || card.set.id.contains('sv')) {
      LoggingService.log("Set ID contains 'swsh' or 'sv', definitely Pokemon: ${card.set.id}");
      return false;
    }
    
    // If the set ID is 3 or fewer characters, it's likely MTG 
    // (unless it's one of the exceptions we already checked)
    if (card.set.id.length <= 3) {
      LoggingService.log("Set ID is 3 or fewer chars, likely MTG: ${card.set.id}");
      return true;
    }
    
    // Default - assume Pokemon for safety
    LoggingService.log("Using default detection: Pokemon");
    return false;
  }
  
  /// Get the most accurate price for a card using eBay sold data when available
  static Future<double?> getAccuratePrice(TcgCard card, {bool includeGraded = false}) async {
    return await _priceService.getAccuratePrice(card, includeGraded: includeGraded);
  }
  
  /// Get detailed price information including source and confidence
  static Future<PriceResult> getPriceData(TcgCard card, {bool includeGraded = false}) async {
    return await _priceService.getPriceData(card, includeGraded: includeGraded);
  }
  
  /// Get comprehensive price data including graded and raw prices
  static Future<ComprehensivePriceData> getComprehensivePriceData(TcgCard card) async {
    return await _priceService.getComprehensivePriceData(card);
  }
  
  /// Get price for raw (ungraded) cards only
  static Future<double?> getRawCardPrice(TcgCard card) async {
    // If price is already null, return null right away
    if (card.price == null) return null;

    try {
      // First try to get the raw eBay price
      if (card.ebayPrice != null && card.ebayPrice! > 0) {
        return card.ebayPrice;
      }
      
      // If no eBay price available, fetch latest pricing from API
      final api = TcgApiService();
      // Change to nullable type with type check
      final Map<String, dynamic>? latestData = await api.getCardById(card.id);
      
      // Only proceed if we have valid data
      if (latestData != null && latestData.isNotEmpty) {
        // Try to get eBay price from the updated data
        final latestCard = TcgCard.fromJson(latestData);
        if (latestCard.ebayPrice != null && latestCard.ebayPrice! > 0) {
          return latestCard.ebayPrice;
        }
        
        // Safely handle tcgplayer prices with null checks
        final tcgplayer = latestData['tcgplayer'];
        if (tcgplayer != null && tcgplayer is Map<String, dynamic>) {
          final prices = tcgplayer['prices'];
          if (prices != null && prices is Map<String, dynamic>) {
            // Try to get holofoil price first
            final holofoil = prices['holofoil'];
            if (holofoil != null && holofoil is Map<String, dynamic> && holofoil['market'] != null) {
              final market = holofoil['market'];
              if (market is num) return market.toDouble();
            }
            
            // Try normal price
            final normal = prices['normal'];
            if (normal != null && normal is Map<String, dynamic> && normal['market'] != null) {
              final market = normal['market'];
              if (market is num) return market.toDouble();
            }
            
            // Try any other price types
            for (final priceType in prices.values) {
              if (priceType is Map<String, dynamic> && priceType['market'] != null) {
                final market = priceType['market'];
                if (market is num) return market.toDouble();
              }
            }
          }
        }
        
        // Safely handle cardmarket price with null checks
        final cardmarket = latestData['cardmarket'];
        if (cardmarket != null && cardmarket is Map<String, dynamic>) {
          final prices = cardmarket['prices'];
          if (prices != null && prices is Map<String, dynamic>) {
            final avgPrice = prices['averageSellPrice'];
            if (avgPrice is num) return avgPrice.toDouble();
          }
        }
      }
    } catch (e) {
      // If there's any error, return the original price
      print('Error getting raw card price: $e');
    }
    
    // Return the original price if all other attempts fail
    return card.price;
  }
  
  // Update or add this method to ensure consistent calculation
  static Future<double> calculateRawTotalValue(List<TcgCard> cards) async {
    // If there are no cards, return 0
    if (cards.isEmpty) return 0.0;
    
    // Use a more efficient approach for large collections
    double totalValue = 0.0;
    
    // Process cards in batches to avoid overloading async queue
    const int batchSize = 20;
    for (int i = 0; i < cards.length; i += batchSize) {
      final batch = cards.sublist(i, min(i + batchSize, cards.length));
      final futures = batch.map((card) => getRawCardPrice(card));
      final results = await Future.wait(futures);
      
      for (final price in results) {
        if (price != null) {
          totalValue += price;
        }
      }
    }
    
    return totalValue;
  }
  
  /// Navigate to the appropriate card details screen
  static void navigateToCardDetails(
    BuildContext context, 
    TcgCard card, {
    String heroContext = 'details',
    bool isFromBinder = false,
    bool isFromCollection = false,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => getDetailsScreen(
          card: card,
          heroContext: heroContext,
          isFromBinder: isFromBinder,
          isFromCollection: isFromCollection,
        ),
      ),
    );
  }
}

/// Helper method to add a card to collection and show a toast notification
Future<void> onAddToCollection(BuildContext context, TcgCard card) async {
  final appState = Provider.of<AppState>(context, listen: false);
  final storageService = Provider.of<StorageService>(context, listen: false);

  try {
    // Update price with the most accurate raw card price data
    final accuratePrice = await CardDetailsRouter.getRawCardPrice(card);
    if (accuratePrice != null) {
      card = card.copyWith(price: accuratePrice);
    }
    
    // Save card
    await storageService.saveCard(card);
    
    // Notify app state about the change
    appState.notifyCardChange();
    
    // Set position to bottom for the notification
    NotificationManager.show(
      context,
      title: 'Added to Collection',
      message: '${card.name}',
      icon: Icons.check_circle,
      position: NotificationPosition.bottom,
    );
  } catch (e) {
    // Set position to bottom for the notification
    NotificationManager.show(
      context,
      title: 'Error',
      message: 'Failed to add card: $e',
      icon: Icons.error_outline,
      isError: true,
      position: NotificationPosition.bottom,
    );
  }
}
