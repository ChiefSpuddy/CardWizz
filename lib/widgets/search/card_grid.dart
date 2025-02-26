import 'package:flutter/material.dart';
import '../../models/tcg_card.dart';
import '../../screens/card_details_screen.dart';
import '../../widgets/card_grid_item.dart';

class CardSearchGrid extends StatelessWidget {
  final List<TcgCard> cards;
  final Map<String, Image> imageCache;
  final Function(String) loadImage;
  final Set<String> loadingRequestedUrls;

  const CardSearchGrid({
    Key? key,
    required this.cards,
    required this.imageCache,
    required this.loadImage,
    required this.loadingRequestedUrls,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.58,
          crossAxisSpacing: 8,
          mainAxisSpacing: 16,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildCardGridItem(context, cards[index]),
          childCount: cards.length,
        ),
      ),
    );
  }

  Widget _buildCardGridItem(BuildContext context, TcgCard card) {
    final String url = card.imageUrl;
  
    if (!loadingRequestedUrls.contains(url) && 
        !imageCache.containsKey(url)) {
      // Delay image loading slightly to prevent too many concurrent requests
      Future.microtask(() => loadImage(url));
    }

    final cachedImage = imageCache[url];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: CardGridItem(
                key: ValueKey(card.id),
                card: card,
                cached: cachedImage,
                heroContext: 'search',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CardDetailsScreen(
                      card: card,
                      heroContext: 'search',
                    ),
                  ),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.only(top: 6, bottom: 6, left: 2, right: 2),
            height: card.name.length > 20 ? 42 : 32,
            child: Text(
              card.name,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
