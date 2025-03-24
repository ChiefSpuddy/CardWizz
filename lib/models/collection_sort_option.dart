enum CollectionSortOption {
  nameAZ,       // Sort by name A-Z
  nameZA,       // Sort by name Z-A
  valueHighLow, // Sort by value high to low
  valueLowHigh, // Sort by value low to high
  newest,       // Sort by newest first
  oldest,       // Sort by oldest first
  countHighLow, // Sort by card count high to low
  countLowHigh, // Sort by card count low to high
}

extension CollectionSortOptionExtension on CollectionSortOption {
  String get label {
    switch (this) {
      case CollectionSortOption.nameAZ:
        return 'Name (A-Z)';
      case CollectionSortOption.nameZA:
        return 'Name (Z-A)';
      case CollectionSortOption.valueHighLow:
        return 'Value (High-Low)';
      case CollectionSortOption.valueLowHigh:
        return 'Value (Low-High)';
      case CollectionSortOption.newest:
        return 'Newest First';
      case CollectionSortOption.oldest:
        return 'Oldest First';
      case CollectionSortOption.countHighLow:
        return 'Card Count (High-Low)';
      case CollectionSortOption.countLowHigh:
        return 'Card Count (Low-High)';
    }
  }
}
