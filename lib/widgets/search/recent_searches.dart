import 'package:flutter/material.dart';
import '../../services/search_history_service.dart';

class RecentSearches extends StatefulWidget {
  final SearchHistoryService? searchHistory;
  final Function(String, Map<String, String>) onSearchSelected;
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
  State<RecentSearches> createState() => _RecentSearchesState();
}

class _RecentSearchesState extends State<RecentSearches> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading || widget.searchHistory == null) {
      return const SizedBox.shrink();
    }

    final searches = widget.searchHistory!.getRecentSearches();
    if (searches.isEmpty) return const SizedBox.shrink();
    
    final itemCount = searches.length > 5 ? 5 : searches.length;

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.1),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      )),
      child: FadeTransition(
        opacity: CurvedAnimation(
          parent: _animationController,
          curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
        ),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 24, 16, 32),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              )
            ],
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
                      ),
                      child: Icon(
                        Icons.history,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Recent Searches',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: widget.onClearHistory,
                      icon: Icon(
                        Icons.delete_outline,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      label: Text(
                        'Clear All',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: itemCount,
                separatorBuilder: (context, index) => const Divider(height: 1, indent: 56),
                itemBuilder: (context, index) {
                  final search = searches[index];
                  
                  return ListTileTheme(
                    dense: true,
                    child: ListTile(
                      contentPadding: const EdgeInsets.fromLTRB(16, 4, 12, 4),
                      visualDensity: VisualDensity.compact,
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: SizedBox(
                          width: 32,
                          height: 45,
                          child: search['imageUrl'] != null
                              ? DecoratedBox(
                                  decoration: BoxDecoration(
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Image.network(
                                    search['imageUrl']!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                                      child: const Icon(Icons.image_not_supported, size: 16),
                                    ),
                                  ),
                                )
                              : Container(
                                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                                  child: const Icon(Icons.search, size: 16),
                                ),
                        ),
                      ),
                      title: Text(
                        search['query']!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              size: 16,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            onPressed: () {
                              // Fix: use clearSearch for a specific item
                              final query = search['query']!;
                              widget.searchHistory!.clearSearch(query);
                              setState(() {});
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 24,
                              minHeight: 24,
                            ),
                            splashRadius: 16,
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                      onTap: () => widget.onSearchSelected(
                        search['query']!,
                        search,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
