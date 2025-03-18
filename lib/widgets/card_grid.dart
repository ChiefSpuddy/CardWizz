import 'package:flutter/material.dart';
import '../models/tcg_card.dart';
import 'card_grid_item.dart';

// Regular CardGrid for use in normal contexts
class CardGrid extends StatelessWidget {
  final List<TcgCard> cards;
  final Function(TcgCard) onCardTap;
  final bool isFromCollection;
  final bool preventNavigationOnQuickAdd;
  final bool showPrice;
  final bool showName;
  final String heroContext;
  final EdgeInsetsGeometry? padding;
  final String? currencySymbol;
  final int crossAxisCount;
  final double childAspectRatio;
  final bool scrollable;

  const CardGrid({
    Key? key,
    required this.cards,
    required this.onCardTap,
    this.isFromCollection = false,
    this.preventNavigationOnQuickAdd = false,
    this.showPrice = true,
    this.showName = false,
    this.heroContext = 'grid',
    this.padding,
    this.currencySymbol,
    this.crossAxisCount = 2,
    this.childAspectRatio = 0.72, // Adjusted for better proportions
    this.scrollable = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Widget> cardItems = _buildGridItems();
    
    if (scrollable) {
      // For standalone scrollable grid
      return GridView.builder(
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 10), // Adjusted paddingl padding
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          mainAxisSpacing: 10, // Reduced spacingfor more card space
          crossAxisSpacing: 8, // Reduced spacing for more card space card width
        ),
        itemCount: cards.length,
        itemBuilder: (context, index) => cardItems[index],
      );
    } else {
      // For non-scrollable embedded grid
      return _NonScrollableGrid(
        cards: cards,
        onCardTap: onCardTap,
        isFromCollection: isFromCollection,
        showPrice: showPrice,
        showName: showName,
        heroContext: heroContext,
        padding: padding,
        currencySymbol: currencySymbol,
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        preventNavigationOnQuickAdd: preventNavigationOnQuickAdd,
      );
    }
  }

  List<Widget> _buildGridItems() {
    return List.generate(
      cards.length,
      (index) {
        final card = cards[index];
        return CardGridItem(
          card: card,
          onCardTap: onCardTap,
          isInCollection: isFromCollection,
          heroContext: '${heroContext}_${index}',
          preventNavigationOnQuickAdd: preventNavigationOnQuickAdd,
          showPrice: showPrice,
          showName: showName,
          currencySymbol: currencySymbol,
        );
      },
    );
  }
}

// A separate widget that properly handles grid display without scrolling
class _NonScrollableGrid extends StatelessWidget {
  final List<TcgCard> cards;
  final Function(TcgCard) onCardTap;
  final bool isFromCollection;
  final bool preventNavigationOnQuickAdd;
  final bool showPrice;
  final bool showName;
  final String heroContext;
  final EdgeInsetsGeometry? padding;
  final String? currencySymbol;
  final int crossAxisCount;
  final double childAspectRatio;

  const _NonScrollableGrid({
    Key? key,
    required this.cards,
    required this.onCardTap,
    this.isFromCollection = false,
    this.preventNavigationOnQuickAdd = false,
    this.showPrice = true,
    this.showName = false,
    this.heroContext = 'grid',
    this.padding,
    this.currencySymbol,
    this.crossAxisCount = 2,
    this.childAspectRatio = 0.7,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 12),// Reduced padding
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate item width based on available width with minimal spacing
          final double itemWidth = (constraints.maxWidth - (crossAxisCount - 1) * 4) / crossAxisCount; // Reduced spacing
          // Calculate item height based on aspect ratio
          final double itemHeight = itemWidth / childAspectRatio;
          
          // Calculate number of rows needed
          final int itemCount = cards.length;
          final int rowCount = (itemCount / crossAxisCount).ceil();
          
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List.generate(rowCount, (rowIndex) {
              return Row(
                children: List.generate(crossAxisCount, (colIndex) {
                  final index = rowIndex * crossAxisCount + colIndex;
                  
                  // If we've run out of items, return an empty SizedBox
                  if (index >= itemCount) {
                    return Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: itemHeight,
                        child: const SizedBox(),
                      ),
                    );
                  }
                  
                  final card = cards[index];
                  
                  return Expanded(
                    flex: 1, 
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: colIndex < crossAxisCount - 1 ? 4 : 0, // Reduced spacing
                        bottom: rowIndex < rowCount - 1 ? 8 : 0,
                      ),
                      child: SizedBox(
                        height: itemHeight,
                        child: CardGridItem(
                          card: card,
                          onCardTap: onCardTap,
                          isInCollection: isFromCollection,
                          heroContext: '${heroContext}_${index}',
                          preventNavigationOnQuickAdd: preventNavigationOnQuickAdd,
                          showPrice: showPrice,
                          showName: showName,
                          currencySymbol: currencySymbol,
                        ),
                      ),
                    ),
                  );
                }),
              );
            }),
          );
        },
      ),
    );
  }
}

// A class specifically for CustomScrollView contexts
class CardGridSliver extends StatelessWidget {
  final List<TcgCard> cards;
  final Function(TcgCard) onCardTap;
  final bool isFromCollection;
  final bool preventNavigationOnQuickAdd;
  final bool showPrice;
  final bool showName;
  final String heroContext;
  final EdgeInsetsGeometry? padding;
  final String? currencySymbol;
  final int crossAxisCount;
  final double childAspectRatio;

  const CardGridSliver({
    Key? key,
    required this.cards,
    required this.onCardTap,
    this.isFromCollection = false,
    this.preventNavigationOnQuickAdd = false,
    this.showPrice = true,
    this.showName = false,
    this.heroContext = 'grid',
    this.padding,
    this.currencySymbol,
    this.crossAxisCount = 2,
    this.childAspectRatio = 0.7,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 6, vertical: 8), // Reduced padding
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio, // Fixed syntax error
          mainAxisSpacing: 8, // Reduced spacing
          crossAxisSpacing: 6, // Reduced spacing for more card space
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final card = cards[index];
            return CardGridItem(
              card: card,
              onCardTap: onCardTap,
              isInCollection: isFromCollection,
              heroContext: '${heroContext}_${index}',
              preventNavigationOnQuickAdd: preventNavigationOnQuickAdd,
              showPrice: showPrice,
              showName: showName,
              currencySymbol: currencySymbol,
            );
          },
          childCount: cards.length,
        ),
      ),
    );
  }
}
