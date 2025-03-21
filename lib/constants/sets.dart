import 'package:flutter/material.dart';

class PokemonSets {
  // Map of set names to their IDs
  static const Map<String, String> setIdMap = {
    'prismatic evolution': 'sv8pt5',
    'lost origin': 'swsh11',
    'crown zenith': 'swsh12pt5',
    'silver tempest': 'swsh12',
    'vivid voltage': 'swsh4',
    'astral radiance': 'swsh10',
    'brilliant stars': 'swsh9',
    'steam siege': 'xy11',
    'temporal forces': 'sv3p5',
    'paradox rift': 'sv4',
    'obsidian flames': 'sv3',
    'paldea evolved': 'sv2',
    'base set': 'base1',
    'jungle': 'base2',
    'fossil': 'base3',
    // Add more sets as needed...
  };

  // Categories for UI organization
  static const List<Map<String, String>> rarity_categories = [
    {'name': 'All Sets', 'code': '', 'icon': '🔍'},
    {'name': 'Crown Zenith', 'code': 'set.id:swsh12pt5', 'icon': '👑'},
    {'name': 'Silver Tempest', 'code': 'set.id:swsh12', 'icon': '⚡'},
    {'name': 'Paradox Rift', 'code': 'set.id:sv4', 'icon': '🌀'},
    {'name': 'Obsidian Flames', 'code': 'set.id:sv3', 'icon': '🔥'},
    {'name': 'Temporal Forces', 'code': 'set.id:sv3p5', 'icon': '⏳'},
  ];

  static const Map<String, Map<String, String>> setQueries = {
    'Prismatic Evolution': {'query': 'set.id:sv8pt5', 'icon': '✨'},
    'Crown Zenith': {'query': 'set.id:swsh12pt5', 'icon': '👑'},
    '151': {'query': 'set.id:sv5', 'icon': '🎮'},
    'Silver Tempest': {'query': 'set.id:swsh12', 'icon': '⚡'},
    'Temporal Forces': {'query': 'set.id:sv3p5', 'icon': '⏳'},
    'Paradox Rift': {'query': 'set.id:sv4', 'icon': '🌀'},
    'Obsidian Flames': {'query': 'set.id:sv3', 'icon': '🔥'},
    'Paldea Evolved': {'query': 'set.id:sv2', 'icon': '🌟'},
    'Scarlet & Violet': {'query': 'set.id:sv1', 'icon': '⚔️'},
    'Astral Radiance': {'query': 'set.id:swsh10', 'icon': '🌟'},
    'Brilliant Stars': {'query': 'set.id:swsh9', 'icon': '💫'},
    'Steam Siege': {'query': 'set.id:xy11', 'icon': '🚂'},
    'Hidden Fates': {'query': 'set.id:sm115', 'icon': '🎯'},
    'Primal Clash': {'query': 'set.id:xy5', 'icon': '🌊'},
    'Phantom Forces': {'query': 'set.id:xy4', 'icon': '👻'},
    'Roaring Skies': {'query': 'set.id:xy6', 'icon': '🌪'},
    'Ancient Origins': {'query': 'set.id:xy7', 'icon': '🏺'},
    'BREAKpoint': {'query': 'set.id:xy9', 'icon': '💥'},
    'BREAKthrough': {'query': 'set.id:xy8', 'icon': '🔨'},
    'Evolutions': {'query': 'set.id:xy12', 'icon': '🧬'},
    'Fates Collide': {'query': 'set.id:xy10', 'icon': '🎲'},
    'Flashfire': {'query': 'set.id:xy2', 'icon': '🔥'},
    'Furious Fists': {'query': 'set.id:xy3', 'icon': '👊'},
    'Generations': {'query': 'set.id:g1', 'icon': '🌟'},
    'Team Rocket Returns': {'query': 'set.id:ex7', 'icon': '🚀'},
    'Lost Origin': {'query': 'set.id:swsh11', 'icon': '🌌'},
    'Vivid Voltage': {'query': 'set.id:swsh4', 'icon': '⚡'},
    'Fusion Strike': {'query': 'set.id:swsh8', 'icon': '🔄'},
    'Ultra Prism': {'query': 'set.id:sm5', 'icon': '💠'},
    'XY Base Set': {'query': 'set.id:xy1', 'icon': '⚔️'},
    'Sun & Moon Base': {'query': 'set.id:sm1', 'icon': '☀️'},
    'Pokemon GO': {'query': 'set.id:pgo', 'icon': '📱'},
    // Special card types
    'Delta Species': {
      'query': 'nationalPokedexNumbers:[1 TO 999] subtypes:"delta species"',
      'icon': '🔮',
      'description': 'Delta Species variant Pokemon'
    },
    'Ancient Pokemon': {
      'query': 'subtypes:ancient',
      'icon': '🗿',
      'description': 'Ancient variant Pokemon'
    },
    // Add more sets as needed...
  };

