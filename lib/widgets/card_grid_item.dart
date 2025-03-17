import 'package:flutter/material.dart';
import '../models/tcg_card.dart';
import '../providers/currency_provider.dart';
import 'package:provider/provider.dart';
import '../widgets/network_card_image.dart';
import 'package:flutter/services.dart';

class CardGridItem extends StatefulWidget {
  final TcgCard card;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCollection;
  final bool isInCollection;
  final bool showPrice;
  final bool showName;
  final bool highQuality;
  final String heroContext;
  final bool hideCheckmarkWhenInCollection;

  const CardGridItem({
    Key? key,
    required this.card,
    this.onTap,
    this.onAddToCollection,
    this.isInCollection = false,
    this.showPrice = false,
    this.showName = true,
    this.highQuality = true,
    required this.heroContext,
    this.hideCheckmarkWhenInCollection = false,
  }) : super(key: key);

  @override
  State<CardGridItem> createState() => _CardGridItemState();
}

class _CardGridItemState extends State<CardGridItem> {
  bool _processingAdd = false;
  
  @override
  Widget build(BuildContext context) {
    final heroTag = 'card_${widget.card.id}_${widget.heroContext}';
    final colorScheme = Theme.of(context).colorScheme;
    
    return Stack(
      children: [
        // CRITICAL FIX: Separate the main card tap handler from the + button
        GestureDetector(
          onTap: widget.onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Card image
                Expanded(
                  child: Hero(
                    tag: heroTag,
                    child: NetworkCardImage(
                      imageUrl: widget.card.imageUrl,
                      highQuality: widget.highQuality,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                
                // Card info footer
                if (widget.showName || (widget.showPrice && widget.card.price != null))
                  Container(
                    color: Theme.of(context).cardColor,
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.showName)
                          Text(
                            widget.card.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        if (widget.showPrice && widget.card.price != null)
                          Consumer<CurrencyProvider>(
                            builder: (context, currencyProvider, _) => Text(
                              '${currencyProvider.symbol}${widget.card.price!.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 10,
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        
        // CRITICAL FIX: Completely separate "+" button with its own tap handler
        if (!widget.isInCollection || (widget.isInCollection && !widget.hideCheckmarkWhenInCollection))
          Positioned(
            top: 5,
            right: 5,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(15),
                onTap: widget.isInCollection ? null : _safelyHandleAddTap,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.isInCollection
                        ? Colors.green.withOpacity(0.9)
                        : colorScheme.primary.withOpacity(0.9),
                  ),
                  child: _processingAdd 
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ) 
                    : Center(
                        child: Icon(
                          widget.isInCollection ? Icons.check : Icons.add,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                ),
              ),
            ),
          ),
      ],
    );
  }
  
  // CRITICAL FIX: New method that completely isolates the tap handling
  void _safelyHandleAddTap() {
    if (_processingAdd) return;
    
    // Set state to show processing indicator
    setState(() {
      _processingAdd = true;
    });
    
    // Provide haptic feedback
    HapticFeedback.lightImpact();
    
    // Use post-frame callback to avoid navigation stack conflicts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        // Call onAddToCollection without affecting navigation
        if (widget.onAddToCollection != null) {
          widget.onAddToCollection!();
        }
      } finally {
        // Reset state after a short delay for UI feedback
        if (mounted) {
          Future.delayed(
            const Duration(milliseconds: 800),
            () {
              if (mounted) {
                setState(() => _processingAdd = false);
              }
            },
          );
        }
      }
    });
  }

  void _onAddButtonPressed() {
    if (widget.onAddToCollection != null) {
      widget.onAddToCollection!();
    }
  }
}
