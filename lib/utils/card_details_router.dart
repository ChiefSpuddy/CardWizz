import 'package:flutter/material.dart';
import '../models/tcg_card.dart';
import '../screens/mtg_card_details_screen.dart';
import '../screens/pokemon_card_details_screen.dart';
import 'package:provider/provider.dart'; // Add this import
import '../services/storage_service.dart'; // Add this import
import '../providers/app_state.dart'; // Add this import
import '../utils/bottom_toast.dart'; // Add this import

class CardDetailsRouter {
  /// Routes to the appropriate card details screen based on card type
  static Widget getDetailsScreen({
    required TcgCard card,
    String heroContext = 'details',
    bool isFromBinder = false,
    bool isFromCollection = false,
  }) {
    // Check if this is an MTG card with improved detection
    final isMtgCard = _isMtgCard(card);
    print("Card ${card.name} detected as ${isMtgCard ? 'MTG' : 'Pokemon'} card");
    
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
    print("Evaluating card type for: ${card.name} (set: ${card.setName ?? 'Unknown'}, id: ${card.set.id})");
    
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
      print("Card belongs to a known Pokemon set: ${card.set.id}");
      return false;
    }
    
    // Check explicit flag first - highest priority
    if (card.isMtg != null) {
      // Override for Pokemon-specific sets that might be marked incorrectly
      if (card.set.id.startsWith('swsh') || 
          card.set.id.startsWith('sv') || 
          card.set.id.startsWith('sm')) {
        print("Overriding isMtg flag for Pokemon set");
        return false;
      }
      
      print("Card has explicit isMtg flag: ${card.isMtg}");
      return card.isMtg!;
    }
    
    // Check ID pattern - very reliable
    if (card.id.startsWith('mtg_')) {
      print("Card ID starts with 'mtg_', detecting as MTG");
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
        print("Set ID starts with known Pokemon prefix '$prefix', detecting as Pokemon");
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
        print("Set name contains Pokemon term '$term', detecting as Pokemon");
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
        print("Set name contains MTG term '$term', detecting as MTG");
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
        print("Card name contains Pokemon character '$name', detecting as Pokemon");
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
      print("Card name has Pokemon card type suffix (ex, gx, v, vmax, vstar), detecting as Pokemon");
      return false;
    }
    
    // Check image URL for hints
    if (card.imageUrl.contains('scryfall') || 
        card.imageUrl.contains('gatherer.wizards.com')) {
      print("Image URL contains MTG source, detecting as MTG");
      return true;
    }
    
    // Check for Pokemon image URLs
    if (card.imageUrl.toLowerCase().contains('pokemon')) {
      print("Image URL contains 'pokemon', detecting as Pokemon");
      return false;
    }
    
    // If all else fails, cards with sv or swsh in the set ID are Pokemon
    if (card.set.id.contains('swsh') || card.set.id.contains('sv')) {
      print("Set ID contains 'swsh' or 'sv', definitely Pokemon: ${card.set.id}");
      return false;
    }
    
    // If the set ID is 3 or fewer characters, it's likely MTG 
    // (unless it's one of the exceptions we already checked)
    if (card.set.id.length <= 3) {
      print("Set ID is 3 or fewer chars, likely MTG: ${card.set.id}");
      return true;
    }
    
    // Default - assume Pokemon for safety
    print("Using default detection: Pokemon");
    return false;
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

// Find the _onAddToCollection method in this file and update it to use bottomToast
/// Helper method to add a card to collection and show a toast notification
Future<void> onAddToCollection(BuildContext context, TcgCard card) async {
  final appState = Provider.of<AppState>(context, listen: false);
  final storageService = Provider.of<StorageService>(context, listen: false);

  try {
    // Save card
    await storageService.saveCard(card);
    
    // Notify app state about the change
    appState.notifyCardChange();
    
    // Use the bottom toast implementation
    showBottomToast(
      context: context,
      title: 'Added to Collection',
      message: '${card.name}',
      icon: Icons.check_circle,
    );
  } catch (e) {
    // Show error toast from bottom
    showBottomToast(
      context: context,
      title: 'Error',
      message: 'Failed to add card: $e',
      icon: Icons.error_outline,
      isError: true,
    );
  }
}