  static const vintageEra = {
    'Base Set': {'code': 'base1', 'year': '1999', 'icon': '📜'},
    'Jungle': {'code': 'base2', 'year': '1999', 'icon': '🌴'},
    'Fossil': {'code': 'base3', 'year': '1999', 'icon': '🦴'},
    'Team Rocket': {'code': 'base5', 'year': '2000', 'icon': '🚀'},
    'Gym Heroes': {'code': 'gym1', 'year': '2000', 'icon': '🏆'},
    'Gym Challenge': {'code': 'gym2', 'year': '2000', 'icon': '🥇'},
    'Neo Genesis': {'code': 'neo1', 'year': '2000', 'icon': '✨'},
    'Neo Discovery': {'code': 'neo2', 'year': '2001', 'icon': '🔍'},
    'Neo Revelation': {'code': 'neo3', 'year': '2001', 'icon': '📖'},
    'Neo Destiny': {'code': 'neo4', 'year': '2002', 'icon': '⭐'},
    // Add more vintage sets
    'Legendary Collection': {'code': 'base6', 'year': '2002', 'icon': '👑'},
    'Expedition Base Set': {'code': 'ecard1', 'year': '2002', 'icon': '🗺️'},
    'Aquapolis': {'code': 'ecard2', 'year': '2003', 'icon': '🌊'},
    'Skyridge': {'code': 'ecard3', 'year': '2003', 'icon': '🌅'},
    'Base Set 2': {'code': 'base4', 'year': '2000', 'icon': '2️⃣'},
    'Southern Islands': {'code': 'si1', 'year': '2001', 'icon': '🏝️'},
    'Black Star Promos': {'code': 'bsp', 'year': '1999', 'icon': '⭐'},
    // EX Series
    'Ruby & Sapphire': {'code': 'ex1', 'year': '2003', 'icon': '💎'},
    'Sandstorm': {'code': 'ex2', 'year': '2003', 'icon': '🏜️'},
    'Dragon': {'code': 'ex3', 'year': '2003', 'icon': '🐉'},
    'Team Magma vs Team Aqua': {'code': 'ex4', 'year': '2004', 'icon': '⚔️'},
    'Hidden Legends': {'code': 'ex5', 'year': '2004', 'icon': '🗿'},
    'FireRed & LeafGreen': {'code': 'ex6', 'year': '2004', 'icon': '🔥'},
    'Team Rocket Returns': {'code': 'ex7', 'year': '2004', 'icon': '🚀'},
    'Deoxys': {'code': 'ex8', 'year': '2005', 'icon': '🧬'},
    'Emerald': {'code': 'ex9', 'year': '2005', 'icon': '💚'},
    'Unseen Forces': {'code': 'ex10', 'year': '2005', 'icon': '👻'},
    'Delta Species': {'code': 'ex11', 'year': '2005', 'icon': '🔮'},
    'Legend Maker': {'code': 'ex12', 'year': '2006', 'icon': '📖'},
    'Holon Phantoms': {'code': 'ex13', 'year': '2006', 'icon': '🌌'},
    'Crystal Guardians': {'code': 'ex14', 'year': '2006', 'icon': '💎'},
    'Dragon Frontiers': {'code': 'ex15', 'year': '2006', 'icon': '🐲'},
    'Power Keepers': {'code': 'ex16', 'year': '2007', 'icon': '⚡'},
  };

