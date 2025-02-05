class SearchTerms {
  static const List<SearchCategory> categories = [
    SearchCategory(
      name: 'Latest Sets',
      searches: [
        'set.id:swsh10',  // Astral Radiance
        'set.id:swsh9',   // Brilliant Stars
        'set.id:xy11',    // Steam Siege
        'set.id:sv4',     // Paradox Rift
        'set.id:sv3',     // Obsidian Flames
        'set.id:sv2',     // Paldea Evolved
        'set.id:sv5',     // 151
        'set.id:sv1',     // Scarlet & Violet
      ],
      icon: 'set',
    ),
    SearchCategory(
      name: 'Classic Sets',
      searches: [
        'set.id:base1',  // Base Set
        'set.id:base2',  // Jungle
        'set.id:base3',  // Fossil
        'set.id:base5',  // Team Rocket
        'set.id:gym1',   // Gym Heroes
        'set.id:gym2',   // Gym Challenge
      ],
      icon: 'classic',
    ),
    SearchCategory(
      name: 'Special Cards',
      searches: [
        'Special Illustration Rare',
        'Illustration Rare',
        'Art Rare',
        'Ancient Rare',
        'Ultra Rare',
      ],
      icon: 'special',
    ),
    SearchCategory(
      name: 'Popular',
      searches: [
        'Charizard',
        'Mewtwo',
        'Pikachu',
        'Mew',
        'Rayquaza',
      ],
      icon: 'popular',
    ),
  ];
}

class SearchCategory {
  final String name;
  final List<String> searches;
  final String icon;

  const SearchCategory({
    required this.name,
    required this.searches,
    this.icon = 'default',
  });
}
