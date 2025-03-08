bool _isAddingCard = false;

@override
Widget build(BuildContext context) {
  // ...existing code...
  
  return WillPopScope(
    onWillPop: () async {
      if (_isAddingCard) {
        return false;
      }
      // ...existing will pop logic...
      return true;
    },
    child: Scaffold(
      // ...existing scaffold code...
    ),
  );
}

void _onNavigationItemTapped(int index) {
  if (_isAddingCard) {
    return;
  }
  // ...existing navigation code...
}
