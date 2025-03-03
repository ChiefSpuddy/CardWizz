// Add these debug button methods to your collection screen

Widget _buildDebugButton() {
  return Positioned(
    bottom: 16,
    right: 16,
    child: FloatingActionButton(
      heroTag: 'debug_fab',
      backgroundColor: Colors.purple,
      onPressed: () {
        _showDebugInfo();
      },
      child: const Icon(Icons.bug_report),
    ),
  );
}

void _showDebugInfo() {
  showDebugOverlay(context);
}

// Add this to your build method
@override
Widget build(BuildContext context) {
  // ... your existing build code ...

  return Scaffold(
    // ... existing scaffold properties ...
    body: Stack(
      children: [
        // Your existing body content
        // ...
        
        // Add the debug button if in debug mode
        if (kDebugMode) _buildDebugButton(),
      ],
    ),
    appBar: AppBar(
      title: Text('Collection Screen'),
      actions: [
        IconButton(
          icon: const Icon(Icons.bug_report),
          onPressed: () {
            final storage = Provider.of<StorageService>(context, listen: false);
            storage.debugAndFixCards();
            
            // Show the card viewer after debugging
            showCardStreamViewer(context);
          },
        ),
      ],
    ),
  );
}
