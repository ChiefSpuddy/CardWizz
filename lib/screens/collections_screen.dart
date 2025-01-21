import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../widgets/collection_grid.dart';
import '../widgets/custom_collections_grid.dart';  // Add this import

class CollectionsScreen extends StatefulWidget {
  const CollectionsScreen({super.key});

  @override
  State<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends State<CollectionsScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  bool _showCustomCollections = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
    _animationController.forward();
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: LayoutBuilder(
          builder: (context, constraints) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Flexible(
                  child: Text(
                    'My Collection',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 32,
                  child: ToggleButtons(
                    constraints: const BoxConstraints(
                      minWidth: 52,
                      minHeight: 32,
                    ),
                    isSelected: [!_showCustomCollections, _showCustomCollections],
                    onPressed: (index) {
                      setState(() {
                        _showCustomCollections = index == 1;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    selectedColor: Colors.white,
                    fillColor: Colors.green.shade600,
                    color: isDark ? Colors.grey[400] : Colors.grey[700],
                    children: const [
                      Text('Cards', style: TextStyle(fontSize: 12)),
                      Text('Sets', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: () {
              // TODO: Navigate to analytics
            },
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () {
              // TODO: Implement sorting
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.3,
              child: Lottie.asset(
                'assets/animations/background.json',
                fit: BoxFit.cover,
                repeat: true,
                frameRate: FrameRate(30),
                controller: _animationController,
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _showCustomCollections
                ? const CustomCollectionsGrid()
                : const CollectionGrid(),
          ),
        ],
      ),
    );
  }
}