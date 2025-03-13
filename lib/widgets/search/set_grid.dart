import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/image_utils.dart';

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
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.5,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final set = sets[index];
            final String name = set['name'] ?? 'Unknown Set';
            final String code = set['id'] ?? '';
            final String logoUrl = set['images']?['symbol'] ?? '';
            
            return Card(
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: () {
                  onSetSelected(name);
                  onSetQuerySelected('set.id:$code');
                },
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (logoUrl.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Image.network(
                            logoUrl,
                            height: 40,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.image_not_supported,
                              size: 40,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (code.isNotEmpty)
                        Text(
                          code,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
          childCount: sets.length,
        ),
      ),
    );
  }
}
