import 'package:flutter/foundation.dart';
import '../models/collection_sort_option.dart';
import '../services/logging_service.dart';

class CollectionSortProvider extends ChangeNotifier {
  CollectionSortOption _sortOption = CollectionSortOption.newest;

  // Getter
  CollectionSortOption get sortOption => _sortOption;

  // Set sort option
  void setSort(CollectionSortOption option) {
    LoggingService.debug('CollectionSortProvider: Setting sort to ${option.name}');
    
    if (_sortOption != option) {
      _sortOption = option;
      notifyListeners();
    }
  }
  
  // Reset to default sorting
  void resetSort() {
    _sortOption = CollectionSortOption.newest;
    notifyListeners();
  }
}
