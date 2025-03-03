import 'package:flutter/material.dart';
import '../models/tcg_card.dart';
import 'package:uuid/uuid.dart'; // Add UUID import

class HomePreviewCard extends StatelessWidget {
  final TcgCard card;
  final VoidCallback onTap;
  final bool showPrice;
  final String? currencySymbol;
  
  // Add a unique identifier field to avoid hero tag conflicts
  final String uniqueId = const Uuid().v4().substring(0, 8);

  HomePreviewCard({
    Key? key,
    required this.card,
    required this.onTap,
    this.showPrice = true,
    this.currencySymbol = '\$',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use the unique ID to create a truly unique hero tag
    final heroTag = 'home_preview_${card.id}_$uniqueId';
    
    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 4.0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Hero(
                tag: heroTag, // Use unique hero tag
                child: Image.network(
                  card.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey.withOpacity(0.3),
                    child: const Center(child: Icon(Icons.broken_image)),
                  ),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey.withOpacity(0.3),
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                ),
              ),
            ),
            if (showPrice && card.price != null && card.price! > 0)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                color: Theme.of(context).colorScheme.surface,
                child: Text(
                  '$currencySymbol${card.price!.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
