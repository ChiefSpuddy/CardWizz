import 'package:flutter/material.dart';
import '../models/tcg_card.dart';

class ChartDebugWidget extends StatelessWidget {
  final List<TcgCard> cards;

  const ChartDebugWidget({
    super.key,
    required this.cards,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Debug Info:', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Number of cards: ${cards.length}'),
            Text('Cards with price history: ${cards.where((c) => c.priceHistory.isNotEmpty).length}'),
            const SizedBox(height: 8),
            const Text('First 3 cards price history:'),
            ...cards.take(3).map((card) => Padding(
              padding: const EdgeInsets.only(left: 16, top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(card.name),
                  Text('History points: ${card.priceHistory.length}'),
                  if (card.priceHistory.isNotEmpty) Text(
                    'Latest price: ${card.priceHistory.last.price} '
                    'at ${card.priceHistory.last.date}'
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}
