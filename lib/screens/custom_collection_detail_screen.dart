import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math'; // Add this import for math functions like sin, pi, and Random
import '../models/custom_collection.dart';
import '../models/tcg_card.dart';
import '../services/collection_service.dart';
import '../services/storage_service.dart';
import '../widgets/card_grid_item.dart';
import '../screens/card_details_screen.dart';
import '../providers/currency_provider.dart';
import '../widgets/animated_background.dart';
import '../screens/home_screen.dart';
import '../screens/collections_screen.dart';
import '../root_navigator.dart';  

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
              return _buildEmptyState(context);
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
                  heroContext: widget.collection.id,
                  showPrice: false,
                  onTap: () => _showCardDetails(context, card),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final binderColor = widget.collection.color;
    final brightness = ThemeData.estimateBrightnessForColor(binderColor);
    final contrastColor = brightness == Brightness.light ? Colors.black87 : Colors.white;
    
    return Stack(
      children: [
        // Decorative background elements - subtle pattern matching the binder color
        Positioned.fill(
          child: CustomPaint(
            painter: EmptyBinderPatternPainter(
              color: binderColor.withOpacity(0.06),
              accentColor: binderColor.withOpacity(0.1),
            ),
          ),
        ),
        
        // Main content with scroll for smaller screens
        Positioned.fill(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  
                  // Empty binder illustration
                  Container(
                    width: 160,
                    height: 200,
                    decoration: BoxDecoration(
                      color: binderColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: binderColor.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Left spine
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          width: 20,
                          child: Container(
                            decoration: BoxDecoration(
                              color: binderColor,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(10),
                                bottomLeft: Radius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        
                        // Rings on spine
                        ...List.generate(
                          5,
                          (index) => Positioned(
                            left: 10,
                            top: 30.0 + (index * 30.0),
                            width: 12,
                            height: 8,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                        
                        // Empty card slots
                        ...List.generate(
                          3,
                          (index) => Positioned(
                            right: 15 + (index * 4.0),
                            top: 70 + (index * 5.0),
                            child: Container(
                              width: 45,
                              height: 63,
                              decoration: BoxDecoration(
                                color: binderColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: binderColor.withOpacity(0.5),
                                  width: 1,
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.add_rounded,
                                  color: binderColor.withOpacity(0.6),
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                        // Add card icon with animation
                        Positioned(
                          right: 50,
                          bottom: 40,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(seconds: 1),
                            builder: (context, value, child) {
                              return Transform.translate(
                                offset: Offset(0, -5 * sin(value * 2 * pi).toDouble()), // Fix: Convert num to double
                                child: child,
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: colorScheme.primary.withOpacity(0.4),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.add_photo_alternate_outlined,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Title with binder name 
                  Text(
                    widget.collection.name,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onBackground,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Empty state text
                  Text(
                    'Your binder is ready for cards',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // UPDATED: Two ways to add cards (removed scan option)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Add cards from:',
                          style: Theme.of(context).textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        
                        // Two ways to add cards
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // From Collection option
                            _buildAddOption(
                              context: context,
                              icon: Icons.style_outlined,
                              label: 'Collection',
                              color: Colors.blue,
                              onTap: () {
                                Navigator.of(context).pop();
                                final rootNavigatorState = Navigator.of(context, rootNavigator: true)
                                    .context.findRootAncestorStateOfType<RootNavigatorState>();
                                if (rootNavigatorState != null) {
                                  rootNavigatorState.switchToTab(1);
                                  Future.delayed(const Duration(milliseconds: 100), () {
                                    final collectionsScreenState = rootNavigatorState.context
                                        .findAncestorStateOfType<CollectionsScreenState>();
                                    if (collectionsScreenState != null) {
                                      collectionsScreenState.showCustomCollections = false;
                                    }
                                  });
                                }
                              },
                            ),
                            
                            // From Search option 
                            _buildAddOption(
                              context: context,
                              icon: Icons.search,
                              label: 'Search',
                              color: Colors.green,
                              onTap: () {
                                Navigator.of(context).pushNamed('/search');
                              },
                            ),
                            
                            // Scan option removed
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Tips section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.primary.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.lightbulb_outline),
                            const SizedBox(width: 8),
                            Text(
                              'Tips',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildTipItem(
                          context: context, 
                          text: 'Use search to find specific cards by name'
                        ),
                        _buildTipItem(
                          context: context, 
                          text: 'Scan cards with your camera to instantly add them'
                        ),
                        _buildTipItem(
                          context: context, 
                          text: 'Create multiple binders for different categories'
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  // Helper method to build add options
  Widget _buildAddOption({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  // Helper method to build tip items
  Widget _buildTipItem({required BuildContext context, required String text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 16,
            color: Colors.green,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text),
          ),
        ],
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

// Add a custom painter for the empty binder background pattern
class EmptyBinderPatternPainter extends CustomPainter {
  final Color color;
  final Color accentColor;
  
  EmptyBinderPatternPainter({required this.color, required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()..color = color;
    final accentPaint = Paint()..color = accentColor;
    final random = Random(42); // Now Random is defined from dart:math import
    
    // Draw subtle dots
    for (int i = 0; i < 300; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = 0.5 + random.nextDouble() * 1.5;
      
      canvas.drawCircle(Offset(x, y), radius, dotPaint);
    }
    
    // Draw a few larger accent circles
    for (int i = 0; i < 30; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = 2.0 + random.nextDouble() * 4.0;
      
      canvas.drawCircle(Offset(x, y), radius, accentPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
