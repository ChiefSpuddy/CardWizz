import 'package:flutter/material.dart';
import 'package:provider/provider.dart';  // Add this import
import '../models/custom_collection.dart';
import '../models/tcg_card.dart';
import '../services/collection_service.dart';
import '../services/storage_service.dart';
import '../widgets/card_grid_item.dart';
import '../screens/card_details_screen.dart';  // Add this import
import '../providers/currency_provider.dart';  // Add this import
import '../widgets/animated_background.dart';  // Add this import
import '../screens/home_screen.dart';  // Add this import
import '../screens/collections_screen.dart';  // Add this import

class CustomCollectionDetailScreen extends StatefulWidget {
  final CustomCollection collection;
  final List<TcgCard>? initialCards;  // Add this

  const CustomCollectionDetailScreen({
    super.key,
    required this.collection,
    this.initialCards,  // Add this
  });

  @override
  State<CustomCollectionDetailScreen> createState() => _CustomCollectionDetailScreenState();
}

class _CustomCollectionDetailScreenState extends State<CustomCollectionDetailScreen> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  List<TcgCard>? _cards;  // Add this field

  // Add binder colors
  final List<Color> _binderColors = [
    const Color(0xFF90CAF9),  // Light Blue
    const Color(0xFFF48FB1),  // Pink
    const Color(0xFFA5D6A7),  // Light Green
    const Color(0xFFFFCC80),  // Orange
    const Color(0xFFE1BEE7),  // Purple
    const Color(0xFFBCAAA4),  // Brown
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.collection.name);
    _descriptionController = TextEditingController(text: widget.collection.description);
    _cards = widget.initialCards;  // Initialize cards from widget parameter
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _editDetails() async {
    final service = await CollectionService.getInstance();
    Color selectedColor = widget.collection.color;

    // Use the same color palette as create binder dialog
    final binderColors = const [
      // Blues
      Color(0xFF90CAF9),
      Color(0xFF42A5F5),
      Color(0xFF1976D2),
      // Greens
      Color(0xFF81C784),
      Color(0xFF66BB6A),
      Color(0xFF388E3C),
      // Oranges & Yellows
      Color(0xFFFFB74D),
      Color(0xFFFFA726),
      Color(0xFFFBC02D),
      // Reds & Pinks
      Color(0xFFE57373),
      Color(0xFFF06292),
      Color(0xFFEC407A),
      // Purples
      Color(0xFFBA68C8),
      Color(0xFF9575CD),
      Color(0xFF7E57C2),
      // Others
      Color(0xFF4DB6AC),
      Color(0xFF26A69A),
      Color(0xFF78909C),
    ];
    
    final result = await showDialog<(bool, Color)>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Binder'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 24),
                const Text('Binder Color'),
                const SizedBox(height: 16),
                Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.25,
                  ),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: binderColors.length,
                    itemBuilder: (context, index) {
                      final color = binderColors[index];
                      final isSelected = selectedColor == color;
                      final isLightColor = ThemeData.estimateBrightnessForColor(color) == Brightness.light;

                      return GestureDetector(
                        onTap: () => setState(() => selectedColor = color),
                        child: Container(
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: isSelected
                              ? Icon(
                                  Icons.check,
                                  color: isLightColor ? Colors.black87 : Colors.white,
                                  size: 20,
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, (false, selectedColor)),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, (true, selectedColor)),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result?.$1 == true) {
      await service.updateCollectionDetails(
        widget.collection.id,
        _nameController.text,
        _descriptionController.text,
        color: result!.$2,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyProvider = context.watch<CurrencyProvider>();
    
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.collection.name),
            StreamBuilder<List<TcgCard>>(
              stream: Provider.of<StorageService>(context).watchCards(),
              builder: (context, snapshot) {
                final cards = snapshot.data ?? [];
                final binderCards = cards.where(
                  (card) => widget.collection.cardIds.contains(card.id)
                ).toList();
                
                final totalValue = binderCards.fold<double>(
                  0,
                  (sum, card) => sum + (card.price ?? 0),
                );

                return Row(
                  children: [
                    Text(
                      '${binderCards.length} cards',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      currencyProvider.formatValue(totalValue),  // Update this line
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editDetails,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Collection'),
                  content: const Text('Are you sure you want to delete this collection?'),
                  actions: [
                    TextButton(
                      child: const Text('Cancel'),
                      onPressed: () => Navigator.pop(context, false),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Delete'),
                      onPressed: () => Navigator.pop(context, true),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                final service = await CollectionService.getInstance();
                await service.deleteCollection(widget.collection.id);
                if (mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: AnimatedBackground(  // Wrap the body with AnimatedBackground
        child: StreamBuilder<List<TcgCard>>(
          stream: Provider.of<StorageService>(context).watchCards(),
          builder: (context, snapshot) {
            if (!snapshot.hasData && _cards == null) {
              return const Center(child: CircularProgressIndicator());
            }

            final allCards = snapshot.data ?? [];
            _cards ??= allCards.where(
              (card) => widget.collection.cardIds.contains(card.id)
            ).toList();

            if (_cards!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.style_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'This binder is empty',
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add cards from your collection',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      height: 46,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(23),
                        gradient: LinearGradient(
                          colors: Theme.of(context).brightness == Brightness.dark ? [
                            Colors.blue[700]!,
                            Colors.blue[900]!,
                          ] : [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.secondary,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).popUntil((route) => route.isFirst);
                          if (mounted) {
                            // First find HomeScreenState to switch to collections tab
                            final homeState = context.findAncestorStateOfType<HomeScreenState>();
                            if (homeState != null) {
                              homeState.setSelectedIndex(1);
                            }
                            // Then find CollectionsScreen to toggle view
                            final collectionsScreen = context.findRootAncestorStateOfType<CollectionsScreenState>();
                            if (collectionsScreen != null) {
                              collectionsScreen.showCustomCollections = false;
                            }
                            Navigator.popUntil(context, (route) => route.isFirst);
                          }
                        },
                        icon: const Icon(Icons.style, color: Colors.white),
                        label: const Text(
                          'Go to Collection',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.7,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _cards!.length,
              itemBuilder: (context, index) {
                final card = _cards![index];
                return CardGridItem(
                  card: card,
                  onTap: () => _showCardDetails(context, card),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _showCardDetails(BuildContext context, TcgCard card) {
    if (!mounted) return;
    // Add check to ensure we're not in the middle of navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CardDetailsScreen(
            card: card,
            heroContext: 'binder_${widget.collection.id}',  // Make hero tag unique
            isFromBinder: true,  // Always true when viewing from binder
          ),
        ),
      );
    });
  }
}
