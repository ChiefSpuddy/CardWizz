import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../models/tcg_card.dart';
import '../widgets/collection_grid.dart';
import '../widgets/custom_collections_grid.dart';  // Add this import
import 'analytics_screen.dart';  // Add this import
import 'home_screen.dart';  // Add this import

class CollectionsScreen extends StatefulWidget {
  const CollectionsScreen({super.key});

  @override
  State<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends State<CollectionsScreen> {
  bool _showCustomCollections = false;

  String _formatValue(double value) {
    if (value >= 1000000) {
      return '€${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '€${(value / 1000).toStringAsFixed(1)}K';
    }
    return '€${value.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<List<TcgCard>>(
      stream: Provider.of<StorageService>(context).watchCards(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final cards = snapshot.data!;
        if (cards.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.style_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Start Your Collection',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Add cards to your collection to track their value and see detailed analytics',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: () {
                      if (context.mounted) {
                        final homeState = context.findAncestorStateOfType<HomeScreenState>();
                        homeState?.setSelectedIndex(2); // Switch to search tab
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Your First Card'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final totalValue = cards.fold<double>(
          0,
          (sum, card) => sum + (card.price ?? 0),
        );

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('My Collection'),
                if (cards.isNotEmpty)
                  Text(
                    '${cards.length} cards · ${_formatValue(totalValue)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[300] : Colors.grey[600],
                    ),
                  ),
              ],
            ),
            leading: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.analytics_outlined),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AnalyticsScreen(),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.sort),
                onPressed: () {
                  // TODO: Implement sorting
                },
              ),
            ],
          ),
          body: Stack(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _showCustomCollections
                    ? const CustomCollectionsGrid()
                    : const CollectionGrid(),
              ),
            ],
          ),
        );
      },
    );
  }
}