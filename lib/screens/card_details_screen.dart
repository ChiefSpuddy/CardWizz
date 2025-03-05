import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tcg_card.dart';
import '../utils/card_details_router.dart';
import '../services/storage_service.dart';
import '../providers/app_state.dart';
import '../widgets/styled_toast.dart';

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
      await storageService.addCard(widget.card);

      // Notify app state about the change
      Provider.of<AppState>(context, listen: false).notifyCardChange();

      if (mounted) {
        // Use green toast with consistent styling
        showToast(
          context: context,
          title: 'Added to Collection',
          subtitle: widget.card.name,
          icon: Icons.check_circle,
          backgroundColor: Colors.green,
          compact: true,
          bottomOffset: 0, // For full-screen details, position at bottom
          onTap: null, // Don't navigate anywhere on tap
        );
        
        setState(() => _isAddingToCollection = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAddingToCollection = false);
        
        // Use styled toast for errors too
        showToast(
          context: context,
          title: 'Unable to Add Card',
          subtitle: e.toString(),
          icon: Icons.error_outline,
          isError: true,
          compact: true,
          bottomOffset: 0, // For full-screen details, position at bottom
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
