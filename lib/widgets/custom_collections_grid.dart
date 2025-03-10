import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'dart:math' as math;
import 'dart:async';  // Add this import for StreamSubscription
import 'package:async/async.dart' show StreamGroup;  // Add this import
import '../models/custom_collection.dart';
import '../models/tcg_card.dart';  // Add this
import '../services/collection_service.dart';
import '../services/storage_service.dart';  // Add this
import '../screens/custom_collection_detail_screen.dart';
import '../widgets/animated_background.dart';
import '../providers/currency_provider.dart';  // Add this import
import '../providers/sort_provider.dart';  // Add this import
import 'package:flutter/foundation.dart';  // Add this for listEquals
import 'package:rxdart/rxdart.dart' as rx;  // Add this for Rx

class BinderCard extends StatefulWidget {
  final CustomCollection collection;
  final List<TcgCard> cards;  // Add this
  final VoidCallback onTap;

  const BinderCard({
    super.key,
    required this.collection,
    required this.cards,  // Add this
    required this.onTap,
  });

  @override
  State<BinderCard> createState() => _BinderCardState();
}

class _BinderCardState extends State<BinderCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward(from: 0);
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  Future<void> _showDeleteDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Binder?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "${widget.collection.name}"?'),
            const SizedBox(height: 8),
            Text(
              '${widget.collection.cardIds.length} cards will be removed from this binder.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete_forever),
            label: const Text('Delete'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final service = await CollectionService.getInstance();
        await service.deleteCollection(widget.collection.id);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${widget.collection.name} deleted'),
              duration: const Duration(seconds: 2), // Reduced from default 4
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () {
                  // TODO: Implement undo functionality
                },
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting binder: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Match cards by ID
    final binderCards = widget.cards.where(
      (card) => widget.collection.cardIds.contains(card.id.trim())
    ).toList();
    
    final currencyProvider = context.watch<CurrencyProvider>();
    final binderColor = widget.collection.color;
    final isLightColor = ThemeData.estimateBrightnessForColor(binderColor) == Brightness.light;
    final textColor = isLightColor ? Colors.black87 : Colors.white;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final wobble = math.sin(_controller.value * math.pi * 2) * 0.025;
        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.002) // Increased perspective
            ..rotateY(wobble)
            ..scale(_isPressed ? 0.95 : 1.0),
          alignment: Alignment.center,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onLongPress: () => _showDeleteDialog(context),
        child: Container(
          decoration: BoxDecoration(
            color: binderColor,
            borderRadius: BorderRadius.circular(16), 
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                binderColor,
                HSLColor.fromColor(binderColor)
                    .withLightness((HSLColor.fromColor(binderColor).lightness * 0.85))
                    .toColor(),
              ],
              stops: const [0.3, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: binderColor.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Improved pattern overlay - leather texture instead of lines
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CustomPaint(
                    painter: BinderTexturePainter(
                      color: isLightColor 
                          ? Colors.white.withOpacity(0.08)
                          : Colors.black.withOpacity(0.08),
                      accentColor: isLightColor
                          ? Colors.black.withOpacity(0.04)
                          : Colors.white.withOpacity(0.03),
                    ),
                  ),
                ),
              ),
              
              // Add subtle highlight at the top
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 40,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(isLightColor ? 0.15 : 0.07),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              
              // Enhanced spine with more realistic binding effect
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 28,
                child: Container(
                  decoration: BoxDecoration(
                    color: HSLColor.fromColor(binderColor)
                        .withLightness((HSLColor.fromColor(binderColor).lightness * 0.8))
                        .toColor(),
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        offset: const Offset(1, 0),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Spine texture
                      Positioned.fill(
                        child: CustomPaint(
                          painter: BinderSpinePainter(
                            color: isLightColor 
                                ? Colors.black.withOpacity(0.06)
                                : Colors.white.withOpacity(0.04),
                          ),
                        ),
                      ),
                      // Binding rings effect
                      Positioned(
                        top: 0,
                        bottom: 0,
                        left: 0,
                        width: 6,
                        child: Container(
                          decoration: BoxDecoration(
                            color: HSLColor.fromColor(binderColor)
                                .withLightness((HSLColor.fromColor(binderColor).lightness * 0.7))
                                .toColor(),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 1,
                                offset: const Offset(1, 0),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Title text
                      RotatedBox(
                        quarterTurns: 1,
                        child: Center(
                          child: Text(
                            widget.collection.name.toUpperCase(),
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              letterSpacing: 1.2,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.3),
                                  offset: const Offset(0, 1),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Content area - keep this as is since you like it
              // ...existing content area code...
              Padding(
                padding: const EdgeInsets.fromLTRB(36, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.collection.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.2),
                            offset: const Offset(0, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${binderCards.length} cards', 
                      style: TextStyle(
                        color: ThemeData.estimateBrightnessForColor(widget.collection.color) == Brightness.light
                          ? Colors.black54
                          : Colors.white70,
                      ),
                    ),
                    const Spacer(),
                    if (widget.collection.totalValue != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          currencyProvider.formatValue(widget.collection.totalValue!),
                          style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    // CHANGE: Always include the SizedBox height placeholder, regardless of cards
                    SizedBox(
                      height: 63,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Only add card images when there are cards
                          if (binderCards.isNotEmpty)
                            for (var i = 0; i < min(3, binderCards.length); i++)
                              Positioned(
                                right: i * 12.0,
                                child: Transform.rotate(
                                  angle: (i - 1) * 0.1,
                                  child: Container(
                                    width: 45,
                                    height: 63,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(6),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: Image.network(
                                        binderCards[binderCards.length - 1 - i].imageUrl,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          
                          // ADD: Show an empty placeholder when there are no cards
                          if (binderCards.isEmpty)
                            Positioned(
                              right: 0,
                              child: Container(
                                width: 45,
                                height: 63,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  color: Colors.black.withOpacity(0.1),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.add_photo_alternate_outlined,
                                    color: Colors.white.withOpacity(0.4),
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
            ],
          ),
        ),
      ),
    );
  }
}

// Replace the simple line painter with a more appealing texture painter
class BinderTexturePainter extends CustomPainter {
  final Color color;
  final Color accentColor;
  
  BinderTexturePainter({required this.color, required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;
    
    final accentPaint = Paint()
      ..color = accentColor
      ..strokeWidth = 1.0;

    final random = math.Random(42); // Fixed seed for consistent pattern
    
    // Create a leather-like texture with small dots and marks
    for (int i = 0; i < size.width * size.height / 120; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 2.5;
      
      canvas.drawCircle(Offset(x, y), radius, paint);
      
      // Add some subtle line marks
      if (i % 5 == 0) {
        final startX = x - 2 + random.nextDouble() * 4;
        final startY = y - 2 + random.nextDouble() * 4;
        final endX = startX + random.nextDouble() * 6 - 3;
        final endY = startY + random.nextDouble() * 6 - 3;
        
        canvas.drawLine(
          Offset(startX, startY),
          Offset(endX, endY),
          accentPaint,
        );
      }
    }
    
    // Add subtle grain texture
    for (int i = 0; i < size.width; i += 4) {
      for (int j = 0; j < size.height; j += 4) {
        if (random.nextDouble() < 0.2) {
          final x = i + random.nextDouble() * 4;
          final y = j + random.nextDouble() * 4;
          canvas.drawCircle(Offset(x, y), 0.5, accentPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Add a spine-specific texture painter
class BinderSpinePainter extends CustomPainter {
  final Color color;
  
  BinderSpinePainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
      
    // Create subtle horizontal ridges for the spine
    for (double y = 5.0; y < size.height - 5; y += 8.0) {
      // Slightly randomize the spacing
      final offsetY = y + (y % 16 == 0 ? 1 : 0);
      
      // Draw the ridge
      canvas.drawLine(
        Offset(2.0, offsetY),
        Offset(size.width - 2, offsetY),
        paint,
      );
      
      // Add a highlight above the ridge
      final highlightPaint = Paint()
        ..color = Colors.white.withOpacity(0.15)
        ..strokeWidth = 0.5;
        
      canvas.drawLine(
        Offset(2.0, offsetY - 0.5),
        Offset(size.width - 2, offsetY - 0.5),
        highlightPaint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CustomCollectionsGrid extends StatefulWidget {
  final bool keepAlive;  // Add this
  final Function(bool)? onMultiselectChange;

  const CustomCollectionsGrid({
    super.key,
    this.keepAlive = false,
    this.onMultiselectChange,
  });

  @override
  State<CustomCollectionsGrid> createState() => CustomCollectionsGridState();
}

class CustomCollectionsGridState extends State<CustomCollectionsGrid> with AutomaticKeepAliveClientMixin {
  late final CollectionService _collectionService;
  bool _isInitialized = false;
  
  // Add these for multiselect functionality
  Set<String> _selectedCollectionIds = {};
  bool _isMultiselect = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    if (_isInitialized) return;
    _collectionService = await CollectionService.getInstance();
    if (mounted) {
      setState(() => _isInitialized = true);
    }
  }
  
  // Add these methods to handle multiselect state
  
  void toggleMultiselect() {
    setState(() {
      _isMultiselect = !_isMultiselect;
      if (!_isMultiselect) {
        _selectedCollectionIds.clear();
      }
      
      // Notify parent about multiselect state
      if (widget.onMultiselectChange != null) {
        widget.onMultiselectChange!(_isMultiselect);
      }
    });
  }
  
  void cancelMultiselect() {
    if (_isMultiselect) {
      setState(() {
        _isMultiselect = false;
        _selectedCollectionIds.clear();
        
        // Notify parent about multiselect state change
        if (widget.onMultiselectChange != null) {
          widget.onMultiselectChange!(false);
        }
      });
    }
  }
  
  void removeSelected() async {
    if (_selectedCollectionIds.isEmpty) return;
    
    // Implement actual removal logic
    try {
      for (final id in _selectedCollectionIds) {
        await _collectionService.deleteCollection(id);
      }
      
      setState(() {
        _isMultiselect = false;
        _selectedCollectionIds.clear();
        
        // Notify parent
        if (widget.onMultiselectChange != null) {
          widget.onMultiselectChange!(false);
        }
      });
    } catch (e) {
      print('Error removing collections: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    // Single StreamBuilder for collections
    return StreamBuilder<List<CustomCollection>>(
      stream: _collectionService.getCustomCollectionsStream(),
      builder: (context, collectionsSnapshot) {
        if (collectionsSnapshot.hasError) {
          return Center(child: Text('Error: ${collectionsSnapshot.error}'));
        }

        final collections = collectionsSnapshot.data ?? [];
        print('Rendering ${collections.length} binders'); // Debug print

        if (collections.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.collections_bookmark_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No binders yet', style: TextStyle(fontSize: 18)),
                SizedBox(height: 8),
                Text('Create one using the + button', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        // Sort collections
        final sortedCollections = _collectionService.sortCollections(
          collections,
          context.read<SortProvider>().currentSort
        );

        // Single StreamBuilder for cards
        return StreamBuilder<List<TcgCard>>(
          stream: Provider.of<StorageService>(context).watchCards(),
          builder: (context, cardsSnapshot) {
            final allCards = cardsSnapshot.data ?? [];
            print('DEBUG: Total available cards: ${allCards.length}');
            
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.85,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: sortedCollections.length,
              itemBuilder: (context, index) {
                final collection = sortedCollections[index];
                final isSelected = _selectedCollectionIds.contains(collection.id);
                
                print('DEBUG: Collection ${collection.name} has IDs: ${collection.cardIds.join(', ')}');
                
                return GestureDetector(
                  onLongPress: () {
                    if (!_isMultiselect) {
                      setState(() {
                        _isMultiselect = true;
                        _selectedCollectionIds.add(collection.id);
                        
                        // Notify parent
                        if (widget.onMultiselectChange != null) {
                          widget.onMultiselectChange!(true);
                        }
                      });
                    }
                  },
                  onTap: () {
                    if (_isMultiselect) {
                      setState(() {
                        if (isSelected) {
                          _selectedCollectionIds.remove(collection.id);
                          if (_selectedCollectionIds.isEmpty) {
                            _isMultiselect = false;
                            if (widget.onMultiselectChange != null) {
                              widget.onMultiselectChange!(false);
                            }
                          }
                        } else {
                          _selectedCollectionIds.add(collection.id);
                        }
                      });
                    } else {
                      // Regular navigation
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CustomCollectionDetailScreen(
                            collection: collection,
                            initialCards: allCards.where(
                              (card) => collection.cardIds.contains(card.id.trim())
                            ).toList(),
                          ),
                        ),
                      );
                    }
                  },
                  child: Stack(
                    children: [
                      BinderCard(
                        collection: collection,
                        cards: allCards,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CustomCollectionDetailScreen(
                              collection: collection,
                              initialCards: allCards.where(
                                (card) => collection.cardIds.contains(card.id.trim())
                              ).toList(),
                            ),
                          ),
                        ),
                      ),
                      if (_isMultiselect)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected 
                                ? Theme.of(context).colorScheme.primary
                                : Colors.white.withOpacity(0.8),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,
                              ),
                            ),
                            child: isSelected 
                              ? const Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Colors.white,
                                )
                              : null,
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}
