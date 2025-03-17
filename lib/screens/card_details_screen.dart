import '../services/logging_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/card_details_router.dart';
import '../services/storage_service.dart';
import '../providers/app_state.dart';
import '../utils/notification_manager.dart'; // Keep this import
import '../services/price_service.dart' as price_service;  // Import with namespace
import '../models/tcg_card.dart';
import 'package:url_launcher/url_launcher.dart';

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
      LoggingService.debug('Error loading accurate price: $e');
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
        
        // Use the unified notification system
        NotificationManager.success(
          context,
          message: 'Card added to collection',
          position: NotificationPosition.bottom,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAddingToCollection = false);
        
        // Use the unified notification system for errors
        NotificationManager.error(
          context,
          message: 'Failed to add card: $e',
          position: NotificationPosition.bottom,
        );
      }
    }
  }

  Widget _buildMarketActionButtons(TcgCard card) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          Expanded(
            child: _buildMarketButton(
              'Cardmarket',
              Colors.blue.shade700,
              Icons.shopping_cart_outlined,
              () => _openCardmarket(card),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildMarketButton(
              'eBay',
              Colors.red.shade700,
              Icons.gavel_outlined,
              () => _openEbay(card),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketButton(String text, Color color, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(text, style: const TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _openCardmarket(TcgCard card) async {
    final query = Uri.encodeComponent(card.name);
    final url = Uri.parse('https://www.cardmarket.com/en/Pokemon/Products/Singles?searchString=$query');
    await _launchUrl(url);
  }

  Future<void> _openEbay(TcgCard card) async {
    final query = Uri.encodeComponent('${card.name} pokemon card');
    final url = Uri.parse('https://www.ebay.com/sch/i.html?_nkw=$query');
    await _launchUrl(url);
  }

  Future<void> _launchUrl(Uri url) async {
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
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
      // Remove this line as we've integrated the buttons directly into the screens
      // marketActionButtons: _buildMarketActionButtons(widget.card),
    );
  }
}