  static const modernEra = {
    'Prismatic Evolution': {'code': 'sv8pt5', 'year': '2024', 'icon': '✨'},
    'Crown Zenith': {'code': 'swsh12pt5', 'year': '2023', 'icon': '👑'},
    'Silver Tempest': {'code': 'swsh12', 'year': '2022', 'icon': '🌪️'},
    'Lost Origin': {'code': 'swsh11', 'year': '2022', 'icon': '🌌'},
    'Pokemon GO': {'code': 'pgo', 'year': '2022', 'icon': '📱'},
    'Astral Radiance': {'code': 'swsh10', 'year': '2022', 'icon': '🌟'},
    'Brilliant Stars': {'code': 'swsh9', 'year': '2022', 'icon': '💫'},
    'Fusion Strike': {'code': 'swsh8', 'year': '2021', 'icon': '🔄'},
    'Celebrations': {'code': 'cel25', 'year': '2021', 'icon': '🎉'},
    // Scarlet & Violet Era
    'Scarlet & Violet': {'code': 'sv1', 'year': '2023', 'icon': '⚔️'},
    'Paldea Evolved': {'code': 'sv2', 'year': '2023', 'icon': '🌟'},
    'Obsidian Flames': {'code': 'sv3', 'year': '2023', 'icon': '🔥'},
    'Paradox Rift': {'code': 'sv4', 'year': '2023', 'icon': '🌀'},
    '151': {'code': 'sv5', 'year': '2023', 'icon': '🎮'},
  };

  static const scarletViolet = <String, Map<String, dynamic>>{
    'Prismatic Evolution': {'code': 'sv8pt5', 'year': '2024', 'icon': '💎'},
    'Surging Sparks': {'code': 'sv8', 'year': '2024', 'icon': '⚡'},
    'Stellar Crown': {'code': 'sv7', 'year': '2024', 'icon': '👑'},
    'Twilight Masquerade': {'code': 'sv6', 'year': '2024', 'icon': '🎭'}, // Fixed from sv6p5 to sv6
    'Temporal Forces': {'code': 'sv5', 'year': '2024', 'icon': '⌛'}, // Fixed code from sv6 to sv5
    'Paldean Fates': {'code': 'sv4pt5', 'year': '2024', 'icon': '🌟'},
    'Paradox Rift': {'code': 'sv4', 'year': '2023', 'icon': '🌀'},
    '151': {'code': 'sv3pt5', 'year': '2023', 'icon': '🎮'},
    'Obsidian Flames': {'code': 'sv3', 'year': '2023', 'icon': '🔥'},
    'Paldea Evolved': {'code': 'sv2', 'year': '2023', 'icon': '🌟'},
    'Scarlet & Violet': {'code': 'sv1', 'year': '2023', 'icon': '⚔️'},
  };

  static const swordShield = <String, Map<String, dynamic>>{
    'Crown Zenith': {'code': 'swsh12pt5', 'year': '2023', 'icon': '👑'},
    'Silver Tempest': {'code': 'swsh12', 'year': '2022', 'icon': '⚡'},
    'Lost Origin': {'code': 'swsh11', 'year': '2022', 'icon': '🌌'},
    'Pokemon GO': {'code': 'pgo', 'year': '2022', 'icon': '📱'},
    'Astral Radiance': {'code': 'swsh10', 'year': '2022', 'icon': '🌟'},
    'Brilliant Stars': {'code': 'swsh9', 'year': '2022', 'icon': '💫'},
    'Fusion Strike': {'code': 'swsh8', 'year': '2021', 'icon': '🔄'},
    'Celebrations': {'code': 'cel25', 'year': '2021', 'icon': '🎉'},
    'Evolving Skies': {'code': 'swsh7', 'year': '2021', 'icon': '🌤️'},
    'Chilling Reign': {'code': 'swsh6', 'year': '2021', 'icon': '❄️'},
    'Battle Styles': {'code': 'swsh5', 'year': '2021', 'icon': '⚔️'},
    'Shining Fates': {'code': 'swsh45', 'year': '2021', 'icon': '✨'},
    'Vivid Voltage': {'code': 'swsh4', 'year': '2020', 'icon': '⚡'},
    'Champions Path': {'code': 'swsh35', 'year': '2020', 'icon': '🏆'},
    'Darkness Ablaze': {'code': 'swsh3', 'year': '2020', 'icon': '🌑'},
    'Rebel Clash': {'code': 'swsh2', 'year': '2020', 'icon': '⚔️'},
    'Sword & Shield': {'code': 'swsh1', 'year': '2020', 'icon': '🛡️'},
  };

