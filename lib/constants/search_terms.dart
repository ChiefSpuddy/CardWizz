class SearchTerms {
  static const List<SearchCategory> categories = [
    SearchCategory(
      name: 'Latest Sets',
      searches: [
        'Paradox Rift',
        'Obsidian Flames',
        'Paldea Evolved',
        '151',
        'Scarlet & Violet',
      ],
      icon: 'set',
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
