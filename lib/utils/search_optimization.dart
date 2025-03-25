import '../models/tcg_card.dart';

/// Helper class to optimize search functionality
class SearchOptimization {
  /// Optimizes a list of search results by limiting the number of cards
  /// and prioritizing more relevant matches
  static List<TcgCard> optimizeSearchResults(
    List<TcgCard> results, 
    String searchTerm, 
    {int maxInitialResults = 100}
  ) {
    if (results.isEmpty || results.length <= maxInitialResults) {
      return results;
    }
    
    // Improved relevance scoring with weighted factors
    final searchTermTerms = searchTerm.toLowerCase().split(' ');
    final rankedResults = results.map((card) {
      // Start with base score
      double score = 0;
      final nameLower = card.name.toLowerCase();
      
      // Exact match is the highest priority
      if (nameLower == searchTerm.toLowerCase()) {
        score += 100;
      }
      
      // Cards with images get a boost
      if (card.imageUrl != null && card.imageUrl!.isNotEmpty) {
        score += 20;
      }
      
      // Name starts with search term
      if (nameLower.startsWith(searchTerm.toLowerCase())) {
        score += 50;
      }
      
      // Contains the full search term
      if (nameLower.contains(searchTerm.toLowerCase())) {
        score += 30;
      }
      
      // Contains all individual search terms
      bool containsAllTerms = true;
      for (final term in searchTermTerms) {
        if (term.length > 2 && !nameLower.contains(term)) {
          containsAllTerms = false;
          break;
        }
      }
      if (containsAllTerms && searchTermTerms.length > 1) {
        score += 25;
      }
      
      // Card rarity factor - higher rarity cards often more relevant
      if (card.rarity != null) {
        final rarityLower = card.rarity!.toLowerCase();
        if (rarityLower.contains('ultra rare') || rarityLower.contains('secret')) {
          score += 15;
        } else if (rarityLower.contains('rare')) {
          score += 10;
        } else if (rarityLower.contains('holo')) {
          score += 5;
        }
      }
      
      // If card has a price, it's likely more important
      if (card.price != null && card.price! > 0) {
        score += 5;
      }
      
      return (card, score);
    }).toList();
    
    // Sort by score in descending order
    rankedResults.sort((a, b) => b.$2.compareTo(a.$2));
    
    // Return the top results
    return rankedResults.take(maxInitialResults).map((tuple) => tuple.$1).toList();
  }
  
  /// Limit and optimize search results before display
  static List<TcgCard> preProcessSearchResults(List<TcgCard> cards, String searchTerm) {
    // Already optimized - return them
    if (cards.length <= 200) return cards;
    
    // For very large result sets, limit before optimization
    final limitedSet = cards.length > 500 ? cards.take(500).toList() : cards;
    
    // Now apply relevance optimization
    return optimizeSearchResults(limitedSet, searchTerm);
  }
}
