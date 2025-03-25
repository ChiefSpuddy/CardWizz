import 'package:flutter/material.dart';

/// A widget that prevents rebuilding its child when parent rebuilds
/// Note: This is a custom widget, not Flutter's MemoryImage
class MemoryImage extends StatefulWidget {
  final Widget child;
  
  const MemoryImage({
    Key? key,
    required this.child,
  }) : super(key: key);
  
  @override
  State<MemoryImage> createState() => _MemoryImageState();
}

class _MemoryImageState extends State<MemoryImage> {
  late Widget _child;
  
  @override
  void initState() {
    super.initState();
    _child = widget.child;
  }
  
  @override
  Widget build(BuildContext context) {
    // Don't rebuild the child - use the cached version
    return _child;
  }
}