  static const sunMoon = <String, Map<String, dynamic>>{
    'Cosmic Eclipse': {'code': 'sm12', 'year': '2019', 'icon': '🌌'},
    'Hidden Fates': {'code': 'sm115', 'year': '2019', 'icon': '🎯'},
    'Unified Minds': {'code': 'sm11', 'year': '2019', 'icon': '🧠'},
    'Unbroken Bonds': {'code': 'sm10', 'year': '2019', 'icon': '🔗'},
    'Team Up': {'code': 'sm9', 'year': '2019', 'icon': '🤝'},
    'Lost Thunder': {'code': 'sm8', 'year': '2018', 'icon': '⚡'},
    'Dragon Majesty': {'code': 'sm75', 'year': '2018', 'icon': '🐉'},
    'Celestial Storm': {'code': 'sm7', 'year': '2018', 'icon': '🌟'},
    'Forbidden Light': {'code': 'sm6', 'year': '2018', 'icon': '✨'},
    'Ultra Prism': {'code': 'sm5', 'year': '2018', 'icon': '💠'},
    'Crimson Invasion': {'code': 'sm4', 'year': '2017', 'icon': '👾'},
    'Shining Legends': {'code': 'sm35', 'year': '2017', 'icon': '💫'},
    'Burning Shadows': {'code': 'sm3', 'year': '2017', 'icon': '🔥'},
    'Guardians Rising': {'code': 'sm2', 'year': '2017', 'icon': '🛡️'},
    'Sun & Moon': {'code': 'sm1', 'year': '2017', 'icon': '☀️'},
  };

  static const xy = <String, Map<String, dynamic>>{
    'XY Base Set': {'code': 'xy1', 'year': '2014', 'icon': '⚔️'},
    'Flashfire': {'code': 'xy2', 'year': '2014', 'icon': '🔥'},
    'Furious Fists': {'code': 'xy3', 'year': '2014', 'icon': '👊'},
    'Phantom Forces': {'code': 'xy4', 'year': '2014', 'icon': '👻'},
    'Primal Clash': {'code': 'xy5', 'year': '2015', 'icon': '🌊'},
    'Roaring Skies': {'code': 'xy6', 'year': '2015', 'icon': '🌪'},
    'Ancient Origins': {'code': 'xy7', 'year': '2015', 'icon': '🏺'},
    'BREAKthrough': {'code': 'xy8', 'year': '2015', 'icon': '💥'},
    'BREAKpoint': {'code': 'xy9', 'year': '2016', 'icon': '⚡'},
    'Fates Collide': {'code': 'xy10', 'year': '2016', 'icon': '🎲'},
    'Steam Siege': {'code': 'xy11', 'year': '2016', 'icon': '🚂'},
    'Evolutions': {'code': 'xy12', 'year': '2016', 'icon': '🧬'},
    'Generations': {'code': 'g1', 'year': '2016', 'icon': '🌟'},
  };

