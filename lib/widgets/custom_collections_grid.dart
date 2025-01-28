import 'package:flutter/material.dart';
import 'package:provider/provider.dart';  // Add this
import 'dart:math';
import 'dart:math' as math;
import '../models/custom_collection.dart';
import '../models/tcg_card.dart';  // Add this
import '../services/collection_service.dart';
import '../services/storage_service.dart';  // Add this
import '../screens/custom_collection_detail_screen.dart';
import '../widgets/animated_background.dart';
import '../providers/currency_provider.dart';  // Add this import

class BinderCard extends StatefulWidget {
  final CustomCollection collection;
  final VoidCallback onTap;

  const BinderCard({
    super.key,
    required this.collection,
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TcgCard>>(
      stream: Provider.of<StorageService>(context).watchCards(),
      builder: (context, snapshot) {
        final cards = snapshot.data ?? [];
        final binderCards = cards.where(
          (card) => widget.collection.cardIds.contains(card.id)
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
            child: Container(
              decoration: BoxDecoration(
                color: binderColor,
                borderRadius: BorderRadius.circular(16), // Increased from 12
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
                  // Subtle pattern overlay
                  Positioned.fill(
                    child: CustomPaint(
                      painter: BinderPatternPainter(
                        color: isLightColor 
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.1),
                      ),
                    ),
                  ),
                  // Spine with embossed effect
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
                            color: Colors.black.withOpacity(0.2),
                            offset: const Offset(1, 0),
                            blurRadius: 2,
                          ),
                          BoxShadow(
                            color: Colors.white.withOpacity(0.1),
                            offset: const Offset(-1, 0),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      child: RotatedBox(
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
                    ),
                  ),
                  // Content area
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
                          '${binderCards.length} cards', // Updated to use actual card count
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
                        if (binderCards.isNotEmpty)
                          SizedBox(
                            height: 63,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
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
      },
    );
  }
}

class BinderPatternPainter extends CustomPainter {
  final Color color;

  BinderPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    // Draw subtle horizontal lines instead of diagonal
    for (double y = 0.0; y < size.height; y += 12.0) {
      canvas.drawLine(
        Offset(0.0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CustomCollectionsGrid extends StatelessWidget {
  const CustomCollectionsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBackground(
      child: FutureBuilder<CollectionService>(
        future: CollectionService.getInstance(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final service = snapshot.data!;

          return StreamBuilder<List<CustomCollection>>(
            stream: service.getCustomCollectionsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final collections = snapshot.data ?? [];
              if (collections.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.collections_bookmark_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No custom collections yet',
                        style: TextStyle(fontSize: 18),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Create one using the + button',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: collections.length,
                itemBuilder: (context, index) {
                  final collection = collections[index];
                  return BinderCard(
                    collection: collection,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CustomCollectionDetailScreen(
                          collection: collection,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
