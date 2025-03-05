import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../services/collection_service.dart';
import '../services/auth_service.dart';
import '../providers/app_state.dart';
import '../screens/debug_collection_screen.dart';
import '../models/tcg_card.dart';  // Keep this import - it includes TcgSet
// Remove this import since it causes conflict: import '../models/tcg_set.dart';

class DevMenu extends StatelessWidget {
  const DevMenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.developer_mode),
      onPressed: () => _showDevMenu(context),
    );
  }

  void _showDevMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => _buildDevMenuContent(context, scrollController),
      ),
    );
  }

  Widget _buildDevMenuContent(BuildContext context, ScrollController scrollController) {
    final storageService = Provider.of<StorageService>(context);
    final collectionService = Provider.of<CollectionService>(context);
    final authService = Provider.of<AuthService>(context);
    final appState = Provider.of<AppState>(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Developer Menu',
                // Fix: headline6 -> titleLarge
                style: Theme.of(context).textTheme.titleLarge,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildSectionHeader(context, 'Authentication'),
              _buildInfoRow('User ID', authService.currentUser?.id ?? 'Not logged in'),
              _buildInfoRow('Is Authenticated', appState.isAuthenticated.toString()),
              _buildButton(
                context: context,
                icon: Icons.refresh,
                label: 'Reinitialize User Data',
                onPressed: () async {
                  if (authService.currentUser != null) {
                    await appState.ensureStorageSync();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('User data reinitialized')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No user logged in')),
                    );
                  }
                },
              ),
              const Divider(),
              _buildSectionHeader(context, 'Collection Data'),
              _buildInfoRow('Card Count', storageService.cardCount.toString()),
              _buildButton(
                context: context,
                icon: Icons.inventory_2,
                label: 'Open Debug Collection Screen',
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DebugCollectionScreen(),
                    ),
                  );
                },
              ),
              _buildButton(
                context: context,
                icon: Icons.bug_report,
                label: 'Debug & Fix Cards',
                onPressed: () async {
                  await storageService.debugAndFixCards();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Card debug complete')),
                  );
                },
              ),
              _buildButton(
                context: context,
                icon: Icons.refresh,
                label: 'Force Card Refresh',
                onPressed: () async {
                  await storageService.refreshCards();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cards refreshed')),
                  );
                },
              ),
              const Divider(),
              _buildSectionHeader(context, 'Test Actions'),
              _buildButton(
                context: context,
                icon: Icons.add_card,
                label: 'Add Test Card',
                onPressed: () async {
                  try {
                    final testCard = _createTestCard();
                    await storageService.addCard(testCard);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Test card added: ${testCard.name}')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        // Fix: subtitle1 -> titleMedium
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }

  // Replace the _buildInfoRow method to handle long user IDs
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Label with fixed size
          Expanded(
            flex: 2,
            child: Text(label),
          ),
          const SizedBox(width: 8),
          // Value with flexible space that can wrap if needed
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ElevatedButton.icon(
        icon: Icon(icon),
        label: Text(label),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // Helper method to create a test card
  TcgCard _createTestCard() {
    final now = DateTime.now();
    return TcgCard(
      id: 'test_card_${now.millisecondsSinceEpoch}',
      name: 'Debug Test Card',
      number: '000',
      imageUrl: 'https://images.pokemontcg.io/sv8/239_hires.png',
      largeImageUrl: 'https://images.pokemontcg.io/sv8/239_hires.png',
      set: TcgSet(id: 'test', name: 'Test Set'),  // This will use TcgSet from tcg_card.dart
      price: 99.99,
      rarity: 'Test Rare',
      dateAdded: now,
      addedToCollection: now,
    );
  }
}
