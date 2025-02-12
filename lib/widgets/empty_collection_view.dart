import 'package:flutter/material.dart';
import '../screens/home_screen.dart';

class EmptyCollectionView extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;
  final IconData icon;
  final VoidCallback? onActionPressed;

  const EmptyCollectionView({
    super.key,
    required this.title,
    required this.message,
    this.buttonText = 'Search Cards',
    this.icon = Icons.style_outlined,
    this.onActionPressed,
  });

  void _handleAction(BuildContext context) {
    if (onActionPressed != null) {
      onActionPressed!();
    } else {
      final homeState = context.findAncestorStateOfType<HomeScreenState>();
      if (homeState != null) {
        homeState.setSelectedIndex(2); // Navigate to search tab
      } else {
        Navigator.pushNamed(context, '/search');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: AppBar().preferredSize.height, // Add top padding equal to app bar height
        bottom: MediaQuery.of(context).size.height * 0.1, // Add some bottom padding
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => _handleAction(context),
                icon: const Icon(Icons.search),
                label: Text(buttonText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
