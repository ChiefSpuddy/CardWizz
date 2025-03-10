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
    final colorScheme = Theme.of(context).colorScheme;
    final binderColor = widget.collection.color;
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: binderColor.withOpacity(0.95),
        foregroundColor: ThemeData.estimateBrightnessForColor(binderColor) == Brightness.light
            ? Colors.black
            : Colors.white,
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
                        color: ThemeData.estimateBrightnessForColor(binderColor) == Brightness.light
                            ? Colors.black.withOpacity(0.7)
                            : Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      currencyProvider.formatValue(totalValue),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: ThemeData.estimateBrightnessForColor(binderColor) == Brightness.light
                            ? Colors.black
                            : Colors.white,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        elevation: 0,
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              binderColor.withOpacity(0.3),
              colorScheme.background.withOpacity(0.95),
            ],
            stops: const [0.0, 0.3],
          ),
        ),
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

            // Show cards with enhanced UI
            return _buildCardGrid(context, _cards!, binderColor);
          },
        ),
      ),
    );
  }
  
  Widget _buildCardGrid(BuildContext context, List<TcgCard> cards, Color binderColor) {
    return CustomScrollView(
      slivers: [
        // Binder info section
        SliverToBoxAdapter(
          child: _buildBinderInfoCard(context, cards, binderColor),
        ),
        
        // Quick stats section
        SliverToBoxAdapter(
          child: _buildQuickStats(context, cards),
        ),
        
        // Grid header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cards in Binder',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                FilledButton.tonal(
                  onPressed: _showSortOptions,
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.sort, size: 16),
                      SizedBox(width: 4),
                      Text('Sort'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Actual card grid with enhanced styling
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.7,
              crossAxisSpacing: 10,
              mainAxisSpacing: 12,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final card = cards[index];
                return _buildEnhancedCardItem(context, card, index);
              },
              childCount: cards.length,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildEnhancedCardItem(BuildContext context, TcgCard card, int index) {
    return Hero(
      tag: 'binder_${widget.collection.id}_${card.id}',
      child: Material(
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.3),
        child: InkWell(
          onTap: () => _showCardDetails(context, card),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Card image
              Positioned.fill(
                child: Image.network(
                  card.imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey[800],
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded / 
                                  (loadingProgress.expectedTotalBytes ?? 1)
                              : null,
                          strokeWidth: 2,
                          color: Colors.white70,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[850],
                      child: const Center(
                        child: Icon(Icons.broken_image, color: Colors.white70),
                      ),
                    );
                  },
                ),
              ),
              
              // Bottom info overlay
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Only show price if available
                      if (card.price != null && card.price! > 0)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          child: Text(
                            context.read<CurrencyProvider>().formatValue(card.price!),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              
              // Top rarity indicator
              if (card.rarity != null && card.rarity!.isNotEmpty)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _getRarityColor(card.rarity!),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    child: Text(
                      _formatRarity(card.rarity!),
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  Color _getRarityColor(String rarity) {
    rarity = rarity.toLowerCase();
    if (rarity.contains('secret')) return Colors.purple;
    if (rarity.contains('ultra')) return const Color(0xFFE0AB37);
    if (rarity.contains('rare')) return Colors.blue;
    if (rarity.contains('uncommon')) return Colors.green;
    return Colors.grey;
  }
  
  String _formatRarity(String rarity) {
    if (rarity.toLowerCase().contains('secret')) return 'SCR';
    if (rarity.toLowerCase().contains('ultra')) return 'UR';
    if (rarity.toLowerCase().contains('holo')) return 'HR';
    if (rarity.toLowerCase().contains('rare')) return 'R';
    if (rarity.toLowerCase().contains('uncommon')) return 'UC';
    return 'C';
  }
  
  Widget _buildBinderInfoCard(BuildContext context, List<TcgCard> cards, Color binderColor) {
    final currencyProvider = context.read<CurrencyProvider>();
    final totalValue = cards.fold<double>(0, (sum, card) => sum + (card.price ?? 0));
    final colorBrightness = ThemeData.estimateBrightnessForColor(binderColor);
    final textColor = colorBrightness == Brightness.light ? Colors.black87 : Colors.white;
    
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: binderColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: binderColor.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Binder icon
          Container(
            width: 50,
            height: 60,
            decoration: BoxDecoration(
              color: binderColor,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Spine lines
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 10,
                  child: Container(
                    decoration: BoxDecoration(
                      color: binderColor.withOpacity(0.7),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        bottomLeft: Radius.circular(8),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(
                        4,
                        (index) => Container(
                          width: 6,
                          height: 2,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Card count
                Center(
                  child: Text(
                    '${cards.length}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Binder stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.collection.description.isEmpty
                      ? 'Binder Value'
                      : widget.collection.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currencyProvider.formatValue(totalValue),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuickStats(BuildContext context, List<TcgCard> cards) {
    // Calculate stats
    int raresCount = 0;
    int holoCount = 0;
    int secretRaresCount = 0;
    
    for (final card in cards) {
      final rarity = card.rarity?.toLowerCase() ?? '';
      
      if (rarity.contains('secret') || 
          rarity.contains('ultra') ||
          rarity.contains('alt art')) {
        secretRaresCount++;
      } else if (rarity.contains('holo') || rarity.contains('rare')) {
        holoCount++;
      } else if (rarity.contains('rare')) {
        raresCount++;
      }
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildStatCard(
            context, 
            raresCount, 
            'Rares',
            Colors.blue,
          ),
          const SizedBox(width: 8),
          _buildStatCard(
            context, 
            holoCount, 
            'Holos',
            Colors.amber,
          ),
          const SizedBox(width: 8),
          _buildStatCard(
            context, 
            secretRaresCount, 
            'Ultra Rares',
            Colors.purple,
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatCard(BuildContext context, int count, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                'Sort By',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.attach_money),
              title: const Text('Price (High to Low)'),
              onTap: () {
                setState(() {
                  _cards?.sort((a, b) => (b.price ?? 0).compareTo(a.price ?? 0));
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.money_off),
              title: const Text('Price (Low to High)'),
              onTap: () {
                setState(() {
                  _cards?.sort((a, b) => (a.price ?? 0).compareTo(b.price ?? 0));
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.sort_by_alpha),
              title: const Text('Name (A to Z)'),
              onTap: () {
                setState(() {
                  _cards?.sort((a, b) => a.name.compareTo(b.name));
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.format_list_numbered),
              title: const Text('Card Number'),
              onTap: () {
                setState(() {
                  _cards?.sort((a, b) {
                    final aNum = int.tryParse(a.number ?? '') ?? 0;
                    final bNum = int.tryParse(b.number ?? '') ?? 0;
                    return aNum.compareTo(bNum);
                  });
                });
                Navigator.pop(context);
              },
            ),
          ],
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
