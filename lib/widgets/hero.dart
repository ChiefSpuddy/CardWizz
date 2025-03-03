import 'package:flutter/material.dart';

/// A complete replacement for the Flutter Hero widget
/// This version simply renders the child without any animations
/// Place this file in your project and modify any imports to use this version
class Hero extends StatelessWidget {
  final Object tag;
  final Widget child;
  final CreateRectTween? createRectTween;
  final HeroFlightShuttleBuilder? flightShuttleBuilder;
  final HeroPlaceholderBuilder? placeholderBuilder;
  final bool transitionOnUserGestures;

  const Hero({
    Key? key,
    required this.tag,
    required this.child,
    this.createRectTween,
    this.flightShuttleBuilder,
    this.placeholderBuilder,
    this.transitionOnUserGestures = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Simply return the child without any hero behavior
    return child;
  }
}
