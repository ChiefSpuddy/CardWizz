import 'package:flutter/material.dart';

class SetSearchGrid extends StatelessWidget {
  final List<dynamic> sets;
  final Function(String) onSetSelected;
  final Function(String) onSetQuerySelected;

  const SetSearchGrid({
    Key? key,
    required this.sets,
    required this.onSetSelected,
    required this.onSetQuerySelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.5,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final dynamic item = sets[index];
            final Map<String, dynamic> set = Map<String, dynamic>.from(item as Map);
            return _buildSetGridItem(context, set);
          },
          childCount: sets.length,
        ),
      ),
    );
  }

  Widget _buildSetGridItem(BuildContext context, Map<String, dynamic> set) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          final setName = set['name']?.toString() ?? 'Unknown Set';
          final setId = set['id']?.toString() ?? '';
          
          onSetSelected(setName);
          onSetQuerySelected('set.id:$setId');
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (set['logo'] != null)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: Image.network(
                    set['logo'].toString(),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stack) {
                      return Icon(
                        Icons.auto_awesome,
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                        size: 32,
                      );
                    },
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.all(12),
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    set['name']?.toString() ?? 'Unknown Set',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${set['total']?.toString() ?? '?'} cards • ${set['releaseDate']?.toString() ?? 'Unknown Date'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
