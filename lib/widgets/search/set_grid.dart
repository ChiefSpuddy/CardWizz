import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/currency_provider.dart';

class SetSearchGrid extends StatelessWidget {
  final List<dynamic> sets;
  final void Function(String) onSetSelected;
  final void Function(String) onSetQuerySelected;

  const SetSearchGrid({
    Key? key,
    required this.sets,
    required this.onSetSelected,
    required this.onSetQuerySelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10.0,
        crossAxisSpacing: 10.0,
        childAspectRatio: 1.0,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final set = sets[index];
          final name = set['name'];
          final logo = set['logo'];
          final symbol = set['symbol'];
          final query = set['query'] ?? 'set.id:${set['id']}';

          return InkWell(
            onTap: () {
              onSetSelected(name);
              onSetQuerySelected(query);
            },
            child: Card(
              clipBehavior: Clip.antiAlias,
              elevation: 2.0,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (logo != null)
                      Expanded(
                        child: Image.network(
                          logo,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return symbol != null
                                ? Image.network(
                                    symbol,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.image_not_supported, size: 40),
                                  )
                                : const Icon(Icons.image_not_supported, size: 40);
                          },
                        ),
                      )
                    else if (symbol != null)
                      Expanded(
                        child: Image.network(
                          symbol,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.image_not_supported, size: 40),
                        ),
                      )
                    else
                      const Expanded(
                        child: Icon(Icons.style, size: 40),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        childCount: sets.length,
      ),
    );
  }
}
