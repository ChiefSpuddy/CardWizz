import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tcg_card.dart';
import '../utils/card_details_router.dart';
import '../services/storage_service.dart';
import '../providers/app_state.dart';
import '../utils/bottom_toast.dart';
import '../widgets/bottom_notification.dart';
import '../services/price_service.dart' as price_service;  // Import with namespace

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
  double? _accuratePrice;
  price_service.PriceSource _priceSource = price_service.PriceSource.unknown;  // Fixed namespace
  bool _isLoadingPrice = false;

  @override
  void initState() {
    super.initState();
    _loadAccuratePrice();
  }
  
  // Load the most accurate price from eBay sold data
  Future<void> _loadAccuratePrice() async {
    if (mounted) {
      setState(() => _isLoadingPrice = true);
    }
    
    try {
      // Get detailed price data
      final priceData = await CardDetailsRouter.getPriceData(widget.card);
      
      if (mounted) {
        setState(() {
          _accuratePrice = priceData.price;
          _priceSource = priceData.source;
          _isLoadingPrice = false;
        });
      }
    } catch (e) {
      print('Error loading accurate price: $e');
      if (mounted) {
        setState(() => _isLoadingPrice = false);
      }
    }
  }

  Future<void> _addToCollection() async {
    setState(() => _isAddingToCollection = true);

    try {
      final storageService = Provider.of<StorageService>(context, listen: false);
      
      // Create a copy of the card with the accurate price
      final updatedCard = _accuratePrice != null 
          ? widget.card.copyWith(price: _accuratePrice) 
          : widget.card;
          
      // Save the card with accurate pricing
      await storageService.saveCard(updatedCard);

      // Notify app state about the change
      Provider.of<AppState>(context, listen: false).notifyCardChange();

      if (mounted) {
        setState(() => _isAddingToCollection = false);
        
        // Use our new bottom notification implementation
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
