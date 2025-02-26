import 'package:flutter/material.dart';
import '../../services/search_history_service.dart';

class RecentSearches extends StatelessWidget {
  final SearchHistoryService? searchHistory;
  final Function(String) onSearchSelected;
  final Function() onClearHistory;
  final bool isLoading;

  const RecentSearches({
    Key? key,
    required this.searchHistory,
    required this.onSearchSelected,
    required this.onClearHistory,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading || searchHistory == null) {
      return const SizedBox.shrink();
    }

    final searches = searchHistory!.getRecentSearches();
    if (searches.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  Icons.history,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Recent Searches',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: onClearHistory,
                  child: Text(
                    'Clear',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.symmetric(
                horizontal: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.2),
                ),
              ),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: searches.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                indent: 56,
                color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.2),
              ),
              itemBuilder: (context, index) {
                final search = searches[index];
                return ListTile(
                  contentPadding: const EdgeInsets.fromLTRB(16, 4, 12, 4),
                  visualDensity: VisualDensity.compact,
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      width: 32,
                      height: 45,
                      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                      child: search['imageUrl'] != null
                          ? Image.network(
                              search['imageUrl']!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.search, size: 16),
                            )
                          : const Icon(Icons.search, size: 16),
                    ),
                  ),
                  title: Text(
                    search['query']!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  onTap: () => onSearchSelected(search['query']!),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
