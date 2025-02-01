import 'dart:ui';  // Add this at the top with other imports
import 'package:flutter/material.dart';

// ...existing code...

Widget _buildPortfolioValue(BuildContext context) {
  return AnimatedContainer(
    duration: const Duration(milliseconds: 300),
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Theme.of(context).colorScheme.primary,
          Theme.of(context).colorScheme.secondary,
        ],
      ),
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Portfolio Value',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(width: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.trending_up,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                const SizedBox(width: 4),
                Text(
                  _totalValue,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildMetricItem(
              icon: Icons.arrow_upward,
              color: Colors.green,
              label: 'Gainers',
              value: '23',
            ),
            _buildMetricItem(
              icon: Icons.arrow_downward,
              color: Colors.red,
              label: 'Losers',
              value: '12',
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _buildStatItem(String label, String value, Color color, IconData icon) {
  return Row(
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

// ...existing code...

body: AnimatedBackground(
  child: !isSignedIn
      ? const SignInView()  // Replace SignInButton with SignInView
      : StreamBuilder<List<TcgCard>>(
// ...existing code...

