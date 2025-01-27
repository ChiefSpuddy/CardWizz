import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class EmptyCollectionView extends StatelessWidget {
  final String message;
  final VoidCallback onSearchPressed;

  const EmptyCollectionView({
    super.key,
    required this.message,
    required this.onSearchPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/animations/empty_box.json',
            width: 200,
            height: 200,
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ElevatedButton.icon(
            onPressed: onSearchPressed,
            icon: const Icon(Icons.search),
            label: const Text('Start Collecting'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
