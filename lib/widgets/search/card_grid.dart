import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async'; // Add this import for Timer
import '../../models/tcg_card.dart';
import '../../constants/app_colors.dart';
import '../../services/storage_service.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'card_grid_item.dart';
import '../../widgets/styled_toast.dart'; // Add this import for StyledToast
import '../../providers/currency_provider.dart';

class CardSearchGrid extends StatefulWidget {
  final List<TcgCard> cards;
  final Map<String, Image> imageCache;
  final Function(String) loadImage;
  final Set<String> loadingRequestedUrls;
  final Function(TcgCard) onCardTap;
  final Function(TcgCard)? onAddToCollection; // Add this line to make it optional

  const CardSearchGrid({
    Key? key,
    required this.cards,
    required this.imageCache,
    required this.loadImage,
    required this.loadingRequestedUrls,
    required this.onCardTap,
    this.onAddToCollection, // Add this optional parameter
  }) : super(key: key);

  @override
  State<CardSearchGrid> createState() => _CardSearchGridState();
}

class _CardSearchGridState extends State<CardSearchGrid> with AutomaticKeepAliveClientMixin {
  // Keep state alive when scrolling
  @override
  bool get wantKeepAlive => true;
  
  final Set<String> _requestedImages = {};
  bool _initialLoadStarted = false;

  // Track cards in collection
  Set<String> _collectionCardIds = {};
  StorageService? _storage;
  // Add timer for periodic refresh
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _initialLoadStarted = false;
    
    // Trigger immediate load instead of waiting for post-frame
    _preloadVisibleImages(immediate: true);
    
    // Also schedule for next frame as fallback
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _preloadVisibleImages();
      _loadCollectionStatus();
      
      // Set up periodic refresh of collection status (every 2 seconds)
      _refreshTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
        _loadCollectionStatus();
      });
    });
  }
  
  @override
  void didUpdateWidget(CardSearchGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    _initialLoadStarted = false;
    
    // If cards changed, immediately load images
    if (widget.cards != oldWidget.cards) {
      _preloadVisibleImages(immediate: true);
      
      // Also schedule for post-frame as fallback
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _preloadVisibleImages();
      });
    }
  }

  // New method to load collection status
  Future<void> _loadCollectionStatus() async {
    if (!mounted) return;
    
    try {
      if (_storage == null) {
        _storage = Provider.of<StorageService>(context, listen: false);
      }
      
      final cards = await _storage!.getCards();
      if (!mounted) return;
      
      setState(() {
        _collectionCardIds = cards.map((c) => c.id).toSet();
      });
    } catch (e) {
      print('Error loading collection status: $e');
    }
  }
  
  @override
  void dispose() {
    // Cancel the refresh timer
    _refreshTimer?.cancel();
    super.dispose();
  }

  // Load all visible images immediately
  void _preloadVisibleImages({bool immediate = false}) {
    if (!mounted || _initialLoadStarted) return;
    
    _initialLoadStarted = true;
    
    // Immediately trigger loading for ALL visible cards
    for (int i = 0; i < math.min(widget.cards.length, 30); i++) {
      final imageUrl = widget.cards[i].imageUrl;
      if (!_requestedImages.contains(imageUrl) && 
          !widget.imageCache.containsKey(imageUrl)) {
        if (immediate) {
          // Directly call loadImage for initial batch
          widget.loadImage(imageUrl);
        } else {
          // Use microtasks for subsequent batches to avoid blocking UI
          Future.microtask(() => widget.loadImage(imageUrl));
        }
        _requestedImages.add(imageUrl);
      }
    }
    
    // Pre-fetch the next batch in background
    for (int i = 30; i < math.min(widget.cards.length, 60); i++) {
      final imageUrl = widget.cards[i].imageUrl;
      if (!_requestedImages.contains(imageUrl) && 
          !widget.imageCache.containsKey(imageUrl)) {
        Future.microtask(() => widget.loadImage(imageUrl));
        _requestedImages.add(imageUrl);
      }
    }
  }

  // Fix the issue with adding cards and standardize toast notifications
  Future<void> _addToCollection(TcgCard card) async {
    if (_storage == null) return;
    
    try {
      // Add the card to collection
      await _storage!.saveCard(card);
      
      // Update local state immediately to show card as added
      setState(() {
        _collectionCardIds.add(card.id);
      });
      
      // Use the widget's onAddToCollection handler if provided 
      if (widget.onAddToCollection != null) {
        widget.onAddToCollection!(card);
      }
      // Remove the internal toast display - let the parent component handle it
    } catch (e) {
      print('Error adding card to collection: $e');
      
      // Only show error toast if parent handler not provided
      if (widget.onAddToCollection == null && mounted) {
        showToast(
          context: context,
          title: 'Failed to Add Card',
          subtitle: e.toString(),
          icon: Icons.error_outline,
          isError: true,
          compact: true,
          bottomOffset: 56,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    // Ensure images start loading on very first build
    if (!_initialLoadStarted) {
      _preloadVisibleImages(immediate: true);
    }
    
    final currencyProvider = Provider.of<CurrencyProvider>(context);

    return SliverPadding(
      padding: const EdgeInsets.all(8),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.7,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final card = widget.cards[index];
            final imageUrl = card.imageUrl;
            
            // One more chance to request missing images
            if (!_requestedImages.contains(imageUrl) && 
                !widget.imageCache.containsKey(imageUrl)) {
              _requestedImages.add(imageUrl);
              widget.loadImage(imageUrl);
            }
            
            // Use our new CardGridItem
            return CardGridItem(
              card: card,
              cachedImage: widget.imageCache[imageUrl],
              onCardTap: widget.onCardTap,
              onAddToCollection: widget.onAddToCollection ?? (_) {}, // Pass it here with a default
              isInCollection: _collectionCardIds.contains(card.id),
              currencySymbol: currencyProvider.symbol,
            );
          },
          childCount: widget.cards.length,
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: true,
        ),
      ),
    );
  }
}
