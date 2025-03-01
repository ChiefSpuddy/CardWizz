import 'package:flutter/material.dart';
import '../../models/tcg_card.dart';
import 'card_grid_item.dart';

class CardSearchGrid extends StatelessWidget {
  final List<TcgCard> cards;
  final Map<String, Image> imageCache;
  final Set<String> loadingRequestedUrls;
  final Function(String) loadImage;
  final Function(TcgCard) onCardTap;

  const CardSearchGrid({
    Key? key,
    required this.cards,
    required this.imageCache,
    required this.loadingRequestedUrls,
    required this.loadImage,
    required this.onCardTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use screen width to calculate the ideal card width
    final double screenWidth = MediaQuery.of(context).size.width;
    
    // Always use 3 columns for consistency, but adjust padding for different screen sizes
    final int crossAxisCount = 3;
    final double horizontalPadding = screenWidth > 600 ? 16.0 : 12.0;
    
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.68, // Optimal for card proportions
          mainAxisSpacing: 12,
          crossAxisSpacing: 8, // Reduced spacing between cards
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final card = cards[index];
            return CardGridItem(
              card: card,
              showPrice: true,
              showName: false, // Hide name to focus on visuals
              elevation: 3.0, // Higher elevation for better shadow
              borderRadius: 12.0, // Slightly reduced border radius
              onTap: () => onCardTap(card),
            );
          },
          childCount: cards.length,
        ),
      ),
    );
  }
}
