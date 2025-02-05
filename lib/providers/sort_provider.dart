import 'package:flutter/material.dart';

enum CollectionSortOption {
  nameAZ,
  nameZA,
  valueHighLow,
  valueLowHigh,
  newest,
  oldest,
  countHighLow,
  countLowHigh,
}

class SortProvider with ChangeNotifier {
  CollectionSortOption _currentSort = CollectionSortOption.valueHighLow;  // Changed from newest

  CollectionSortOption get currentSort => _currentSort;

  void setSort(CollectionSortOption option) {
    _currentSort = option;
    notifyListeners();
  }
}
