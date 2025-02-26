import 'package:flutter/material.dart';

class SearchEmptyState extends StatelessWidget {
  final String message;
  final String? actionText;
  final VoidCallback? onAction;
  final String? imagePath;
  final IconData? icon;

  const SearchEmptyState({
    Key? key,
    required this.message,
    this.actionText,
    this.onAction,
    this.imagePath,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SliverToBoxAdapter(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (imagePath != null) ...[
                Image.asset(
                  imagePath!,
                  width: 120,
                  height: 120,
                ),
              ] else if (icon != null) ...[
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: isDark
                        ? colorScheme.primary.withOpacity(0.15)
                        : colorScheme.primaryContainer.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 40,
                    color: colorScheme.primary,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onBackground,
                ),
              ),
              const SizedBox(height: 16),
              if (actionText != null && onAction != null)
                ElevatedButton(
                  onPressed: onAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(fontWeight: FontWeight.w500),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(actionText!),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class NoResultsState extends StatelessWidget {
  final String query;
  final VoidCallback onClearSearch;

  const NoResultsState({
    Key? key,
    required this.query,
    required this.onClearSearch,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SearchEmptyState(
      message: 'No results found for "$query"',
      icon: Icons.search_off_rounded,
      actionText: 'Clear Search',
      onAction: onClearSearch,
    );
  }
}

class InitialSearchState extends StatelessWidget {
  const InitialSearchState({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SearchEmptyState(
      message: 'Enter a search term to find cards',
      icon: Icons.search,
    );
  }
}
