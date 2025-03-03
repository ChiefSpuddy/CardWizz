import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tcg_card.dart';
import '../utils/card_details_router.dart';
import '../services/storage_service.dart';
import '../providers/app_state.dart';

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

      // IMPORTANT: Add this line to make sure the app state knows cards were added
      Provider.of<AppState>(context, listen: false).notifyCardChange();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.card.name} added to collection!')),
        );
        setState(() => _isAddingToCollection = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAddingToCollection = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
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
