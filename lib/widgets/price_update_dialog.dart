import 'package:flutter/material.dart';

class PriceUpdateDialog extends StatelessWidget {
  final int current;
  final int total;

  const PriceUpdateDialog({
    super.key,
    required this.current,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    // Handle edge cases
    if (total == 0) {
      return const Dialog(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('No cards to update'),
        ),
      );
    }

    final progress = (current / total * 100).round();
    
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Checking Card Prices',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            LinearProgressIndicator(
              value: current / total,
              backgroundColor: Colors.grey[200],
            ),
            const SizedBox(height: 12),
            Text(
              '$progress% • Card $current of $total',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.info_outline, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Checking TCG and eBay prices...',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
