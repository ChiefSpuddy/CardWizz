import 'package:flutter/material.dart';

/// A wrapper for Hero widgets that ensures unique tags
class CardHeroWrapper extends StatelessWidget {
  final Widget child;
  final String? baseTag;
  final Object? object;
  
  // Generate a unique timestamp that will be different for each instance
  final String uniqueId = DateTime.now().microsecondsSinceEpoch.toString();

  CardHeroWrapper({
    Key? key,
    required this.child,
    this.baseTag, 
    this.object,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // Create a truly unique tag
    final heroTag = '${baseTag ?? 'hero'}_${uniqueId}_${object?.hashCode ?? ''}';
    
    // Use this unique tag for the Hero
    return Hero(
      tag: heroTag, 
      child: child,
    );
  }
}
