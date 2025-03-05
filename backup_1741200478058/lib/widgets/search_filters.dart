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
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('All Sets'),
              selected: selectedFilter == null,
              onSelected: (_) => onFilterSelected(''),
              avatar: const Text('🔍'),
            ),
          ),
          ...PokemonSets.setQueries.entries.map((entry) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(entry.key),
              selected: selectedFilter == entry.value['query'],
              onSelected: (_) => onFilterSelected(entry.value['query']!),
              avatar: Text(entry.value['icon']!),
            ),
          )),
        ],
      ),
    );
  }
}
