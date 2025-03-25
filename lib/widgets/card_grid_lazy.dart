import 'package:flutter/material.dart';
import '../models/tcg_card.dart';
import 'card_grid_item.dart';
import '../services/image_prefetch_service.dart';
import '../utils/notification_manager.dart';

/// A more efficient card grid that loads items lazily and prefetches images
class LazyCardGrid extends StatefulWidget {
  final List<TcgCard> cards;
  final Function(TcgCard card)? onCardTap;
  final bool Function(TcgCard card)? isInCollection;
  final String heroContext;
  final bool preventNavigationOnQuickAdd;
  final bool showPrice;
  final bool showName;
  final int crossAxisCount;
  final double childAspectRatio;
  final EdgeInsets padding;
  final String? currencySymbol;
  final ScrollPhysics? physics;
  final bool? scrollable;

  const LazyCardGrid({
    Key? key,
    required this.cards,
    this.onCardTap,
    this.isInCollection,
    this.heroContext = 'card_grid',
    this.preventNavigationOnQuickAdd = false,
    this.showPrice = false,
    this.showName = false,
    this.crossAxisCount = 2,
    this.childAspectRatio = 0.7,
    this.padding = const EdgeInsets.all(8.0),
    this.currencySymbol,
    this.physics,
    this.scrollable,
  }) : super(key: key);

  @override
  State<LazyCardGrid> createState() => _LazyCardGridState();
}

class _LazyCardGridState extends State<LazyCardGrid> {
  final _scrollController = ScrollController();
  final _prefetchService = ImagePrefetchService();
  int _currentLastIndex = 0;
  
  // Initial batch size - how many cards to render immediately
  final int _initialBatchSize = 12;
  
  // Additional batch size - how many cards to add each time
  final int _additionalBatchSize = 12;
  
  // Visible cards list - gradually increases as user scrolls
  late List<TcgCard> _visibleCards;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize with first batch of cards
    _visibleCards = widget.cards.take(_initialBatchSize).toList();
    _currentLastIndex = _visibleCards.length;
    
    // Prefetch images for better performance
    _prefetchService.prefetchCardImages(_visibleCards);
    
    // Set up scroll listener to load more cards when needed
    _scrollController.addListener(_onScroll);
  }
  
  @override
  void didUpdateWidget(LazyCardGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // If card list changes, update visible cards
    if (widget.cards != oldWidget.cards) {
      setState(() {
        _visibleCards = widget.cards.take(_initialBatchSize).toList();
        _currentLastIndex = _visibleCards.length;
      });
      
      // Prefetch images for new cards
      _prefetchService.prefetchCardImages(_visibleCards);
    }
  }
  
  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }
  
  // Load more cards when user scrolls near the bottom
  void _onScroll() {
    // Check if we're near the bottom of the scroll view
    if (_scrollController.position.pixels > 
        _scrollController.position.maxScrollExtent - 800) {
      _loadMoreCards();
    }
  }
  
  // Add more cards to the visible list
  void _loadMoreCards() {
    // Don't load more if we've already loaded everything
    if (_currentLastIndex >= widget.cards.length) return;
    
    // Calculate next batch of cards to add
    final nextBatch = widget.cards.skip(_currentLastIndex).take(_additionalBatchSize).toList();
    
    // If there are no more cards, don't update state
    if (nextBatch.isEmpty) return;
    
    setState(() {
      _visibleCards.addAll(nextBatch);
      _currentLastIndex += nextBatch.length;
    });
    
    // Prefetch images for new batch
    _prefetchService.prefetchCardImages(nextBatch);
  }
  
  // Handle quick add cards functionality
  void _onQuickAddCard(TcgCard card) {
    // Implement quick add functionality (same as original)
    // ...existing implementation...
    
    // Show notification
    NotificationManager.success(
      context,
      message: 'Added ${card.name} to collection',
      icon: Icons.add_circle_outline,
      preventNavigation: true,
      position: NotificationPosition.bottom,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    // Show progress indicator if we haven't loaded all cards
    final hasMoreCards = _currentLastIndex < widget.cards.length;
    
    return Column(
      children: [
        Expanded(
          child: GridView.builder(
            controller: _scrollController,
            physics: widget.scrollable == false
                ? const NeverScrollableScrollPhysics()
                : widget.physics ?? const AlwaysScrollableScrollPhysics(),
            padding: widget.padding,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: widget.crossAxisCount,
              childAspectRatio: widget.childAspectRatio,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _visibleCards.length + (hasMoreCards ? 1 : 0),
            itemBuilder: (context, index) {
              // If we're at the last item and there are more cards, show loading indicator
              if (index == _visibleCards.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              
              // Otherwise show card item wrapped in RepaintBoundary for performance
              final card = _visibleCards[index];
              return RepaintBoundary(
                child: CardGridItem(
                  card: card,
                  onCardTap: widget.onCardTap,
                  isInCollection: widget.isInCollection?.call(card) ?? false,
                  heroContext: '${widget.heroContext}_$index',
                  showPrice: widget.showPrice,
                  showName: widget.showName,
                  currencySymbol: widget.currencySymbol,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
