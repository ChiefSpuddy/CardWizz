import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/tcg_card.dart';
import '../../constants/app_colors.dart';

class CardGridItem extends StatefulWidget {
  final TcgCard card;
  final bool showName;
  final bool showPrice;
  final bool showRarity;
  final VoidCallback onTap;
  final double elevation;
  final double borderRadius;

  const CardGridItem({
    Key? key,
    required this.card,
    this.showName = true,
    this.showPrice = false,
    this.showRarity = true,
    required this.onTap,
    this.elevation = 2.0,
    this.borderRadius = 16.0,
  }) : super(key: key);

  @override
  State<CardGridItem> createState() => _CardGridItemState();
}

class _CardGridItemState extends State<CardGridItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasPrice = widget.card.price != null && widget.card.price! > 0;
    final rarityColor = _getRarityColor(widget.card.rarity ?? '');
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: child,
      ),
      child: GestureDetector(
        onTapDown: (_) {
          _controller.forward();
          HapticFeedback.selectionClick();
        },
        onTapUp: (_) {
          _controller.reverse();
          widget.onTap();
        },
        onTapCancel: () {
          _controller.reverse();
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08 * widget.elevation),
                blurRadius: 8.0 * widget.elevation / 2,
                offset: Offset(0, 3.0 * widget.elevation / 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? [Colors.grey.shade900, Colors.black.withOpacity(0.7)]
                      : [Colors.white, Colors.grey.shade50],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Card image with overlay
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Card image with hero animation
                        Hero(
                          tag: 'card_image_${widget.card.id}',
                          child: Image.network(
                            widget.card.imageUrl,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded / 
                                        loadingProgress.expectedTotalBytes!
                                      : null,
                                  strokeWidth: 2,
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                                ),
                              );
                            },
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.image_not_supported_outlined),
                            ),
                          ),
                        ),
                        
                        // Rarity border indicator at the top
                        if ((widget.card.rarity?.isNotEmpty ?? false) && rarityColor != Colors.transparent)
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 4,
                              decoration: BoxDecoration(
                                color: rarityColor,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        
                        // Price indicator
                        if (widget.showPrice && hasPrice)
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.getValueColor(widget.card.price!),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                '\$${widget.card.price!.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          
                        // Set number in bottom left
                        if (widget.card.number?.isNotEmpty ?? false)
                          Positioned(
                            bottom: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: isDark 
                                    ? Colors.black.withOpacity(0.6)
                                    : Colors.white.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '#${widget.card.number}',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  // Optional card name section
                  if (widget.showName)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black : Colors.white,
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(widget.borderRadius - 1),
                        ),
                      ),
                      child: Text(
                        widget.card.name,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  // Helper method to get appropriate color based on rarity
  Color _getRarityColor(String rarity) {
    final rarityLower = rarity.toLowerCase();
    
    if (rarityLower.contains('hyper') || rarityLower.contains('secret')) {
      return const Color(0xFF9333EA); // Purple for hyper/secret
    } else if (rarityLower.contains('ultra')) {
      return const Color(0xFFEA580C); // Orange for ultra rare
    } else if (rarityLower.contains('rare') && !rarityLower.contains('ultra')) {
      return const Color(0xFFEAB308); // Gold for rare
    } else if (rarityLower.contains('uncommon')) {
      return const Color(0xFF0EA5E9); // Blue for uncommon
    } else {
      return Colors.transparent; // No border for common
    }
  }
  
  // Format rarity for display
  String _formatRarity(String rarity) {
    if (rarity.isEmpty) return '';
    
    final rarityLower = rarity.toLowerCase();
    if (rarityLower.contains('secret')) return 'SR';
    if (rarityLower.contains('hyper')) return 'HR';
    if (rarityLower.contains('ultra')) return 'UR';
    if (rarityLower.contains('rare') && !rarityLower.contains('ultra')) return 'R';
    if (rarityLower.contains('uncommon')) return 'UC';
    if (rarityLower.contains('common')) return 'C';
    
    // Return first letter if unknown
    return rarity[0].toUpperCase();
  }
}
