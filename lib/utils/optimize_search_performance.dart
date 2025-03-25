import 'dart:async';
import '../models/tcg_card.dart';

/// Utility class to optimize search performance through various techniques
class SearchPerformanceOptimizer {
  // Debounce search inputs to reduce API calls
  static Timer? _debounceTimer;
  
  /// Debounce a search function to avoid rapid repeated calls
  static void debounceSearch(
    String query,
    Function(String) searchFunction, {
    Duration duration = const Duration(milliseconds: 500),
  }) {
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
    }
    
    _debounceTimer = Timer(duration, () {
      searchFunction(query);
    });
  }
  
  /// Pre-process search results to enhance performance
  static List<TcgCard> preprocessResults(
    List<TcgCard> results,
    {bool sortByRelevance = true, int? limit}
  ) {
    // Apply pre-processing steps
    var processedResults = List<TcgCard>.from(results);
    
    // Apply optional sorting by relevance
    if (sortByRelevance && processedResults.length > 1) {
      processedResults.sort((a, b) {
        // Put cards with images first
        final aHasImage = a.imageUrl != null && a.imageUrl!.isNotEmpty;
        final bHasImage = b.imageUrl != null && b.imageUrl!.isNotEmpty;
        
        if (aHasImage != bHasImage) {
          return aHasImage ? -1 : 1;
        }
        
        // Then sort by card number if available
        if (a.number != null && b.number != null) {
          try {
            final aNum = int.tryParse(a.number!) ?? 0;
            final bNum = int.tryParse(b.number!) ?? 0;
            if (aNum != 0 && bNum != 0) {
              return aNum.compareTo(bNum);
            }
          } catch (_) {
            // If parsing fails, fall back to string comparison
            return a.number!.compareTo(b.number!);
          }
        }
        
        // Default to alphabetical sorting
        return a.name.compareTo(b.name);
      });
    }
    
    // Apply optional limit
    if (limit != null && limit < processedResults.length) {
      processedResults = processedResults.sublist(0, limit);
    }
    
    return processedResults;
  }
  
  /// Perform image pre-fetching for search results to improve UX
  static Future<void> prefetchResultImages(
    List<TcgCard> results, 
    {int maxPrefetch = 20}
  ) async {
    // Implement image prefetching logic using ImagePrefetchService
    // This would be implemented in a real app
    return Future.value();
  }
}
