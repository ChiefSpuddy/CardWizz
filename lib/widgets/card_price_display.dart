import '../services/logging_service.dart';
import 'package:flutter/material.dart';
import '../services/price_service.dart' as price_service;
import '../utils/card_details_router.dart';
import '../providers/currency_provider.dart';
import 'package:provider/provider.dart';
import '../models/tcg_card.dart';

class CardPriceDisplay extends StatefulWidget {
  final TcgCard card;
  final bool showSource;
  final double textSize;
  final bool isDetailed;
  final bool includeGraded;
  
  const CardPriceDisplay({
    Key? key,
    required this.card,
    this.showSource = true,
    this.textSize = 16.0,
    this.isDetailed = false,
    this.includeGraded = false, // By default, only show raw prices
  }) : super(key: key);
  
  @override
  State<CardPriceDisplay> createState() => _CardPriceDisplayState();
}

// Ensure price display always uses raw prices for consistency

class _CardPriceDisplayState extends State<CardPriceDisplay> {
  double? _rawPrice;
  double? _gradedPrice;
  price_service.PriceSource _source = price_service.PriceSource.unknown;
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasGradedData = false;
  double _gradedRatio = 1.0;
  
  @override
  void initState() {
    super.initState();
    _loadPrice();
  }
  
  @override
  void didUpdateWidget(CardPriceDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.card.id != widget.card.id || 
        oldWidget.card.price != widget.card.price ||
        oldWidget.includeGraded != widget.includeGraded) {
      _loadPrice();
    }
  }
  
  Future<void> _loadPrice() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // For all views, load raw price by default
      final priceData = await CardDetailsRouter.getPriceData(
        widget.card, 
        includeGraded: false // Always use raw price data
      );
      
      if (mounted) {
        setState(() {
          _rawPrice = priceData.price;
          _source = priceData.source;
          _isLoading = false;
        });
      }
      
      // Only load additional graded data if detailed view requires it
      if (widget.isDetailed && mounted) {
        try {
          final comprehensiveData = await CardDetailsRouter.getComprehensivePriceData(widget.card);
          if (mounted) {
            setState(() {
              _gradedPrice = comprehensiveData.gradedPrice;
              _hasGradedData = comprehensiveData.hasGradedSales;
              _gradedRatio = comprehensiveData.gradedToRawRatio;
            });
          }
        } catch (e) {
          LoggingService.debug('Error loading comprehensive price data: $e');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading price';
          _isLoading = false;
        });
      }
      LoggingService.debug('Error loading card price: $e');
    }
  }
  
  String _formatPrice(double? price, String symbol) {
    if (price == null) return 'N/A';
    return '$symbol${price.toStringAsFixed(2)}';
  }
  
  Widget _buildSourceIndicator(BuildContext context) {
    if (!widget.showSource) return const SizedBox.shrink();
    
    final sourceColors = {
      price_service.PriceSource.ebay: Colors.green.shade700,
      price_service.PriceSource.tcgApi: Colors.blue.shade700,
      price_service.PriceSource.original: Colors.orange.shade700,
      price_service.PriceSource.unknown: Colors.grey.shade700,
    };
    
    final sourceIcons = {
      price_service.PriceSource.ebay: Icons.shopping_bag,
      price_service.PriceSource.tcgApi: Icons.store,
      price_service.PriceSource.original: Icons.list_alt,
      price_service.PriceSource.unknown: Icons.help_outline,
    };
    
    final tooltips = {
      price_service.PriceSource.ebay: 'Based on recent eBay sales',
      price_service.PriceSource.tcgApi: 'Based on TCG market data',
      price_service.PriceSource.original: 'Original listing price',
      price_service.PriceSource.unknown: 'Price source unknown',
    };
    
    return Tooltip(
      message: tooltips[_source] ?? '',
      child: Icon(
        sourceIcons[_source] ?? Icons.help_outline,
        color: sourceColors[_source] ?? Colors.grey,
        size: widget.textSize * 0.8,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    final symbol = currencyProvider.symbol;
    
    if (_isLoading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: widget.textSize,
            height: widget.textSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('Loading price...', style: TextStyle(fontSize: widget.textSize * 0.8)),
        ],
      );
    }
    
    if (_errorMessage != null) {
      return Text(
        _errorMessage!,
        style: TextStyle(
          color: Colors.red.shade700,
          fontSize: widget.textSize,
        ),
      );
    }
    
    // Calculate the display price based on configuration
    final displayPrice = _rawPrice ?? widget.card.price;
    
    // For detailed view with graded data, show both raw and graded prices
    if (widget.isDetailed && _hasGradedData && _rawPrice != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Raw: ${_formatPrice(_rawPrice, symbol)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: widget.textSize,
                  color: _source == price_service.PriceSource.ebay
                      ? Colors.green.shade800
                      : null,
                ),
              ),
              if (widget.showSource) ...[
                const SizedBox(width: 4),
                _buildSourceIndicator(context),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                'Graded: ${_formatPrice(_gradedPrice, symbol)}',
                style: TextStyle(
                  fontSize: widget.textSize * 0.9,
                  fontWeight: FontWeight.w600,
                  color: Colors.purple.shade700,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.verified,
                color: Colors.purple.shade700,
                size: widget.textSize * 0.8,
              ),
            ],
          ),
        ],
      );
    }
    
    // Standard price display for non-detailed views
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatPrice(displayPrice, symbol),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: widget.textSize,
            color: _source == price_service.PriceSource.ebay
                ? Colors.green.shade800
                : null,
          ),
        ),
        if (widget.showSource) ...[
          const SizedBox(width: 4),
          _buildSourceIndicator(context),
        ],
        if (widget.isDetailed && _source == price_service.PriceSource.ebay) ...[
          const SizedBox(width: 8),
          Text(
            '(eBay raw)',
            style: TextStyle(
              fontSize: widget.textSize * 0.7,
              fontStyle: FontStyle.italic,
              color: Colors.green.shade700,
            ),
          ),
        ],
      ],
    );
  }
}
