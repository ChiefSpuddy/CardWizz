import 'package:flutter/material.dart';
import '../constants/sets.dart';

class SearchFilters extends StatelessWidget {
  final Function(String) onFilterSelected;
  final String? selectedFilter;

  const SearchFilters({
    super.key,
    required this.onFilterSelected,
    this.selectedFilter,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          ...PokemonSets.rarityFilters.map((filter) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter['name']!),
              selected: selectedFilter == filter['code'],
              onSelected: (_) => onFilterSelected(filter['code']!),
              avatar: Text(filter['icon']!),
            ),
          )),
        ],
      ),
    );
  }
}
