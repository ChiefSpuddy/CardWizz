import 'package:flutter/material.dart';

/// A Hero widget that won't cause conflicts
class SafeHero extends StatelessWidget {
  final Object tag;
  final Widget child;

  const SafeHero({
    Key? key,
    required this.tag,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Simply return the child without animation for now
    return child;
  }
}
