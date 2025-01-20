import 'package:flutter/material.dart';
import '../models/business_card_model.dart';
import '../constants/colors.dart';
import '../constants/app_constants.dart';

class CardGridItem extends StatelessWidget {
  final BusinessCard card;
  final VoidCallback? onTap;

  const CardGridItem({
    super.key,
    required this.card,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      elevation: 2,
      child: InkWell(
        onTap: onTap ?? () {
          // TODO: Navigate to card detail screen
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Image or Placeholder
            AspectRatio(
              aspectRatio: AppConstants.cardAspectRatio,
              child: card.imageUrl != null
                  ? Image.network(
                      card.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppColors.secondary.withOpacity(0.1),
                          child: const Icon(
                            Icons.broken_image,
                            color: Colors.grey,
                          ),
                        );
                      },
                    )
                  : Container(
                      color: AppColors.secondary.withOpacity(0.1),
                      child: const Icon(
                        Icons.business_card,
                        color: Colors.grey,
                      ),
                    ),
            ),
            // Card Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (card.title != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        card.title!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodySmall?.color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (card.company != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        card.company!,
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
