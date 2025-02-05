class PokemonSets {
  static const Map<String, String> setIds = {
    'Crown Zenith': 'swsh12pt5',
    'Silver Tempest': 'swsh12',
    'Paradox Rift': 'sv4',
    'Obsidian Flames': 'sv3',
    'Paldea Evolved': 'sv2',
    '151': 'sv3pt5',
    'Scarlet & Violet': 'sv1',
  };

  static const List<Map<String, String>> rarityFilters = [
    {'name': 'All Sets', 'code': '', 'icon': '🔍'},
    {'name': 'Crown Zenith', 'code': 'set.id:swsh12pt5', 'icon': '👑'},
    {'name': 'Silver Tempest', 'code': 'set.id:swsh12', 'icon': '⚡'},
    {'name': 'Paradox Rift', 'code': 'set.id:sv4', 'icon': '🌀'},
    {'name': 'Obsidian Flames', 'code': 'set.id:sv3', 'icon': '🔥'},
    {'name': 'Temporal Forces', 'code': 'set.id:sv3p5', 'icon': '⏳'},
  ];

  static const Map<String, Map<String, String>> setQueries = {
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
    // Recent Sword & Shield Sets
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
    // Sun & Moon Era
    'Ultra Prism': {'code': 'sm5', 'year': '2018', 'icon': '💠'},
    'Burning Shadows': {'code': 'sm3', 'year': '2017', 'icon': '🔥'},
    'Guardians Rising': {'code': 'sm2', 'year': '2017', 'icon': '🛡️'},
    'Sun & Moon Base': {'code': 'sm1', 'year': '2017', 'icon': '☀️'},
    'Team Up': {'code': 'sm9', 'year': '2019', 'icon': '🤝'},
    'Lost Thunder': {'code': 'sm8', 'year': '2018', 'icon': '⚡'},
    'Dragon Majesty': {'code': 'sm75', 'year': '2018', 'icon': '🐉'},
    'Celestial Storm': {'code': 'sm7', 'year': '2018', 'icon': '🌟'},
    'Forbidden Light': {'code': 'sm6', 'year': '2018', 'icon': '✨'},
    'Crimson Invasion': {'code': 'sm4', 'year': '2017', 'icon': '👾'},
    'Shining Legends': {'code': 'sm35', 'year': '2017', 'icon': '💫'},
    'Unified Minds': {'code': 'sm11', 'year': '2019', 'icon': '🧠'},
    'Unbroken Bonds': {'code': 'sm10', 'year': '2019', 'icon': '🔗'},
    'Cosmic Eclipse': {'code': 'sm12', 'year': '2019', 'icon': '🌌'},
    'Hidden Fates': {'code': 'sm115', 'year': '2019', 'icon': '🎯'},
    'XY Base Set': {'code': 'xy1', 'year': '2013', 'icon': '⚔️'},
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
    {'name': 'Umbreon', 'icon': '🌙'},  // Added Moonbreon back
    {'name': 'Pikachu', 'icon': '⚡'},
    {'name': 'Mew', 'icon': '✨'},
    {'name': 'Mewtwo', 'icon': '🔮'},
    {'name': 'Lugia', 'icon': '🌊'},
    {'name': 'Rayquaza', 'icon': '🐉'},
  ];

  static const Map<String, String> setAliases = {
    'astral radiance': 'swsh10',
    'brilliant stars': 'swsh9',
    'steam siege': 'xy11',
    'crown zenith': 'swsh12pt5',
    'silver tempest': 'swsh12',
    'temporal forces': 'sv3p5',
    // Add more aliases as needed
  };

  static String? getSetId(String searchTerm) {
    // First try direct match in setIds
    final directMatch = setIds[searchTerm];
    if (directMatch != null) return directMatch;

    // Then try aliases (case insensitive)
    final normalizedSearch = searchTerm.toLowerCase();
    return setAliases[normalizedSearch];
  }
}
