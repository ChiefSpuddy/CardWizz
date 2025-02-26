import 'package:flutter/material.dart';
import '../../constants/sets.dart';
import '../../constants/japanese_sets.dart';
import '../../constants/mtg_sets.dart';
import '../../screens/search_screen.dart';
import '../../utils/image_utils.dart';

class SearchCategories extends StatelessWidget {
  final SearchMode searchMode;
  final Function(Map<String, dynamic>) onQuickSearch;

  const SearchCategories({
    Key? key,
    required this.searchMode,
    required this.onQuickSearch,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Define the eras based on search mode
    final sets = searchMode == SearchMode.eng
      ? [
          {'title': 'Latest Sets', 'sets': PokemonSets.scarletViolet},
          {'title': 'Sword & Shield', 'sets': PokemonSets.swordShield},
          {'title': 'Sun & Moon', 'sets': PokemonSets.sunMoon},
          {'title': 'XY Series', 'sets': PokemonSets.xy},
          {'title': 'Black & White', 'sets': PokemonSets.blackWhite},
          {'title': 'HeartGold SoulSilver', 'sets': PokemonSets.heartGoldSoulSilver},
          {'title': 'Diamond & Pearl', 'sets': PokemonSets.diamondPearl},
          {'title': 'EX Series', 'sets': PokemonSets.ex},
          {'title': 'e-Card Series', 'sets': PokemonSets.eCard},
          {'title': 'Classic WOTC', 'sets': PokemonSets.classic},
        ]
      : searchMode == SearchMode.jpn
      ? [
          {'title': 'Latest Sets', 'sets': JapaneseSets.scarletViolet},
          {'title': 'Sword & Shield', 'sets': JapaneseSets.swordShield},
        ]
      : [
          {'title': 'Standard Sets', 'sets': MtgSets.standard},
          {'title': 'Modern Sets', 'sets': MtgSets.modern},
          {'title': 'Legacy Sets', 'sets': MtgSets.legacy},
        ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sets.length,
      itemBuilder: (context, index) {
        final era = sets[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                era['title'] as String,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onBackground,
                ),
              ),
            ),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: (era['sets'] as Map<String, Map<String, dynamic>>).length,
                itemBuilder: (context, index) {
                  final set = (era['sets'] as Map<String, Map<String, dynamic>>)
                      .entries.toList()[index];
                  return _buildSetCard(
                    context,
                    {
                      'name': set.key,
                      'query': 'set.id:${set.value['code']}',
                      'icon': set.value['icon'],
                      'year': set.value['year'],
                      'logo': set.value['logo'],
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSetCard(BuildContext context, Map<String, dynamic> item) {
    final colorScheme = Theme.of(context).colorScheme;
    final query = item['query'] as String? ?? '';
    final isSetQuery = query.startsWith('set.id:');
    
    // Get logo URL based on query type
    String? logoUrl;
    if (item.containsKey('logo') && item['logo'] != null) {
      logoUrl = item['logo'] as String;
    } else if (isSetQuery) {
      final setCode = query.replaceAll('set.id:', '').trim();
      if (searchMode == SearchMode.mtg) {
        // Use Scryfall's CDN for MTG sets
        logoUrl = CardImageUtils.getMtgSetLogo(setCode);
      } else {
        logoUrl = CardImageUtils.getPokemonSetLogo(setCode);
      }
    }
    
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => onQuickSearch(item),
        child: Container(
          width: 100,
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (logoUrl != null)
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Show icon as background/fallback
                      Text(
                        item['icon'] ?? '📦',
                        style: const TextStyle(fontSize: 24, color: Colors.black26),
                      ),
                      // Try to load the logo on top with proper error handling
                      CardImageUtils.loadImage(
                        logoUrl,
                        fit: BoxFit.contain,
                        context: context,
                      ),
                    ],
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    item['icon'] ?? '📦',
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              if (item['name'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    item['name'] ?? '',
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
