import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tcg_card.dart';
import '../services/storage_service.dart';
import '../providers/currency_provider.dart';  // Add this import

class CardGridItem extends StatefulWidget {
  final TcgCard card;
  final VoidCallback? onTap;
  final bool showQuickAdd;  // Add this parameter

  const CardGridItem({
    super.key,
    required this.card,
    this.onTap,
    this.showQuickAdd = false,  // Default to false
  });

  @override
  State<CardGridItem> createState() => _CardGridItemState();
}

class _CardGridItemState extends State<CardGridItem> {
  bool _isLoaded = false;
  bool _hasError = false;

  Future<void> _addToCollection(BuildContext context) async {
    final storage = Provider.of<StorageService>(context, listen: false);
    
    try {
      print('Adding card to collection: ${widget.card.name}');
      await storage.saveCard(widget.card);
      await storage.debugStorage(); // Add this debug call
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${widget.card.name} to collection'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error adding card: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add card: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildImage() {
    if (widget.card.imageUrl.isEmpty) {
      return const Center(
        child: Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey),
      );
    }

    return Image.network(
      widget.card.imageUrl,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        print('Error loading image: ${widget.card.imageUrl}');  // Add debug print
        return const Center(
          child: Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey),
        );
      },
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
              onTap: widget.onTap,
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
                  onTap: () => _addToCollection(context),
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