  static const blackWhite = <String, Map<String, dynamic>>{
    'Legendary Treasures': {'code': 'bw11', 'year': '2013', 'icon': '👑'},
    'Plasma Blast': {'code': 'bw10', 'year': '2013', 'icon': '🌊'},
    'Plasma Freeze': {'code': 'bw9', 'year': '2013', 'icon': '❄️'},
    'Plasma Storm': {'code': 'bw8', 'year': '2013', 'icon': '⚡'},
    'Boundaries Crossed': {'code': 'bw7', 'year': '2012', 'icon': '🌈'},
    'Dragons Exalted': {'code': 'bw6', 'year': '2012', 'icon': '🐉'},
    'Dark Explorers': {'code': 'bw5', 'year': '2012', 'icon': '🔦'},
    'Next Destinies': {'code': 'bw4', 'year': '2012', 'icon': '🎯'},
    'Noble Victories': {'code': 'bw3', 'year': '2011', 'icon': '🏆'},
    'Emerging Powers': {'code': 'bw2', 'year': '2011', 'icon': '💪'},
    'Black & White': {'code': 'bw1', 'year': '2011', 'icon': '⚫'},
  };

  static const heartGoldSoulSilver = <String, Map<String, dynamic>>{
    'Call of Legends': {'code': 'col1', 'year': '2011', 'icon': '📞'},
    'Triumphant': {'code': 'hgss4', 'year': '2010', 'icon': '🏆'},
    'Undaunted': {'code': 'hgss3', 'year': '2010', 'icon': '💪'},
    'Unleashed': {'code': 'hgss2', 'year': '2010', 'icon': '⚡'},
    'HeartGold & SoulSilver': {'code': 'hgss1', 'year': '2010', 'icon': '💛'},
  };

  static const diamondPearl = <String, Map<String, dynamic>>{
    'Arceus': {'code': 'pl4', 'year': '2009', 'icon': '🌟'},
    'Supreme Victors': {'code': 'pl3', 'year': '2009', 'icon': '🏆'},
    'Rising Rivals': {'code': 'pl2', 'year': '2009', 'icon': '⚔️'},
    'Platinum': {'code': 'pl1', 'year': '2009', 'icon': '💎'},
    'Stormfront': {'code': 'dp7', 'year': '2008', 'icon': '⛈️'},
    'Legends Awakened': {'code': 'dp6', 'year': '2008', 'icon': '👁️'},
    'Majestic Dawn': {'code': 'dp5', 'year': '2008', 'icon': '🌅'},
    'Great Encounters': {'code': 'dp4', 'year': '2008', 'icon': '🤝'},
    'Secret Wonders': {'code': 'dp3', 'year': '2007', 'icon': '✨'},
    'Mysterious Treasures': {'code': 'dp2', 'year': '2007', 'icon': '💎'},
    'Diamond & Pearl': {'code': 'dp1', 'year': '2007', 'icon': '💎'},
  };

  static const ex = <String, Map<String, dynamic>>{
    'Power Keepers': {'code': 'ex16', 'year': '2007', 'icon': '⚡'},
    'Dragon Frontiers': {'code': 'ex15', 'year': '2006', 'icon': '🐲'},
    'Crystal Guardians': {'code': 'ex14', 'year': '2006', 'icon': '💎'},
    'Holon Phantoms': {'code': 'ex13', 'year': '2006', 'icon': '🌌'},
    'Legend Maker': {'code': 'ex12', 'year': '2006', 'icon': '📖'},
    'Delta Species': {'code': 'ex11', 'year': '2005', 'icon': '🔮'},
    'Unseen Forces': {'code': 'ex10', 'year': '2005', 'icon': '👻'},
    'Emerald': {'code': 'ex9', 'year': '2005', 'icon': '💚'},
    'Deoxys': {'code': 'ex8', 'year': '2005', 'icon': '🧬'},
    'Team Rocket Returns': {'code': 'ex7', 'year': '2004', 'icon': '🚀'},
    'FireRed & LeafGreen': {'code': 'ex6', 'year': '2004', 'icon': '🔥'},
    'Hidden Legends': {'code': 'ex5', 'year': '2004', 'icon': '🗿'},
    'Team Magma vs Team Aqua': {'code': 'ex4', 'year': '2004', 'icon': '⚔️'},
    'Dragon': {'code': 'ex3', 'year': '2003', 'icon': '🐉'},
    'Sandstorm': {'code': 'ex2', 'year': '2003', 'icon': '🏜️'},
    'Ruby & Sapphire': {'code': 'ex1', 'year': '2003', 'icon': '💎'},
  };

