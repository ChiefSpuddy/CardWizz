import 'package:flutter/material.dart';
import 'package:provider/provider.dart';  // Add this import
import '../models/custom_collection.dart';
import '../models/tcg_card.dart';
import '../services/collection_service.dart';
import '../services/storage_service.dart';
import '../widgets/card_grid_item.dart';
import '../screens/card_details_screen.dart';  // Add this import

class CustomCollectionDetailScreen extends StatefulWidget {
  final CustomCollection collection;

  const CustomCollectionDetailScreen({
    super.key,
    required this.collection,
  });

  @override
  State<CustomCollectionDetailScreen> createState() => _CustomCollectionDetailScreenState();
}

class _CustomCollectionDetailScreenState extends State<CustomCollectionDetailScreen> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;

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
    
    final result = await showDialog<(bool, Color)>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Binder'),
          content: Column(
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
              const SizedBox(height: 16),
              const Text('Binder Color'),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: _binderColors.map((color) => 
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () {
                          setState(() => selectedColor = color);
                        },
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: color == selectedColor
                                ? Theme.of(context).colorScheme.primary
                                : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: color == selectedColor
                            ? Icon(
                                Icons.check,
                                color: ThemeData.estimateBrightnessForColor(color) == Brightness.light
                                  ? Colors.black
                                  : Colors.white,
                              )
                            : null,
                        ),
                      ),
                    ),
                  ).toList(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context, (false, selectedColor)),
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () => Navigator.pop(context, (true, selectedColor)),
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
                      '€${totalValue.toStringAsFixed(2)}',
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
      body: StreamBuilder<List<TcgCard>>(
        stream: Provider.of<StorageService>(context).watchCards(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allCards = snapshot.data!;
          final collectionCards = allCards
              .where((card) => widget.collection.cardIds.contains(card.id))
              .toList();

          if (collectionCards.isEmpty) {
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
            itemCount: collectionCards.length,
            itemBuilder: (context, index) {
              final card = collectionCards[index];
              return CardGridItem(
                card: card,
                onTap: () => _showCardDetails(context, card),
              );
            },
          );
        },
      ),
    );
  }

  void _showCardDetails(BuildContext context, TcgCard card) {
    // Implement card details navigation
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CardDetailsScreen(card: card),
      ),
    );
  }
}
