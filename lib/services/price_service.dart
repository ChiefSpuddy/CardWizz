import 'dart:async';
import '../services/ebay_api_service.dart';
import '../services/ebay_search_service.dart';
import '../services/logging_service.dart';
import '../models/tcg_card.dart';  // Add this import for TcgCard

class PriceService {
  final EbayApiService _ebayApi = EbayApiService();
  final EbaySearchService _ebaySearchService = EbaySearchService();
  
  // Cache to prevent redundant API calls
  final Map<String, _PriceData> _priceCache = {};
  
  // Price expiration - refresh after 12 hours
  static const Duration _priceCacheDuration = Duration(hours: 12);

  // Add a property to cache the most recent price changes
  List<Map<String, dynamic>>? _lastRecentPriceChanges;

  // Add this property to fix missing listings error
  List<Map<String, dynamic>> listings = [];
  
  /// Get the most accurate price for a card with the following priority:
  /// 1. eBay sold listings (median price)
  /// 2. TCG API price data
  /// 3. Original card price if available
  Future<double?> getAccuratePrice(TcgCard card, {bool includeGraded = false}) async {
    // Build cache key from card details
    final cacheKey = _buildCacheKey(card, includeGraded);
    
    // Check cache first
    if (_priceCache.containsKey(cacheKey)) {
      final cachedData = _priceCache[cacheKey]!;
      
      // Return cached data if it's still valid
      if (DateTime.now().difference(cachedData.timestamp) < _priceCacheDuration) {
        return cachedData.price;
      }
    }
    
    try {
      // First priority: Try to get eBay sold listings
      final isMtg = _isMtgCard(card);
      
      double? ebayPrice;
      if (includeGraded) {
        // Include graded cards in the price calculation
        ebayPrice = await _ebayApi.getAveragePrice(
          card.name,
          setName: card.setName,
          number: card.number,
          isMtg: isMtg,
        );
      } else {
        // Calculate price excluding graded cards
        ebayPrice = await _calculateRawCardPrice(card);
      }
      
      // If we have valid eBay data, use it and cache it
      if (ebayPrice != null && ebayPrice > 0) {
        _logPriceInfo('Using eBay sold price for ${card.name}: \$${ebayPrice.toStringAsFixed(2)}' +
              (includeGraded ? ' (including graded cards)' : ' (raw cards only)'));
        _priceCache[cacheKey] = _PriceData(
          price: ebayPrice,
          source: PriceSource.ebay,
          timestamp: DateTime.now(),
        );
        return ebayPrice;
      }
      
      // Second priority: Use the TCG API price if available
      if (card.price != null && card.price! > 0) {
        _logPriceInfo('Using TCG API price for ${card.name}: \$${card.price!.toStringAsFixed(2)}');
        _priceCache[cacheKey] = _PriceData(
          price: card.price!,
          source: PriceSource.tcgApi,
          timestamp: DateTime.now(),
        );
        return card.price;
      }
      
      // No valid price found
      _logPriceInfo('No valid price found for ${card.name}');
      return null;
      
    } catch (e) {
      _logPriceInfo('Error getting accurate price: $e');
      // Fallback to existing price in case of error
      return card.price;
    }
  }
  
  /// Get price data for raw (ungraded) cards only
  Future<double?> getRawCardPrice(TcgCard card) async {
    return await getAccuratePrice(card, includeGraded: false);
  }

  /// Get price data for all cards including graded
  Future<double?> getAllCardPrice(TcgCard card) async {
    return await getAccuratePrice(card, includeGraded: true);
  }
  