  static const eCard = <String, Map<String, dynamic>>{
    'Skyridge': {'code': 'ecard3', 'year': '2003', 'icon': '🌅'},
    'Aquapolis': {'code': 'ecard2', 'year': '2003', 'icon': '🌊'},
    'Expedition Base Set': {'code': 'ecard1', 'year': '2002', 'icon': '🗺️'},
  };

  // Update classic sets to be in chronological order (oldest first)
  static const classic = <String, Map<String, dynamic>>{
    'Base Set': {'code': 'base1', 'year': '1999', 'icon': '📜'},
    'Jungle': {'code': 'base2', 'year': '1999', 'icon': '🌴'},
    'Fossil': {'code': 'base3', 'year': '1999', 'icon': '🦴'},
    'Base Set 2': {'code': 'base4', 'year': '2000', 'icon': '2️⃣'},
    'Team Rocket': {'code': 'base5', 'year': '2000', 'icon': '🚀'},
    'Gym Heroes': {'code': 'gym1', 'year': '2000', 'icon': '🏆'},
    'Gym Challenge': {'code': 'gym2', 'year': '2000', 'icon': '🥇'},
    'Neo Genesis': {'code': 'neo1', 'year': '2000', 'icon': '✨'},
    'Neo Discovery': {'code': 'neo2', 'year': '2001', 'icon': '🔍'},
    'Southern Islands': {'code': 'si1', 'year': '2001', 'icon': '🏝️'},
    'Neo Revelation': {'code': 'neo3', 'year': '2001', 'icon': '📖'},
    'Neo Destiny': {'code': 'neo4', 'year': '2002', 'icon': '⭐'},
    'Legendary Collection': {'code': 'base6', 'year': '2002', 'icon': '👑'},
  };

  static const promoSets = <String, Map<String, dynamic>>{
    'SWSH Black Star Promos': {'code': 'swshp', 'year': '2019-2023', 'icon': '⭐'},
    'SM Black Star Promos': {'code': 'smp', 'year': '2016-2019', 'icon': '⭐'},
    'XY Black Star Promos': {'code': 'xyp', 'year': '2013-2016', 'icon': '⭐'},
    'BW Black Star Promos': {'code': 'bwp', 'year': '2011-2013', 'icon': '⭐'},
    'HGSS Black Star Promos': {'code': 'hsp', 'year': '2010-2011', 'icon': '⭐'},
    'DP Black Star Promos': {'code': 'dpp', 'year': '2007-2010', 'icon': '⭐'},
    'POP Series Promos': {'code': 'pop', 'year': '2004-2009', 'icon': '⭐'},
    'Nintendo Black Star Promos': {'code': 'np', 'year': '2003-2006', 'icon': '⭐'},
    'Wizards Black Star Promos': {'code': 'bsp', 'year': '1999-2003', 'icon': '⭐'},
  };

  static const rarityFilters = [
    {'name': 'Holo Rare', 'icon': '✨', 'code': 'rarity:holo'},
    {'name': 'Ultra Rare', 'icon': '⭐', 'code': 'rarity:ultra'},
    {'name': 'Secret Rare', 'icon': '🌟', 'code': 'rarity:secret'},
    {'name': 'Alt Art', 'icon': '🎨', 'code': 'rarity:altart'},
    {'name': 'Full Art', 'icon': '🖼️', 'code': 'rarity:fullart'},
    {'name': 'Rainbow Rare', 'icon': '🌈', 'code': 'rarity:rainbow'},
  ];

  static const popularCards = [
    {'name': 'Charizard', 'icon': '🔥'},
    {'name': 'Umbreon', 'icon': '🌙'},
    {'name': 'Pikachu', 'icon': '⚡'},
    {'name': 'Mew', 'icon': '✨'},
    {'name': 'Mewtwo', 'icon': '🔮'},
    {'name': 'Lugia', 'icon': '🌊'},
    {'name': 'Rayquaza', 'icon': '🐉'},
  ];

