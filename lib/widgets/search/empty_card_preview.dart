import 'package:flutter/material.dart' hide Hero;
import 'package:uuid/uuid.dart';
import '../no_hero.dart'; // Use no_hero.dart instead of quick_fix.dart

/// A widget to display when a card image is not yet loaded
class EmptyCardPreview extends StatelessWidget {
  final int index;
  final double? width;
  final double? height;
  final bool useHero;
  final Color? backgroundColor;
  final String context; // Add a context parameter to make tags unique

  // Create a UUID instance for generating unique IDs
  static final _uuid = Uuid();
  
  // Store a unique ID for this instance
  final String _uniqueId = _uuid.v4();

  // Update constructor to include context
  const EmptyCardPreview({
    Key? key, 
    required this.index,
    this.width,
    this.height,
    this.useHero = true,
    this.backgroundColor,
    this.context = 'default', // Default context value
  }) : super(key: key);
  
  // Factory to create with timestamp-based unique tag
  factory EmptyCardPreview.unique({
    double? width,
    double? height,
    bool useHero = true,
    Color? backgroundColor,
  }) {
    final uniqueTag = 'empty_preview_${DateTime.now().microsecondsSinceEpoch}';
    return EmptyCardPreview(
      index: 0,
      width: width,
      height: height,
      useHero: useHero,
      backgroundColor: backgroundColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = Container(
      width: width,
      height: height,
      color: backgroundColor ?? Theme.of(context).colorScheme.surfaceVariant,
      child: const Center(
        child: Icon(
          Icons.search,
          size: 30,
          color: Colors.grey,
        ),
      ),
    );
    
    // Just return the content directly without any Hero animations
    return content;
  }
}
