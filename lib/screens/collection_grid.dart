import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:your_app/models/tcg_card.dart';
import 'package:your_app/providers/sort_provider.dart';
import 'package:your_app/services/storage_service.dart';

class CollectionsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Collections'),
      ),
      body: StreamBuilder<List<TcgCard>>(
        stream: storage.watchCards(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final cards = snapshot.data ?? [];
          final sortOption = context.watch<SortProvider>().currentSort;
          
          // Sort the cards based on selected option
          final sortedCards = List<TcgCard>.from(cards)..sort((a, b) {
            switch (sortOption) {
              case CollectionSortOption.nameAZ:
                return a.name.compareTo(b.name);
              case CollectionSortOption.nameZA:
                return b.name.compareTo(a.name);
              case CollectionSortOption.valueHighLow:
                return (b.price ?? 0).compareTo(a.price ?? 0);
              case CollectionSortOption.valueLowHigh:
                return (a.price ?? 0).compareTo(b.price ?? 0);
              case CollectionSortOption.newest:
                return (b.addedToCollection ?? DateTime.now())
                    .compareTo(a.addedToCollection ?? DateTime.now());
              case CollectionSortOption.oldest:
                return (a.addedToCollection ?? DateTime.now())
                    .compareTo(b.addedToCollection ?? DateTime.now());
              case CollectionSortOption.countHighLow:
              case CollectionSortOption.countLowHigh:
                return 0; // These options don't apply to the main collection
            }
          });

          // Use sortedCards instead of cards in your GridView
          return GridView.builder(
            itemCount: sortedCards.length,
            itemBuilder: (context, index) {
              final card = sortedCards[index];
              // ...rest of your card building code...
            },
          );
        },
      ),
    );
  }
}
