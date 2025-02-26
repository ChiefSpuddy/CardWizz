import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_colors.dart';
import '../../utils/image_utils.dart';

class SetSearchGrid extends StatefulWidget {
  final List<dynamic> sets;
  final Function(String) onSetSelected;
  final Function(String) onSetQuerySelected;

  const SetSearchGrid({
    Key? key,
    required this.sets,
    required this.onSetSelected,
    required this.onSetQuerySelected,
  }) : super(key: key);

  @override
  State<SetSearchGrid> createState() => _SetSearchGridState();
}

class _SetSearchGridState extends State<SetSearchGrid> with TickerProviderStateMixin {
  late AnimationController _animationController;
  final List<AnimationController> _itemControllers = [];
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animationController.forward();
    
    // Initialize hover controllers for each set
    for (int i = 0; i < widget.sets.length; i++) {
      _itemControllers.add(AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 200),
        value: 0,
      ));
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    for (var controller in _itemControllers) {
      controller.dispose();
    }
    super.dispose();
  }
  
  @override
  void didUpdateWidget(SetSearchGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.sets != widget.sets) {
      // Clean up old controllers
      for (var controller in _itemControllers) {
        controller.dispose();
      }
      _itemControllers.clear();
      
      // Create new controllers
      for (int i = 0; i < widget.sets.length; i++) {
        _itemControllers.add(AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 200),
          value: 0,
        ));
      }
      
      // Reset and restart main animation
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.2, // Slightly wider cards
          crossAxisSpacing: 16,
          mainAxisSpacing: 20, // More space between rows
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final dynamic item = widget.sets[index];
            final Map<String, dynamic> set = Map<String, dynamic>.from(item as Map);
            
            // Calculate staggered delay based on index
            final delay = (index % 6) * 100;
            final delayFraction = delay / 1200;
            
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: _animationController,
                curve: Interval(delayFraction, delayFraction + 0.4, curve: Curves.easeOut),
              ),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.2),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(delayFraction, delayFraction + 0.6, curve: Curves.easeOutQuint),
                )),
                child: _buildSetItem(context, set, index),
              ),
            );
          },
          childCount: widget.sets.length,
        ),
      ),
    );
  }
  
  Widget _buildSetItem(BuildContext context, Map<String, dynamic> set, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final releaseDate = set['releaseDate']?.toString() ?? 'Unknown Date';
    final formattedDate = releaseDate.length > 10 ? releaseDate.substring(0, 10) : releaseDate;
    
    return MouseRegion(
      onEnter: (_) => _itemControllers[index].forward(),
      onExit: (_) => _itemControllers[index].reverse(),
      child: AnimatedBuilder(
        animation: _itemControllers[index],
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 + (_itemControllers[index].value * 0.03),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1 + (_itemControllers[index].value * 0.15)),
                    blurRadius: 15 + (_itemControllers[index].value * 10),
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Card(
                elevation: 4,
                shadowColor: Colors.black.withOpacity(0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isDark 
                        ? Colors.grey[800]!.withOpacity(0.5) 
                        : Colors.grey[300]!.withOpacity(0.8),
                    width: 0.5,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    final setName = set['name']?.toString() ?? 'Unknown Set';
                    final setId = set['id']?.toString() ?? '';
                    
                    widget.onSetSelected(setName);
                    widget.onSetQuerySelected('set.id:$setId');
                  },
                  splashColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (set['logo'] != null)
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            child: Image.network(
                              set['logo'].toString(),
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stack) {
                                return Icon(
                                  Icons.auto_awesome,
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                                  size: 32,
                                );
                              },
                            ),
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              set['name']?.toString() ?? 'Unknown Set',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${set['total']?.toString() ?? '?'} cards • $formattedDate',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