  /// Get comprehensive price data for a card including graded and raw options
  Future<ComprehensivePriceData> getComprehensivePriceData(TcgCard card) async {
    // Get raw price data
    final rawResult = await getPriceData(card, includeGraded: false);
    
    // Get graded price data separately if the card has significant value
    double? gradedPrice;
    double gradedToRawRatio = 1.0;
    bool hasGradedSales = false;
    
    // Get the all-inclusive price data (includes graded)
    final allInclusiveResult = await getPriceData(card, includeGraded: true);
    
    _logPriceInfo('Price analysis for ${card.name}:');
    _logPriceInfo('  - Raw price: ${rawResult.price != null ? "\$${rawResult.price!.toStringAsFixed(2)}" : "N/A"}');
    _logPriceInfo('  - All-inclusive price: ${allInclusiveResult.price != null ? "\$${allInclusiveResult.price!.toStringAsFixed(2)}" : "N/A"}');
    
    // Check if we have meaningful difference between raw and all-inclusive prices
    if (rawResult.price != null && allInclusiveResult.price != null) {
      final difference = allInclusiveResult.price! - rawResult.price!;
      final percentDifference = (difference / rawResult.price!) * 100;
      
      _logPriceInfo('  - Price difference: ${difference.toStringAsFixed(2)} (${percentDifference.toStringAsFixed(1)}%)');
      
      // If all-inclusive price is significantly higher (>10%), we likely have graded sales
      if (percentDifference > 10.0) {
        _logPriceInfo('  - Detected significant price difference, assuming graded sales exist');
        gradedPrice = allInclusiveResult.price;
        gradedToRawRatio = allInclusiveResult.price! / rawResult.price!;
        hasGradedSales = true;
      } else {
        // Explicitly fetch graded-only prices as a fallback
        try {
          final ebayApi = EbayApiService();
          final sales = await ebayApi.getRecentSalesWithGraded(card.name, setName: card.setName, number: card.number);
          
          // Count graded sales
          int gradedCount = 0;
          List<double> gradedPrices = [];
          
          for (final key in sales.keys) {
            if (key != 'ungraded' && sales[key] != null) {
              gradedCount += sales[key]!.length;
              gradedPrices.addAll(sales[key]!.map((s) => (s['price'] as num).toDouble()));
            }
          }
          
          _logPriceInfo('  - Found $gradedCount graded sales');
          
          if (gradedCount >= 3 && gradedPrices.isNotEmpty) {
            // Calculate average graded price
            final avgGradedPrice = gradedPrices.reduce((a, b) => a + b) / gradedPrices.length;
            gradedPrice = avgGradedPrice;
            gradedToRawRatio = avgGradedPrice / rawResult.price!;
            hasGradedSales = true;
            
            _logPriceInfo('  - Calculated graded price: \$${avgGradedPrice.toStringAsFixed(2)}');
            _logPriceInfo('  - Grading premium: ${((gradedToRawRatio - 1) * 100).toStringAsFixed(1)}%');
          }
        } catch (e) {
          _logPriceInfo('  - Error determining graded prices: $e');
        }
      }
    }
    
    return ComprehensivePriceData(
      rawPrice: rawResult.price,
      primarySource: rawResult.source,
      confidence: rawResult.confidence,
      gradedPrice: gradedPrice,
      gradedToRawRatio: gradedToRawRatio,
      hasGradedSales: hasGradedSales,
    );
  }
  
  /// Get price data including source and confidence level
  Future<PriceResult> getPriceData(TcgCard card, {bool includeGraded = false}) async {
    final price = await getAccuratePrice(card, includeGraded: includeGraded);
    
    // Build cache key from card details
    final cacheKey = _buildCacheKey(card, includeGraded);
    
    // Determine source and confidence
    PriceSource source = PriceSource.unknown;
    double confidence = 0.0;
    
    if (_priceCache.containsKey(cacheKey)) {
      source = _priceCache[cacheKey]!.source;
      
      // Set confidence level based on source
      switch (source) {
        case PriceSource.ebay:
          confidence = 0.9; // 90% confidence for eBay sold data
          break;
        case PriceSource.tcgApi:
          confidence = 0.7; // 70% confidence for TCG API data
          break;
        case PriceSource.original:
          confidence = 0.5; // 50% confidence for original data
          break;
        case PriceSource.unknown:
          confidence = 0.3; // 30% confidence for unknown source
          break;
      }
    } else if (price != null) {
      // If we have a price but no cached data, it's likely the original price
      source = PriceSource.original;
      confidence = 0.5;
    }
    
    return PriceResult(
      price: price,
      source: source,
      confidence: confidence,
    );
  }
  
  /// Build cache key based on card details and includes/excludes graded flag
  String _buildCacheKey(TcgCard card, bool includeGraded) {
    return '${card.id}_${card.name}_${card.setName ?? ""}_${card.number ?? ""}_${includeGraded ? "graded" : "raw"}';
  }
  