  static const Map<String, String> setAliases = {
    'astral radiance': 'swsh10',
    'brilliant stars': 'swsh9',
    'steam siege': 'xy11',  // Keep only this instance
    'crown zenith': 'swsh12pt5',
    'silver tempest': 'swsh12',
    'temporal forces': 'sv3p5',
    'sword & shield': 'swsh1',
    'swsh': 'swsh1',
    'sword and shield': 'swsh1',
    'scarlet & violet': 'sv1',
    'sv': 'sv1', 
    'scarlet and violet': 'sv1',
    'pokemon 151': 'sv3pt5',
    '151': 'sv3pt5',
    'paldean fates': 'sv4pt5',
    'obsidian flames': 'sv3',
    'paradox rift': 'sv4',
    'paldea evolved': 'sv2',
    'vivid voltage': 'swsh4',
    'fusion strike': 'swsh8',
    'evolving skies': 'swsh7',
    'chilling reign': 'swsh6',
    'battle styles': 'swsh5',
    'shining fates': 'swsh45',
    'champions path': 'swsh35',
    'darkness ablaze': 'swsh3',
    'rebel clash': 'swsh2',
    'cosmic eclipse': 'sm12',
    'hidden fates': 'sm115',
    'unified minds': 'sm11',
    'unbroken bonds': 'sm10',
    'team up': 'sm9',
    'lost thunder': 'sm8',
    'celestial storm': 'sm7',
    'forbidden light': 'sm6',
    'ultra prism': 'sm5',
    'sun & moon': 'sm1',
    'sun and moon': 'sm1',
    'crimson invasion': 'sm4',
    'burning shadows': 'sm3',
    'guardians rising': 'sm2',
    'shining legends': 'sm35',
    'dragon majesty': 'sm75',
    'evolutions': 'xy12',
    // Removed duplicate 'steam siege': 'xy11' entry here
    'fates collide': 'xy10',
    'breakpoint': 'xy9',
    'breakthrough': 'xy8',
    'ancient origins': 'xy7',
    'roaring skies': 'xy6',
    'primal clash': 'xy5',
    'phantom forces': 'xy4',
    'furious fists': 'xy3',
    'flashfire': 'xy2',
    'xy': 'xy1',
    'xy base': 'xy1',
    'xy base set': 'xy1',
    // ...remaining existing code...
  };
  
  static String? getSetId(String searchTerm) {
    // Clean up the search term
    final normalizedSearch = searchTerm.toLowerCase().trim();
    
    // First try direct match in setIdMap
    final directMatch = setIdMap[normalizedSearch];
    if (directMatch != null) return directMatch;

    // Then try aliases (case insensitive)
    final aliasMatch = setAliases[normalizedSearch];
    if (aliasMatch != null) return aliasMatch;
    
    // Try partial matches if the term is long enough
    if (normalizedSearch.length >= 4) {
      // Check if any set name contains this search term
      for (final entry in setAliases.entries) {
        if (entry.key.contains(normalizedSearch) || normalizedSearch.contains(entry.key)) {
          return entry.value;
        }
      }
      
      // Check if any set ID contains this search term
      for (final entry in setIdMap.entries) {
        if (entry.key.contains(normalizedSearch) || normalizedSearch.contains(entry.key)) {
          return entry.value;
        }
      }
    }

    return null;
  }

  static Map<String, String> get allSetIds => setIdMap;

  static const rarities = [
    // Special Arts & Full Arts
    {
      'name': 'Special Illustration',
      'icon': '🎨',
      'query': 'rarity:"Special Illustration Rare"',
      'description': 'Special art cards'
    },
    {
      'name': 'Full Art',
      'icon': '🖼️',
      'query': 'subtypes:"Trainer Gallery" OR rarity:"Rare Ultra" -subtypes:VMAX',
      'description': 'Full art cards'
    },
    {
      'name': 'Ancient',
      'icon': '🗿',
      'query': 'subtypes:ancient',
      'description': 'Ancient variant cards'
    },

    // Ultra Rares - existing rarities...
    {'name': 'Secret Rare', 'icon': '🌟', 'query': 'rarity:"Rare Secret"'},
    {'name': 'Rainbow Rare', 'icon': '🌈', 'query': 'rarity:"Rare Rainbow"'},
    // ...rest of existing rarities...
  ];

