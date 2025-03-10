import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tcg_card.dart';
import '../services/storage_service.dart';
import '../services/collection_service.dart';
import '../screens/card_details_screen.dart';
import 'card_grid_item.dart';
import '../models/custom_collection.dart';
import '../providers/app_state.dart';
import '../utils/notification_manager.dart';
import '../providers/sort_provider.dart';
import '../screens/home_screen.dart';  // Add this import
import '../widgets/empty_collection_view.dart';
import '../widgets/sign_in_view.dart';  // Add this import

class CollectionGrid extends StatefulWidget {
  final bool keepAlive;  // Add this
  final Function(bool)? onMultiselectChange;

  const CollectionGrid({
    super.key,
    this.keepAlive = false,  // Add this
    this.onMultiselectChange,
  });

  @override
  State<CollectionGrid> createState() => _CollectionGridState();
}

class _CollectionGridState extends State<CollectionGrid> with AutomaticKeepAliveClientMixin {
  final Set<String> _selectedCards = {};
  bool _isMultiSelectMode = false;

  // Add scroll controller and scroll state tracking
  late ScrollController _scrollController;
  bool _isScrolling = false;
  bool _lowQualityRendering = false;
  bool _initialRendering = true;  // Add this flag to track initial rendering

  @override
  bool get wantKeepAlive => true;  // Keep the state alive

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    
    // Reset initial rendering after frame is drawn
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _initialRendering = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    // Only enable low-quality rendering during very fast scrolling
    if (_scrollController.position.activity?.velocity != null) {
      final velocity = _scrollController.position.activity!.velocity.abs();
      
      // Use higher threshold for activating low quality mode (1500 instead of 1000)
      // and only when not in initial rendering
      if (velocity > 1500 && !_lowQualityRendering && !_initialRendering) {
        setState(() => _lowQualityRendering = true);
      } 
      // More quickly turn off low quality mode (300 instead of 200)
      else if (velocity < 300 && _lowQualityRendering) {
        setState(() => _lowQualityRendering = false);
      }
    }

