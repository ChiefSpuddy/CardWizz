import 'package:flutter/material.dart';

class SearchCategoriesHeader extends StatelessWidget {
  final bool showCategories;
  final VoidCallback onToggleCategories;

  const SearchCategoriesHeader({
    Key? key,
    required this.showCategories,
    required this.onToggleCategories,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggleCategories,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Row(
          children: [
            Text(
              'Quick Searches',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
            const Spacer(),
            Icon(
              showCategories ? Icons.expand_less : Icons.expand_more,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