  /// Calculate price specifically for raw (ungraded) cards
  Future<double?> _calculateRawCardPrice(TcgCard card) async {
    try {
      final isMtg = _isMtgCard(card);
      
      // Get all sales data
      final allSales = await _ebayApi.getRecentSales(
        card.name,
        setName: card.setName,
        number: card.number,
        isMtg: isMtg,
      );
      
      _logPriceInfo('Total eBay sales found for ${card.name}: ${allSales.length}');
      
      // Filter out graded cards
      final rawSales = allSales.where((sale) {
        final title = (sale['title'] as String).toLowerCase();
        
        // Extended graded detection logic
        if (title.contains('psa') || 
            title.contains('bgs') || 
            title.contains('cgc') || 
            title.contains('sgc') || 
            title.contains('ace') ||
            title.contains('beckett') ||
            title.contains('grade') ||
            title.contains('graded') ||
            title.contains(' gem ') ||
            title.contains(' mint ') ||
            title.contains(' slab') ||
            title.contains(' pop ') ||
            RegExp(r'(^|\s)(10|9\.5|9)($|\s)').hasMatch(title)) {
          return false;
        }
        return true;
      }).toList();
      
      _logPriceInfo('Filtered to ${rawSales.length} raw card sales (excluded ${allSales.length - rawSales.length} graded sales)');
      
      // If we have at least 3 raw sales, calculate the price
      if (rawSales.length >= 3) {
        // Extract prices
        final prices = rawSales
            .map((s) => (s['price'] as num).toDouble())
            .where((p) => p > 0)
            .toList();
        
        // Sort prices to calculate median
        prices.sort();
        
        // Calculate median
        final median = prices[prices.length ~/ 2];
        
        // Calculate mean for comparison
        final mean = prices.reduce((a, b) => a + b) / prices.length;
        
        // Calculate trimmed mean (excluding top and bottom 15%)
        final trimCount = (prices.length * 0.15).round();
        List<double> trimmedPrices;
        if (trimCount > 0 && prices.length > (trimCount * 2)) {
          trimmedPrices = prices.sublist(trimCount, prices.length - trimCount);
        } else {
          trimmedPrices = prices;
        }
        final trimmedMean = trimmedPrices.reduce((a, b) => a + b) / trimmedPrices.length;
        
        _logPriceInfo('Raw card price analysis for ${card.name} (${rawSales.length} raw sales):');
        _logPriceInfo('  - Range: \$${prices.first.toStringAsFixed(2)} to \$${prices.last.toStringAsFixed(2)}');
        _logPriceInfo('  - Median: \$${median.toStringAsFixed(2)}');
        _logPriceInfo('  - Mean: \$${mean.toStringAsFixed(2)}');
        _logPriceInfo('  - Trimmed Mean (15%): \$${trimmedMean.toStringAsFixed(2)}');
        
        // For regular cards, we prefer trimmed mean
        return trimmedMean;
      }
      
      _logPriceInfo('Not enough raw sales found for ${card.name} (only ${rawSales.length})');
      
      // If not enough raw sales, fall back to the TCG price if available
      if (card.price != null && card.price! > 0) {
        return card.price;
      }
      
      return null;
      
    } catch (e) {
      _logPriceInfo('Error calculating raw card price: $e');
      return null;
    }
  }
  
  /// Check if a card is an MTG card
  bool _isMtgCard(TcgCard card) {
    if (card.isMtg != null) {
      return card.isMtg!;
    }
    
    // Check ID pattern
    if (card.id.startsWith('mtg_')) {
      return true;
    }
    
    // Check for Pokemon set IDs
    const pokemonSetPrefixes = ['sv', 'swsh', 'sm', 'xy', 'bw', 'dp', 'cel'];
    for (final prefix in pokemonSetPrefixes) {
      if (card.set.id.toLowerCase().startsWith(prefix)) {
        return false; // Definitely Pokemon
      }
    }
    
    // Default to non-MTG
    return false;
  }
  
  /// Clear the price cache
  void clearCache() {
    _priceCache.clear();
  }
  
  // Replace print statements with logging service calls
  void _logPriceInfo(String message) {
    LoggingService.debug(message, tag: 'Price');
  }

