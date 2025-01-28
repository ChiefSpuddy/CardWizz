import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tcg_card.dart';
import '../services/storage_service.dart';
import '../services/collection_service.dart';
import '../screens/card_details_screen.dart';
import 'card_grid_item.dart';
import '../models/custom_collection.dart';
import '../providers/app_state.dart';
import '../widgets/sign_in_button.dart';
import '../utils/notification_manager.dart';

class CollectionGrid extends StatefulWidget {
  const CollectionGrid({super.key});

  @override
  _CollectionGridState createState() => _CollectionGridState();
}

class _CollectionGridState extends State<CollectionGrid> {
  final Set<String> _selectedCards = {};
  bool _isMultiSelectMode = false;

  void _toggleCardSelection(String cardId) {
    setState(() {
      if (_selectedCards.contains(cardId)) {
        _selectedCards.remove(cardId);
        if (_selectedCards.isEmpty) {
          _isMultiSelectMode = false;
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
        builder: (context) => CardDetailsScreen(card: card),
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

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final storage = Provider.of<StorageService>(context);
    
    if (!appState.isAuthenticated) {
      return const SignInButton();
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

        if (cards.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.collections_bookmark_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Your collection is empty',
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 8),
                Text(
                  'Add cards from the Search tab',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return Stack(
          children: [
            GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.7,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: cards.length,
              itemBuilder: (context, index) {
                final card = cards[index];
                final isSelected = _selectedCards.contains(card.id);
                
                return GestureDetector(
                  onLongPress: () {
                    setState(() {
                      _isMultiSelectMode = true;
                      _toggleCardSelection(card.id);
                    });
                  },
                  onTap: () {
                    if (_isMultiSelectMode) {
                      _toggleCardSelection(card.id);
                    } else {
                      _showCardDetails(context, card);
                    }
                  },
                  child: Stack(
                    children: [
                      CardGridItem(
                        card: card,
                        onTap: null,
                      ),
                      if (_isMultiSelectMode)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected 
                                ? Theme.of(context).primaryColor 
                                : Colors.grey.withOpacity(0.5),
                            ),
                            padding: const EdgeInsets.all(2),
                            child: Icon(
                              isSelected ? Icons.check_circle : Icons.circle_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                    ],
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
                  color: Theme.of(context).colorScheme.surface.withOpacity(0.95),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '${_selectedCards.length} selected',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  FilledButton.tonal(
                                    onPressed: () => _addToCustomCollection(context),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(Icons.collections_bookmark, size: 18),
                                        SizedBox(width: 8),
                                        Text('Add to Binder'),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  FilledButton.tonal(
                                    onPressed: () => _removeSelectedCards(context),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Theme.of(context).colorScheme.errorContainer,
                                      foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(Icons.delete_outline, size: 18),
                                        SizedBox(width: 8),
                                        Text('Remove'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
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
}
