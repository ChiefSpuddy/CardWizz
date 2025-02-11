import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tcg_card.dart';
import '../services/storage_service.dart';
import '../providers/currency_provider.dart';
import '../services/purchase_service.dart';
import '../screens/card_details_screen.dart';  // Add this import

class CardGridItem extends StatefulWidget {
  final TcgCard card;
  final VoidCallback? onTap;
  final bool showQuickAdd;  // Add this parameter
  final Image? cached;  // Add this parameter
  final String? heroContext;  // Add this property

  const CardGridItem({
    super.key,
    required this.card,
    this.onTap,
    this.showQuickAdd = false,  // Default to false
    this.cached,  // Add this parameter
    this.heroContext,  // Add this parameter
  });

  @override
  State<CardGridItem> createState() => _CardGridItemState();
}

class _CardGridItemState extends State<CardGridItem> {
  bool _isLoaded = false;
  bool _hasError = false;

  Future<void> _addCardToCollection(BuildContext context) async {
    try {
      final storage = Provider.of<StorageService>(context, listen: false);
      await storage.addCard(widget.card);
      
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars(); // Clear any existing SnackBars
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Added ${widget.card.name} to collection',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2), // Reduced from default 4 seconds
          backgroundColor: Theme.of(context).colorScheme.secondary,
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 16,
            left: 16,
            right: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      final colorScheme = Theme.of(context).colorScheme;
      final storage = Provider.of<StorageService>(context, listen: false);
      final remainingSlots = storage.remainingFreeSlots;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.diamond_outlined, color: colorScheme.primary),
              const SizedBox(width: 8),
              const Text('Premium Required'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(e.toString()),
              const SizedBox(height: 16),
              Text(
                'Free users can add up to 10 cards',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              Text(
                'You have $remainingSlots slots remaining',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text('Premium features include:'),
              const SizedBox(height: 8),
              _buildFeatureRow('Unlimited card collection'),
              _buildFeatureRow('Price history tracking'),
              _buildFeatureRow('Advanced analytics'),
              _buildFeatureRow('Multiple binders'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Maybe Later'),
            ),
            FilledButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                final purchaseService = context.read<PurchaseService>();
                await purchaseService.purchasePremium();
              },
              icon: const Text('💎'),
              label: const Text('Upgrade Now'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildFeatureRow(String feature) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(feature),
        ],
      ),
    );
  }

  // Update _buildImage method
  Widget _buildImage() {
    if (widget.card.imageUrl.isEmpty) {
      return const Center(
        child: Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey),
      );
    }

    if (widget.cached != null) {
      if (!_isLoaded) {
        Future.microtask(() {
          if (mounted) setState(() => _isLoaded = true);
        });
      }
      return widget.cached!;
    }

    return Image.network(
      widget.card.imageUrl,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, progress) {
        if (progress == null) {
          if (mounted && !_hasError) {
            Future.microtask(() {
              if (mounted) setState(() => _isLoaded = true);
            });
          }
          return child;
        }
        return Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            value: progress.expectedTotalBytes != null
                ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                : null,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        _hasError = true;
        return const Center(
          child: Icon(Icons.broken_image_outlined, size: 48, color: Colors.red),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyProvider = context.watch<CurrencyProvider>();

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: _isLoaded ? 1.0 : 0.0,
      child: Stack(
        children: [
          Card(
            clipBehavior: Clip.antiAlias,
            elevation: 2,
            child: InkWell(
              onTap: () {
                if (!context.mounted) return;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CardDetailsScreen(
                        card: widget.card,
                        heroContext: widget.heroContext ?? 'grid',
                      ),
                    ),
                  );
                });
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 5, // Adjust image size ratio
                    child: Hero(
                      tag: 'collection_${widget.card.id}',  // Add 'collection_' prefix
                      child: _buildImage(),
                    ),
                  ),
                  // Add card name section
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      border: Border(
                        top: BorderSide(
                          color: Theme.of(context).dividerColor.withOpacity(0.1),
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    child: Text(
                      widget.card.name,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Set info overlay - moved up slightly to accommodate name
          Positioned(
            left: 0,
            right: 0,
            bottom: 44, // Adjusted position
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
              padding: const EdgeInsets.all(4),
              child: Text(
                widget.card.set != null 
                    ? '${widget.card.set!.name} · ${widget.card.number}'
                    : widget.card.number.isNotEmpty ? '#${widget.card.number}' : '',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Price bar - moved up slightly
          Positioned(
            left: 0,
            right: 0,
            bottom: 24, // Adjusted position
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: Colors.black87,
              child: Text(
                widget.card.price != null 
                    ? currencyProvider.formatValue(widget.card.price!)
                    : 'No price',
                style: TextStyle(
                  color: widget.card.price != null ? Colors.white : Colors.grey[400],
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Quick add button
          if (widget.showQuickAdd)
            Positioned(
              top: 4,
              right: 4,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _addCardToCollection(context),
                  customBorder: const CircleBorder(),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