    // Also track if scrolling at all
    final isCurrentlyScrolling = _scrollController.position.isScrollingNotifier.value;
    if (isCurrentlyScrolling != _isScrolling) {
      setState(() {
        _isScrolling = isCurrentlyScrolling;
        
        // When scrolling stops, always ensure high quality
        if (!isCurrentlyScrolling) {
          _lowQualityRendering = false;
        }
      });
    }
  }

  void _toggleCardSelection(String cardId) {
    setState(() {
      if (_selectedCards.contains(cardId)) {
        _selectedCards.remove(cardId);
        if (_selectedCards.isEmpty) {
          _isMultiSelectMode = false;
          // Notify parent when exiting multiselect mode
          if (widget.onMultiselectChange != null) {
            widget.onMultiselectChange!(false);
          }
        }
      } else {
        _selectedCards.add(cardId);
      }
    });
  }

  void _exitMultiSelectMode() {
    setState(() {
      _selectedCards.clear();
      _isMultiSelectMode = false;
    });
  }

  Future<void> _removeSelectedCards(BuildContext context) async {
    final storage = Provider.of<StorageService>(context, listen: false);
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Cards'),
        content: Text('Remove ${_selectedCards.length} cards from your collection?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      for (final cardId in _selectedCards) {
        await storage.removeCard(cardId);
      }
      _exitMultiSelectMode();
    }
  }

  Future<void> _addToCustomCollection(BuildContext context) async {
    final service = await CollectionService.getInstance();
    
    if (!context.mounted) return;

    final collections = await service.getCustomCollections();
    
    if (!context.mounted) return;
    
    if (collections.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No Binders'),
          content: const Text('Create a binder first to add cards to it.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: Show create binder dialog
              },
              child: const Text('Create Binder'),
            ),
          ],
        ),
      );
      return;
    }

    await showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Text(
                'Add ${_selectedCards.length} cards to binder',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const Divider(),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: collections.map((collection) => ListTile(
                    leading: const Icon(Icons.folder_outlined),
                    title: Text(collection.name),
                    subtitle: Text('${collection.cardIds.length} cards'),
                    onTap: () async {
                      Navigator.pop(context);
                      for (final cardId in _selectedCards) {
                        await service.addCardToCollection(collection.id, cardId);
                      }
                      if (context.mounted) {
                        NotificationManager.show(
                          context,
                          message: 'Added ${_selectedCards.length} cards to ${collection.name}',
                        );
                        _exitMultiSelectMode();
                      }
                    },
                  )).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRemoveDialog(BuildContext context, TcgCard card) async {
    // Store StorageService before showing dialog
    final storage = Provider.of<StorageService>(context, listen: false);
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove Card'),
        content: Text('Remove ${card.name} from your collection?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(dialogContext, false),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
            onPressed: () => Navigator.pop(dialogContext, true),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await storage.removeCard(card.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed ${card.name} from collection'),
            action: SnackBarAction(
              label: 'UNDO',
              onPressed: () async {
                await storage.undoRemoveCard(card.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Restored ${card.name} to collection')),
                  );
                }
              },
            ),
          ),
        );
      }
    }
  }

  void _showCardDetails(BuildContext context, TcgCard card) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CardDetailsScreen(
          card: card,
          heroContext: 'collection',
          isFromCollection: true,  // Add this parameter
        ),
      ),
    );
  }

  Future<void> _showCardOptions(BuildContext context, TcgCard card) async {
    final storage = Provider.of<StorageService>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.2,
        maxChildSize: 0.75,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    height: 4,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    card.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollController,
                children: [
                  ListTile(
                    leading: const Icon(Icons.delete_outline, color: Colors.red),
                    title: const Text('Remove from Collection'),
                    onTap: () {
                      Navigator.pop(context);
                      _showRemoveDialog(context, card);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.collections_bookmark_outlined),
                    title: const Text('Add to Custom Collection'),
                    onTap: () {
                      Navigator.pop(context);
                      _showAddToCollectionDialog(context, card);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('View Details'),
                    onTap: () {
                      Navigator.pop(context);
                      _showCardDetails(context, card);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddToCollectionDialog(BuildContext context, TcgCard card) async {
    final service = await CollectionService.getInstance();
    
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add to Collection'),
        content: StreamBuilder<List<CustomCollection>>(
          stream: service.getCustomCollectionsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final collections = snapshot.data ?? [];
            if (collections.isEmpty) {
              return const Text('No custom collections available');
            }

            return SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: collections.length,
                itemBuilder: (context, index) {
                  final collection = collections[index];
                  return ListTile(
                    title: Text(collection.name),
                    subtitle: Text(
                      '${collection.cardIds.length} cards',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      try {
                        await service.addCardToCollection(collection.id, card.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Added ${card.name} to ${collection.name}'),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to add card to collection'),
                            ),
                          );
                        }
                      }
                    },
                  );
                },
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void toggleMultiselect() {
    setState(() {
      _isMultiSelectMode = !_isMultiSelectMode;
      if (!_isMultiSelectMode) {
        _selectedCards.clear();
      }
      
      // Notify parent about multiselect state
      if (widget.onMultiselectChange != null) {
        widget.onMultiselectChange!(_isMultiSelectMode);
      }
    });
  }
  
  // Method to be called from parent to cancel multiselect
  void cancelMultiselect() {
    if (_isMultiSelectMode) {
      setState(() {
        _isMultiSelectMode = false;
        _selectedCards.clear();
      });
    }
  }
  
  // Method to be called from parent to remove selected items
  void removeSelected() {
    if (_selectedCards.isNotEmpty) {
      // Call your removal logic here
      // For example: 
      // _selectedCardIds.forEach((id) => storageService.removeCard(id));
      
      setState(() {
        _isMultiSelectMode = false;
        _selectedCards.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);  // Required for AutomaticKeepAliveClientMixin

    final appState = context.watch<AppState>();
    final storage = Provider.of<StorageService>(context);
    
    if (!appState.isAuthenticated) {
      return const SignInView(); // Changed from SignInButton to SignInView
    }

    return StreamBuilder<List<TcgCard>>(
      stream: storage.watchCards(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && snapshot.data == null) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading your collection...'),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red),
                SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                TextButton(
                  onPressed: () {
                    storage.refreshCards(); // Add this method to StorageService
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final cards = snapshot.data ?? [];
        final sortOption = context.watch<SortProvider>().currentSort;
    
        if (cards.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 64.0),
            child: const EmptyCollectionView(
              title: 'Your Collection is Empty',
              message: 'Start building your collection by searching for cards you own',
              icon: Icons.style_outlined,
            ),
          );
        }

        // Sort the cards based on selected option
        final sortedCards = _getSortedCards(cards, sortOption);

        if (sortedCards.isEmpty) {
          return const EmptyCollectionView(
            title: 'Your Collection is Empty',
            message: 'Start building your collection by searching for cards you own',
            icon: Icons.style_outlined,
          );
        }

        return Stack(
          children: [
            GridView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.7,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: sortedCards.length,  // Use sortedCards instead of cards
              cacheExtent: 500, // Increase cache extent for smoother scrolling
              itemBuilder: (context, index) {
                // Modify this condition to never use empty placeholders during initial load
                if (_isScrolling && index > 60 && !_initialRendering) {
                  return const SizedBox();
                }

                final card = sortedCards[index];  // Use sortedCards instead of cards
                final isSelected = _selectedCards.contains(card.id);
                
                return RepaintBoundary(
                  child: GestureDetector(
                    onTap: () {
                      if (_isMultiSelectMode) {
                        _toggleCardSelection(card.id);
                      } else {
                        _showCardDetails(context, card);
                      }
                    },
                    onLongPress: () {
                      setState(() {
                        _isMultiSelectMode = true;
                        _toggleCardSelection(card.id);
                        
                        // Critical fix: Notify parent about entering multiselect mode
                        if (widget.onMultiselectChange != null) {
                          widget.onMultiselectChange!(true);
                        }
                      });
                    },
                    child: Container( // Wrap in Container to ensure gestures work
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected ? Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ) : null,
                      ),
                      child: Stack(
                        children: [
                          Opacity(
                            opacity: isSelected ? 0.8 : 1.0,
                            child: CardGridItem(
                              key: ValueKey(card.id),
                              card: card,
                              heroContext: 'collection',
                              showPrice: true, // Changed to true
                              showName: true,  // Added showName
                              // Always use high quality for initial rendering and non-scrolling
                              highQuality: !_lowQualityRendering || _initialRendering,
                              onTap: () => _showCardDetails(context, card), // Add direct handler here
                            ),
                          ),
                          if (_isMultiSelectMode)
                            Positioned.fill(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  color: isSelected 
                                    ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                                    : Colors.transparent,
                                ),
                                child: Center(
                                  child: AnimatedScale(
                                    scale: _isMultiSelectMode ? 1.0 : 0.0,
                                    duration: const Duration(milliseconds: 200),
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isSelected 
                                          ? Theme.of(context).colorScheme.primary
                                          : Theme.of(context).colorScheme.surface.withOpacity(0.8),
                                        border: Border.all(
                                          color: isSelected
                                            ? Colors.transparent
                                            : Theme.of(context).colorScheme.primary,
                                          width: 2,
                                        ),
                                      ),
                                      child: AnimatedScale(
                                        scale: isSelected ? 1.0 : 0.8,
                                        duration: const Duration(milliseconds: 200),
                                        child: Icon(
                                          isSelected ? Icons.check : Icons.add,
                                          color: isSelected 
                                            ? Colors.white
                                            : Theme.of(context).colorScheme.primary,
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            if (_isMultiSelectMode)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface.withOpacity(0.95),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, -1),
                      ),
                    ],
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          // Styled selection counter
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${_selectedCards.length}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const Spacer(), // Push buttons to the right
                          
                          // Binder button with enhanced styling
                          FilledButton.icon(
                            onPressed: () => _addToCustomCollection(context),
                            icon: const Icon(Icons.collections_bookmark_outlined, size: 16),
                            label: const Text('Binder'),
                            style: FilledButton.styleFrom(
                              elevation: 2,
                              minimumSize: const Size(0, 36),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                              foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
                            ),
                          ),
                          
                          const SizedBox(width: 10),
                          
                          // Remove button with enhanced styling
                          FilledButton.icon(
                            onPressed: () => _removeSelectedCards(context),
                            icon: const Icon(Icons.delete_outlined, size: 16),
                            label: const Text('Remove'),
                            style: FilledButton.styleFrom(
                              elevation: 2,
                              minimumSize: const Size(0, 36),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              backgroundColor: Theme.of(context).colorScheme.errorContainer,
                              foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // Cache sorting results
  List<TcgCard>? _lastCards;
  CollectionSortOption? _lastSortOption;
  List<TcgCard>? _sortedResult;

  List<TcgCard> _getSortedCards(List<TcgCard> cards, CollectionSortOption sortOption) {
    // Return cached result if inputs haven't changed
    if (_lastCards == cards && _lastSortOption == sortOption && _sortedResult != null) {
      return _sortedResult!;
    }

    // Otherwise sort and cache
    final sortedCards = List<TcgCard>.from(cards);

    switch (sortOption) {
      case CollectionSortOption.nameAZ:
        sortedCards.sort((a, b) => a.name.compareTo(b.name));
        break;
      case CollectionSortOption.nameZA:
        sortedCards.sort((a, b) => b.name.compareTo(a.name));
        break;
      case CollectionSortOption.valueHighLow:
        sortedCards.sort((a, b) => (b.price ?? 0).compareTo(a.price ?? 0));
        break;
      case CollectionSortOption.valueLowHigh:
        sortedCards.sort((a, b) => (a.price ?? 0).compareTo(b.price ?? 0));
        break;
      case CollectionSortOption.newest:
        sortedCards.sort((a, b) => (b.addedToCollection ?? DateTime.now())
            .compareTo(a.addedToCollection ?? DateTime.now()));
        break;
      case CollectionSortOption.oldest:
        sortedCards.sort((a, b) => (a.addedToCollection ?? DateTime.now())
            .compareTo(b.addedToCollection ?? DateTime.now()));
        break;
      default:
        break;
    }

    // Update cache
    _lastCards = cards;
    _lastSortOption = sortOption;
    _sortedResult = sortedCards;

    return sortedCards;
  }
}