  // Modify method to cache results - Fixed the missing result variable
  Future<List<Map<String, dynamic>>> getRecentPriceChanges(List<TcgCard> cards) async {
    try {
      // Declare the result variable here
      final List<Map<String, dynamic>> result = [];
      
      // Find cards with direct price changes from the latest update
      for (final card in cards) {
        if (card.lastPriceChange != null && card.previousPrice != null && card.price != null) {
          final change = ((card.price! - card.previousPrice!) / card.previousPrice!) * 100;
          if (change.abs() > 0.01) {
            result.add({
              'card': card,
              'change': change,
              'period': 'Last update',
            });
          }
        }
      }
      
      // Also check price history for changes
      for (final card in cards) {
        if (card.price != null && card.priceHistory.length >= 2) {
          final change = card.getPriceChange(const Duration(days: 1)) ??
                        card.getPriceChange(const Duration(days: 7)) ??
                        card.getPriceChange(const Duration(days: 30));
          
          if (change != null && change.abs() > 0.01) {
            // Check if we already have this card from direct changes
            if (!result.any((item) => (item['card'] as TcgCard).id == card.id)) {
              result.add({
                'card': card,
                'change': change,
                'period': '${card.getPriceChangePeriod() ?? 'Recent'}',
              });
            }
          }
        }
      }
      
      // Sort by absolute change percentage (largest changes first)
      result.sort((a, b) => (b['change'] as double).abs().compareTo((a['change'] as double).abs()));
      
      // Store the result in cache before returning
      _lastRecentPriceChanges = result;
      return result;
    } catch (e) {
      print('Error getting recent price changes: $e');
      // If we have cached results, return them on error
      if (_lastRecentPriceChanges != null) {
        return _lastRecentPriceChanges!;
      }
      return [];
    }
  }

  // Add a method to get cached changes
  List<Map<String, dynamic>>? getCachedPriceChanges() {
    return _lastRecentPriceChanges;
  }
  
  // Ensure market scanner doesn't reset the recent price changes - Fixed missing result variable
  Future<List<Map<String, dynamic>>> scanMarket() async {
    // Preserve the recent price changes cache
    final cachedChanges = _lastRecentPriceChanges;
    
    // Declare the result variable
    final List<Map<String, dynamic>> result = [];
    
    try {
      // Implementation for market scanning
      // This is a simplified placeholder - you would add your actual market scanning logic here
      
      // For example:
      // final marketData = await _fetchMarketData();
      // result.addAll(marketData);
      
    } catch (e) {
      print('Error scanning market: $e');
    } finally {
      // Restore the cache if it was cleared during the process
      if (cachedChanges != null) {
        _lastRecentPriceChanges = cachedChanges;
      }
    }
    
    return result;
  }

  Future<double?> _getEbayPrice(TcgCard card) async {
    try {
      // ... existing code ...
      
      if (listings.isEmpty) {
        // Replace print with LoggingService
        LoggingService.debug('No eBay listings found for ${card.name}', tag: 'Price');
        return null;
      }
      
      // ... existing code ...
    } catch (e) {
      // Replace print with LoggingService
      LoggingService.error('Error fetching eBay price: $e', tag: 'Price');
      return null;
    }
  }
}

/// Price data for caching
class _PriceData {
  final double price;
  final PriceSource source;
  final DateTime timestamp;
  
  _PriceData({
    required this.price,
    required this.source,
    required this.timestamp,
  });
}

/// Source of the price data
enum PriceSource {
  ebay,     // From eBay sold listings (most accurate)
  tcgApi,   // From TCG API (moderately accurate)
  original, // Original price from card model (least accurate)
  unknown,  // Source unknown
}

/// Result of a price query
class PriceResult {
  final double? price;
  final PriceSource source;
  final double confidence; // 0.0-1.0 representing confidence level
  
  PriceResult({
    this.price,
    this.source = PriceSource.unknown,
    this.confidence = 0.0,
  });
  
  /// Returns a human-readable description of the price source
  String get sourceDescription {
    switch (source) {
      case PriceSource.ebay:
        return 'Based on recent eBay sales';
      case PriceSource.tcgApi:
        return 'Based on TCG market data';
      case PriceSource.original:
        return 'Based on original listing';
      case PriceSource.unknown:
        return 'Price source unknown';
    }
  }
}

/// Comprehensive price data including graded and raw price information
class ComprehensivePriceData {
  final double? rawPrice;
  final double? gradedPrice;
  final PriceSource primarySource;
  final double confidence;
  final double gradedToRawRatio;
  final bool hasGradedSales;
  
  ComprehensivePriceData({
    this.rawPrice,
    this.gradedPrice,
    this.primarySource = PriceSource.unknown,
    this.confidence = 0.0,
    this.gradedToRawRatio = 1.0,
    this.hasGradedSales = false,
  });
  
  /// Returns the best price to display as default
  double? get bestPrice => rawPrice;
  
  /// Returns a potential value estimate if graded based on raw price
  double? get potentialGradedValue {
    if (rawPrice == null) return null;
    return rawPrice! * gradedToRawRatio;
  }
}
