import '../models/tcg_card.dart';
import 'dart:math';

class CardBattleStats {
  final double attackPower;
  final double defensePower;
  final double specialPower;
  final double speed;
  final String specialAbility;
  final String element;
  
  CardBattleStats({
    required this.attackPower,
    required this.defensePower,
    required this.specialPower,
    required this.speed,
    required this.specialAbility,
    required this.element,
  });
  
  // Update the fromCard method to accept nullable card
  static CardBattleStats fromCard(TcgCard? card) {
    if (card == null) {
      // Provide default values if card is null
      return CardBattleStats(
        attackPower: 10.0,
        defensePower: 10.0,
        specialPower: 10.0,
        speed: 10.0,
        specialAbility: 'Default Move',
        element: 'normal',
      );
    }
    
    // Get base value but normalize it to a reasonable range
    double baseValue = card.price ?? 10.0;
    
    // Normalize extremely high values using logarithmic scaling
    if (baseValue > 100) {
      // Use logarithmic scale for high values: log10(price) * 20
      baseValue = (log(baseValue) / log(10)) * 20;
    }
    
    // Cap the maximum value
    baseValue = min(baseValue, 50.0);
    
    // Ensure minimum value is reasonable
    baseValue = max(baseValue, 5.0);
    
    // Rest of the calculations based on normalized baseValue
    double attackPower = baseValue * 1.2;
    double defensePower = baseValue * 0.8;
    double specialPower = baseValue;
    double speed = baseValue * 0.7;
    
    // Apply other modifiers as before
    final rarity = card.rarity?.toLowerCase() ?? '';
    
    if (card.set.id.contains('base') || card.set.id.contains('fossil')) {
      defensePower *= 1.5; // Vintage boost
    }
    
    if (rarity.contains('holo') || rarity.contains('rare')) {
      specialPower *= 1.4;
    } else if (rarity.contains('secret') || rarity.contains('ultra')) {
      specialPower *= 1.8;
    }
    
    // Speed boosts for starter cards
    try {
      final cardNumStr = card.number ?? "0";
      final cardNum = int.tryParse(cardNumStr.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
      if (cardNum > 0 && cardNum < 15) {
        speed *= 1.3; // Starter boost
      }
    } catch (_) {}
    
    // Determine special ability and element as before
    String specialAbility = _determineSpecialAbility(card.name);
    String element = _determineElement(card.name, rarity);
    
    return CardBattleStats(
      attackPower: attackPower,
      defensePower: defensePower,
      specialPower: specialPower,
      speed: speed,
      specialAbility: specialAbility,
      element: element,
    );
  }
  
  static String _determineSpecialAbility(String name) {
    name = name.toLowerCase();
    
    if (name.contains('charizard') || name.contains('dragon')) {
      return 'Inferno';
    } else if (name.contains('pikachu') || name.contains('electric')) {
      return 'Lightning Strike';
    } else if (name.contains('blastoise') || name.contains('water')) {
      return 'Hydro Pump';
    } else if (name.contains('venusaur') || name.contains('grass')) {
      return 'Solar Beam';
    } else if (name.contains('mewtwo') || name.contains('psychic')) {
      return 'Mind Control';
    } else if (name.contains('dark') || name.contains('ghost')) {
      return 'Shadow Force';
    } else if (name.contains('metal') || name.contains('steel')) {
      return 'Iron Defense';
    } else if (name.contains('gx') || name.contains('ex')) {
      return 'Ultimate Power';
    } else if (name.contains('v') || name.contains('vmax')) {
      return 'Dynamax Cannon';
    }
    
    // Default abilities by first letter of name
    final firstLetter = name.isNotEmpty ? name[0] : 'a';
    final abilities = [
      'Power Surge', 'Flame Charge', 'Hydro Blast', 
      'Static Shock', 'Night Slash', 'Fairy Wind',
      'Ancient Power', 'Future Sight', 'Dragon Rage'
    ];
    
    // Select based on first letter
    int index = (firstLetter.codeUnitAt(0) % abilities.length);
    return abilities[index];
  }
  
  static String _determineElement(String name, String rarity) {
    name = name.toLowerCase();
    rarity = rarity.toLowerCase();
    
    if (name.contains('fire') || name.contains('flame') || name.contains('charizard')) {
      return 'fire';
    } else if (name.contains('water') || name.contains('aqua') || name.contains('blastoise')) {
      return 'water';
    } else if (name.contains('grass') || name.contains('leaf') || name.contains('venusaur')) {
      return 'grass';
    } else if (name.contains('electric') || name.contains('thunder') || name.contains('pikachu')) {
      return 'electric';
    } else if (name.contains('psychic') || name.contains('mind') || name.contains('mewtwo')) {
      return 'psychic';
    } else if (name.contains('dark') || name.contains('ghost') || name.contains('shadow')) {
      return 'dark';
    } else if (name.contains('metal') || name.contains('steel')) {
      return 'metal';
    } else if (name.contains('fairy')) {
      return 'fairy';
    } else if (name.contains('dragon')) {
      return 'dragon';
    }
    
    // If rarity contains a clue
    if (rarity.contains('holo') || rarity.contains('foil')) {
      return 'psychic'; // Holographics tend to be psychic or special types
    }
    
    // Default elements by first letter
    final firstLetter = name.isNotEmpty ? name[0] : 'a';
    final elements = [
      'normal', 'fire', 'water', 'electric', 'grass',
      'ice', 'fighting', 'poison', 'ground', 'flying', 
      'psychic', 'bug', 'rock', 'ghost', 'dragon',
      'dark', 'steel', 'fairy'
    ];
    
    int index = (firstLetter.codeUnitAt(0) % elements.length);
    return elements[index];
  }
  
  // Calculate elemental advantage
  double getElementalMultiplier(CardBattleStats opponent) {
    // Simplified type effectiveness system
    final Map<String, List<String>> strengths = {
      'fire': ['grass', 'bug', 'steel', 'ice'],
      'water': ['fire', 'ground', 'rock'],
      'electric': ['water', 'flying'],
      'grass': ['water', 'ground', 'rock'],
      'psychic': ['fighting', 'poison'],
      'dark': ['psychic', 'ghost'],
      'dragon': ['dragon'],
      'fairy': ['dark', 'dragon', 'fighting'],
      'fighting': ['normal', 'rock', 'steel', 'ice', 'dark'],
      'flying': ['grass', 'fighting', 'bug'],
      'poison': ['grass', 'fairy'],
      'ground': ['fire', 'electric', 'poison', 'rock', 'steel'],
      'rock': ['fire', 'flying', 'bug', 'ice'],
      'bug': ['grass', 'psychic', 'dark'],
      'ghost': ['psychic', 'ghost'],
      'steel': ['ice', 'rock', 'fairy'],
      'ice': ['grass', 'ground', 'flying', 'dragon'],
    };
    
    // Check for elemental advantage
    if (strengths.containsKey(this.element) && 
        strengths[this.element]!.contains(opponent.element)) {
      return 1.5; // Super effective!
    }
    
    // Check for elemental disadvantage
    if (strengths.containsKey(opponent.element) && 
        strengths[opponent.element]!.contains(this.element)) {
      return 0.7; // Not very effective...
    }
    
    // No special relationship
    return 1.0;
  }
}
