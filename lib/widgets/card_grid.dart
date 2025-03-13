import 'package:flutter/material.dart';
import '../widgets/card_grid_item.dart';

class CardGrid extends StatefulWidget {
  final List<TcgCard> cards;
  final Function(TcgCard)? onCardTap;
  final String? heroContext;
  final bool showPrices;

  const CardGrid({
    super.key,
    required this.cards,
    this.onCardTap,
    this.heroContext,
    this.showPrices = true,
  });

  @override
  State<CardGrid> createState() => _CardGridState();
}

class _CardGridState extends State<CardGrid> {
  final ScrollController _scrollController = ScrollController();
  bool _isLowQualityMode = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    // Detect fast scrolling and enable low quality mode
    if (_scrollController.position.isScrollingNotifier.value) {
      final velocity = _scrollController.position.activity?.velocity ?? 0;

      if (velocity.abs() > 1500 && !_isLowQualityMode) {
        setState(() => _isLowQualityMode = true);
      } else if (velocity.abs() < 300 && _isLowQualityMode) {
        setState(() => _isLowQualityMode = false);
      }
    } else if (_isLowQualityMode) {
      setState(() => _isLowQualityMode = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.cards.isEmpty
        ? const Center(child: Text('No cards found'))
        : GridView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: widget.cards.length,
            itemBuilder: (context, index) {
              final card = widget.cards[index];
              return Hero(
                tag: '${widget.heroContext ?? "grid"}_${card.id}',
                child: CardGridItem(
                  card: card,
                  onTap: widget.onCardTap != null
                      ? () => widget.onCardTap!(card)
                      : null,
                  showPrice: widget.showPrices,
                  highQuality: !_isLowQualityMode,
                  heroContext: widget.heroContext,
                ),
              );
            },
          );
  }
}
