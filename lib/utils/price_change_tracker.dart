import 'dart:math';
import '../models/tcg_card.dart';
import '../services/logging_service.dart';

/// Utility class to track and calculate price changes for cards
class PriceChangeTracker {
  /// Get recent price changes in the collection
  /// 
  /// [cards] - List of cards to analyze
  /// [minChangePercentage] - Minimum percentage change to include (default: 2.0%)
  /// [maxResults] - Maximum number of results to return (default: 10)
  /// [preferEbayPrices] - Whether to prioritize eBay prices over API prices
  static Future<List<Map<String, dynamic>>> getRecentPriceChanges(
    List<TcgCard> cards, {
    double minChangePercentage = 2.0,
    int maxResults = 10,
    bool preferEbayPrices = true,
  }) async {
    final results = <Map<String, dynamic>>[];
    
    // Check each card for price changes
    for (final card in cards) {
      // Skip cards without price info
      if (card.price == null || card.price! <= 0) continue;

      // Get current price (API price)
      final currentPrice = card.price!;

      // Calculate changes from different sources
      Map<String, dynamic>? bestChange;
      
      // 1. Check eBay price change if available
      if (card.ebayPrice != null && card.ebayPrice! > 0) {
        final ebayChange = _calculateChange(
          card,
          card.ebayPrice!,
          currentPrice,
          'eBay',
        );
        
        // If significant change and we prefer eBay, or no best change yet
        if (ebayChange != null && 
            (bestChange == null || preferEbayPrices)) {
          bestChange = ebayChange;
        }
      }
      
      // 2. Check price history if available
      if (card.priceHistory.length > 1) {
        final historyChange = _calculateHistoryChange(card);
        
        // If history change is more significant or we don't have a change yet
        if (historyChange != null && 
            (bestChange == null || 
             (historyChange['change'].abs() > (bestChange['change'] as double).abs()))) {
          bestChange = historyChange;
        }
      }
      
      // Add the best change if it meets minimum threshold
      if (bestChange != null && 
          bestChange['change'].abs() >= minChangePercentage) {
        results.add(bestChange);
      }
    }
    
    // Sort by absolute percentage change (highest first)
    results.sort((a, b) => 
      (b['change'] as double).abs().compareTo((a['change'] as double).abs())
    );
    
    // Limit results if needed
    if (results.length > maxResults) {
      return results.sublist(0, maxResults);
    }
    
    return results;
  }
  
  /// Calculate change between eBay and API prices
  static Map<String, dynamic>? _calculateChange(
    TcgCard card,
    double newPrice,
    double oldPrice,
    String period,
  ) {
    // Avoid division by zero
    if (oldPrice <= 0) return null;
    
    // Calculate percentage change
    final change = ((newPrice - oldPrice) / oldPrice) * 100.0;
    
    // Only track significant changes to avoid noise
    if (change.abs() < 2.0) return null;
    
    return {
      'card': card,
      'change': change,
      'oldPrice': oldPrice,
      'newPrice': newPrice,
      'period': period,
    };
  }
  
  /// Calculate change from price history
  static Map<String, dynamic>? _calculateHistoryChange(TcgCard card) {
    if (card.priceHistory.length < 2) return null;
    
    // Sort history by timestamp (oldest first)
    final history = List.of(card.priceHistory)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    // Get oldest and newest prices
    final oldestEntry = history.first;
    final newestEntry = history.last;
    
    // Calculate days between entries
    final daysDiff = newestEntry.timestamp.difference(oldestEntry.timestamp).inDays;
    
    // Skip if less than 1 day or more than 30 days (for reliability)
    if (daysDiff < 1 || daysDiff > 30) return null;
    
    // Skip if prices are the same or too close
    if ((newestEntry.price - oldestEntry.price).abs() < 0.01) return null;
    
    // Calculate percentage change
    final change = ((newestEntry.price - oldestEntry.price) / oldestEntry.price) * 100.0;
    
    // Only track significant changes
    if (change.abs() < 2.0) return null;
    
    // Convert days to a readable period
    String period = '${daysDiff}d';
    if (daysDiff == 1) {
      period = '24h';
    } else if (daysDiff <= 7) {
      period = '${daysDiff}d';
    } else if (daysDiff <= 30) {
      period = '${(daysDiff / 7).ceil()}w';
    }
    
    return {
      'card': card,
      'change': change,
      'oldPrice': oldestEntry.price,
      'newPrice': newestEntry.price,
      'period': period,
    };
  }
}