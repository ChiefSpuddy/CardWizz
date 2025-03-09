import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tcg_card.dart';
import '../utils/card_details_router.dart';
import '../services/storage_service.dart';
import '../providers/app_state.dart';
// Import the bottom toast instead of styled_toast
import '../utils/bottom_toast.dart';
// Update imports - add our new notification class
import '../widgets/bottom_notification.dart'; 

// This class is now just a router to the appropriate screen type
class CardDetailsScreen extends StatefulWidget {
  final TcgCard card;
  final String heroContext;
  final bool isFromBinder;
  final bool isFromCollection;

  const CardDetailsScreen({
    super.key,
    required this.card,
    this.heroContext = 'details',
    this.isFromBinder = false,
    this.isFromCollection = false,
  });

  @override
  _CardDetailsScreenState createState() => _CardDetailsScreenState();
}

class _CardDetailsScreenState extends State<CardDetailsScreen> {
  bool _isAddingToCollection = false;

  Future<void> _addToCollection() async {
    setState(() => _isAddingToCollection = true);

    try {
      final storageService = Provider.of<StorageService>(context, listen: false);
      await storageService.saveCard(widget.card);

      // Notify app state about the change
      Provider.of<AppState>(context, listen: false).notifyCardChange();

      if (mounted) {
        setState(() => _isAddingToCollection = false);
        
        // *** Use our new bottom notification implementation ***
        BottomNotification.show(
          context: context,
          title: 'Added to Collection',
          message: widget.card.name,
          icon: Icons.check_circle,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAddingToCollection = false);
        
        // Show errors with the new implementation too
        BottomNotification.show(
          context: context,
          title: 'Error',
          message: 'Failed to add card: $e',
          icon: Icons.error_outline,
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use the router to get the appropriate screen
    return CardDetailsRouter.getDetailsScreen(
      card: widget.card,
      heroContext: widget.heroContext,
      isFromBinder: widget.isFromBinder,
      isFromCollection: widget.isFromCollection,
    );
  }
}
