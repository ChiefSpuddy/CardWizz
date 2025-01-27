import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../services/collection_service.dart';  // Add this
import '../models/tcg_card.dart';
import '../models/custom_collection.dart';  // Add this
import '../widgets/collection_grid.dart';
import '../widgets/custom_collections_grid.dart';
import '../widgets/create_collection_sheet.dart';
import 'analytics_screen.dart';
import 'home_screen.dart';
import 'custom_collection_detail_screen.dart';  // Add this
import '../widgets/animated_background.dart';

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

  Widget _buildToggle() {
    return Container(
      height: 36,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12), // Added more bottom margin
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _showCustomCollections = false),
              child: Container(
                decoration: BoxDecoration(
                  color: !_showCustomCollections 
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.style,
                      size: 16,
                      color: !_showCustomCollections
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Main',  // Fixed text
                      style: TextStyle(
                        fontSize: 13,
                        color: !_showCustomCollections
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _showCustomCollections = true),
              child: Container(
                decoration: BoxDecoration(
                  color: _showCustomCollections 
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.collections_bookmark,
                      size: 16,
                      color: _showCustomCollections
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Binders',  // Fixed text
                      style: TextStyle(
                        fontSize: 13,
                        color: _showCustomCollections
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createCollection(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const CreateCollectionSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBackground(
      child: StreamBuilder<List<TcgCard>>(
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
              toolbarHeight: 72,
              centerTitle: false,
              title: cards.isNotEmpty ? SizedBox(
                width: double.infinity,
                child: Row(  // Changed from Wrap to Row
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.style_outlined,
                            size: 16,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${cards.length}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.euro,
                            size: 16,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formatValue(totalValue),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ) : null,
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
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48), // Increased from 36
                child: _buildToggle(),
              ),
            ),
            drawer: Drawer(
              child: ListView(
                children: [
                  const DrawerHeader(
                    decoration: BoxDecoration(
                      color: Colors.blue,
                    ),
                    child: Text('Menu'),
                  ),
                  // Custom Collections section
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Binders',  // Updated text
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  FutureBuilder<CollectionService>(
                    future: CollectionService.getInstance(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox();
                      
                      return StreamBuilder<List<CustomCollection>>(
                        stream: snapshot.data!.getCustomCollectionsStream(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const SizedBox();
                          
                          final collections = snapshot.data!;
                          return Column(
                            children: collections.map((collection) => ListTile(
                              leading: const Icon(Icons.folder_outlined),
                              title: Text(collection.name),
                              subtitle: Text('${collection.cardIds.length} cards'),
                              trailing: collection.totalValue != null
                                  ? Text('€${collection.totalValue!.toStringAsFixed(2)}')
                                  : null,
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CustomCollectionDetailScreen(
                                      collection: collection,
                                    ),
                                  ),
                                );
                              },
                            )).toList(),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
            body: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _showCustomCollections
                  ? const CustomCollectionsGrid()
                  : const CollectionGrid(),
            ),
            floatingActionButton: _showCustomCollections
                ? FloatingActionButton.extended(
                    onPressed: () => _createCollection(context),
                    elevation: 4,
                    backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                    foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
                    label: const Text('New Binder'),
                    icon: const Icon(Icons.add),
                  )
                : null,
          );
        },
      ),
    );
  }
}