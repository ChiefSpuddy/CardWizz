import '../services/logging_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../services/collection_service.dart';
import '../utils/notification_manager.dart';
import '../widgets/create_binder_dialog.dart';
import '../models/tcg_card.dart';  // Add this import

abstract class BaseCardDetailsScreen extends StatefulWidget {
  final TcgCard card;
  final String heroContext;
  final bool isFromBinder;
  final bool isFromCollection;

  const BaseCardDetailsScreen({
    super.key,
    required this.card,
    this.heroContext = 'details',
    this.isFromBinder = false,
    this.isFromCollection = false,
  });
}

abstract class BaseCardDetailsScreenState<T extends BaseCardDetailsScreen>
    extends State<T> with TickerProviderStateMixin {
  late AnimationController wobbleController;
  late AnimationController flipController;
  bool isLoading = true;
  bool showingFront = true;
  late StorageService storage;

  @override
  void initState() {
    super.initState();
    storage = Provider.of<StorageService>(context, listen: false);
    wobbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    // Debugging info about the card
    LoggingService.debug('Loading card details: ${widget.card.name} (ID: ${widget.card.id})');
    LoggingService.debug('Set: ${widget.card.setName} (${widget.card.set.id})');
    
    loadData();
  }

  @override
  void dispose() {
    wobbleController.dispose();
    flipController.dispose();
    super.dispose();
  }

  void loadData();

  void wobbleCard() {
    wobbleController.forward().then((_) => wobbleController.reverse());
  }

  void flipCard() {
    if (flipController.isAnimating) return;
    
    if (showingFront) {
      flipController.forward();
    } else {
      flipController.reverse();
    }
    
    setState(() {
      showingFront = !showingFront;
    });
  }

  Future<void> addToCollection(BuildContext context) async {
    try {
      final service = Provider.of<StorageService>(context, listen: false);
      await service.saveCard(widget.card);
      if (mounted) {
        // Set position to bottom for the notification
        NotificationManager.success(
          context,
          message: '${widget.card.name} has been added to your collection',
          position: NotificationPosition.bottom,
        );
      }
    } catch (e) {
      if (mounted) {
        // Set position to bottom for the notification
        NotificationManager.error(
          context,
          message: 'There was an error adding the card to your collection',
          position: NotificationPosition.bottom,
        );
      }
    }
  }

  Future<void> showAddToBinderDialog(BuildContext context) async {
    final service = await CollectionService.getInstance();
    final collections = await service.getCustomCollections();
    
    if (collections.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No Binders'),
          content: const Text('Create a binder first to add cards to it.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                showCreateBinderDialog(context);
              },
              child: const Text('Create Binder'),
            ),
          ],
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add to Binder',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: collections.length,
                itemBuilder: (context, index) {
                  final collection = collections[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: collection.color,
                      child: const Icon(Icons.collections_bookmark, color: Colors.white),
                    ),
                    title: Text(collection.name),
                    subtitle: Text('${collection.cardIds.length} cards'),
                    onTap: () async {
                      Navigator.pop(context);
                      await service.addCardToCollection(collection.id, widget.card.id);
                      if (context.mounted) {
                        // Set position to bottom for the notification
                        NotificationManager.success(
                          context,
                          message: 'Card added to binder successfully',
                          position: NotificationPosition.bottom,
                        );
                      }
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).colorScheme.secondary,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  showCreateBinderDialog(context);
                },
                icon: const Icon(Icons.add, color: Colors.white),
                label: Text(
                  'Create New Binder',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> showCreateBinderDialog(BuildContext context) async {
    final collectionId = await showDialog<String?>(
      context: context,
      barrierDismissible: true,
      builder: (context) => CreateBinderDialog(
        cardToAdd: widget.card.id,
      ),
    );

    if (collectionId != null && context.mounted) {
      final service = await CollectionService.getInstance();
      final collection = await service.getCollection(collectionId);
      
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      if (context.mounted && collection != null) {
        // Set position to bottom for the notification
        NotificationManager.success(
          context,
          message: 'Added ${widget.card.name} to ${collection.name}',
          position: NotificationPosition.bottom,
        );
      }
    }
  }

  Widget buildFAB({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // Use consistent, attractive colors instead of relying blindly on theme
    final Color startColor = colorScheme.primary;
    final Color endColor = colorScheme.primaryContainer;
    
    return Container(
      height: 46,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(23),
        // Use specific gradient colors for better visual appeal
        gradient: LinearGradient(
          colors: [
            startColor,
            endColor,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: startColor.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: onPressed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }
}
