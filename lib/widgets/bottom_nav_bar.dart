// ...existing code...

  void _onItemTapped(BuildContext context, int index) {
    if (index == 1) { // Search tab
      // Always create a new instance of search screen
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/search',
        (route) => false, // Clear the stack
      );
    } else {
      // ...existing navigation logic...
    }
  }

// ...existing code...
