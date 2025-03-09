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
import 'package:flutter/services.dart'; // Add this import for HapticFeedback
import '../../providers/app_state.dart';  // Import the AppState provider
import '../../widgets/bottom_notification.dart'; // Add our new notification class

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
      // Add haptic feedback for better user experience
      HapticFeedback.lightImpact();
      
      // CRITICAL: Don't update any state or UI before completing the operation
      
      // Save card silently in the background
      await _storage!.saveCard(card);
      
      // IMPORTANT: Update local state only *after* save completes
      if (mounted) {
        setState(() {
          _collectionCardIds.add(card.id);
        });
      }
      
      // Show feedback only after everything is done
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${card.name} added to collection'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 100), // Position higher up
          ),
        );
      }
      
      // IMPORTANT: DO NOT navigate or trigger any parent functions
    } catch (e) {
      print('Error adding card: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          ),
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
            
            // CRITICAL FIX: Create a direct add handler that bypasses the widget's handler completely
            void directAddHandler(TcgCard cardToAdd) async {
              // Add haptic feedback
              HapticFeedback.lightImpact();
              
              try {
                // Get the storage service directly to bypass any parent widget handlers
                final storageService = Provider.of<StorageService>(context, listen: false);
                
                // Save directly without going through widget.onAddToCollection 
                await storageService.saveCard(cardToAdd);
                
                // Update local state to show check immediately
                setState(() {
                  _collectionCardIds.add(cardToAdd.id);
                });
                
                // Show feedback with our new notification
                BottomNotification.show(
                  context: context,
                  title: 'Added to Collection',
                  message: cardToAdd.name,
                  icon: Icons.check_circle,
                );
                
                // Notify app state but with a delay to avoid navigation issues
                Future.delayed(const Duration(milliseconds: 500), () {
                  final appState = Provider.of<AppState>(context, listen: false);
                  appState.notifyCardChange();
                });
              } catch (e) {
                print('Error in direct add handler: $e');
                // Show error with our notification
                BottomNotification.show(
                  context: context,
                  title: 'Error',
                  message: 'Failed to add card: $e',
                  icon: Icons.error_outline,
                  isError: true,
                );
              }
            }
            
            // Use our new CardGridItem with the direct handler
            return CardGridItem(
              card: card,
              cachedImage: widget.imageCache[imageUrl],
              onCardTap: widget.onCardTap,
              // CRITICAL: Use the direct handler instead of the parent's handler
              onAddToCollection: directAddHandler,
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