  // Update _convertSetToSearchFormat to correctly handle logo URLs
  static List<Map<String, dynamic>> _convertSetToSearchFormat(Map<String, Map<String, dynamic>> sets) {
    return sets.entries.map((entry) {
      final code = entry.value['code'] as String;
      return {
        'name': entry.key,
        'query': 'set.id:$code',
        'icon': entry.value['icon'],
        'year': entry.value['year'] ?? entry.value['release'],
        'description': entry.value['description'] ?? '${entry.key} set',
        'logo': 'https://images.pokemontcg.io/$code/logo.png', // Ensure correct logo URL
      };
    }).toList();
  }

  // Update getSearchCategories to combine all eras
  static Map<String, List<Map<String, dynamic>>> getSearchCategories() {
    final Map<String, Map<String, Map<String, dynamic>>> allSets = {
      'latest': {
        ...scarletViolet,
        ...swordShield,
      },
      'modern': {
        ...sunMoon,
        ...xy,
      },
      'vintage': {
        ...classic,
        ...ex,
      },
      'promos': promoSets,
    };

    return {
      'latest': _convertSetToSearchFormat(allSets['latest']!),
      'modern': _convertSetToSearchFormat(allSets['modern']!),
      'vintage': _convertSetToSearchFormat(allSets['vintage']!),
      'promos': _convertSetToSearchFormat(allSets['promos']!),
      'special': rarities.where((r) => 
        r['name'] == 'Special Illustration' || 
        r['name'] == 'Ancient' ||
        r['name'] == 'Full Art'
      ).toList(),
      'popular': popularCards,
      'rarities': rarities,
    };
  }

  // Update setCategories to match new organization
  static const setCategories = {
    'latest': 'Latest Sets',
    'modern': 'Modern Era',
    'vintage': 'Classic Sets',
    'promos': 'Promo Sets',
    'special': 'Special Cards',
    'popular': 'Popular',
    'rarities': 'Card Rarities',
  };

  // Update section icons
  static const sectionIcons = {
    'latest': Icons.new_releases,
    'modern': Icons.history_edu,
    'vintage': Icons.auto_awesome,
    'promos': Icons.star,
    'special': Icons.stars,
    'popular': Icons.local_fire_department,
    'rarities': Icons.auto_awesome,
  };

  // Update getSetsForCategory to use new categories
  static List<Map<String, dynamic>> getSetsForCategory(String category) {
    final allSets = {
      'latest': {
        ...scarletViolet,
        ...swordShield,
      },
      'modern': {
        ...sunMoon,
        ...xy,
      },
      'vintage': {
        ...classic,
        ...ex,
      },
      'promos': promoSets,
    };

    if (allSets.containsKey(category)) {
      return _convertSetToSearchFormat(allSets[category]!);
    }

    switch (category) {
      case 'special':
        return rarities.where((r) => 
          r['name'] == 'Special Illustration' || 
          r['name'] == 'Ancient' ||
          r['name'] == 'Full Art'
        ).toList();
      case 'popular':
        return popularCards;
      case 'rarities':
        return rarities;
      default:
        return [];
    }
  }

  // Add method to get all categories
  static List<String> getAllCategories() {
    return setCategories.keys.toList();
  }

  // Update the getAllSets method to include all eras in chronological order
  static List<Map<String, dynamic>> getAllSets() {
    final Map<String, Map<String, dynamic>> allSets = {
      ...scarletViolet,
      ...swordShield,
      ...sunMoon,
      ...xy,
      ...blackWhite,
      ...heartGoldSoulSilver,
      ...diamondPearl,
      ...ex,
      ...eCard,
      ...classic,
    };
    return _convertSetToSearchFormat(allSets);
  }
}