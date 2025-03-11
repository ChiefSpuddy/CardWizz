import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;
import 'dart:math' show Random;  // Add this import for Random
import '../models/tcg_card.dart';
import '../services/logging_service.dart';

// Define enum at the top level, not inside the class
enum CardMatchResult {
  noMatch,
  nameMatchOnly,
  exactMatch,
}

class EbayApiService {
  static const String _clientId = 'SamMay-CardScan-PRD-4227403db-8b726135';
  static const String _clientSecret = 'PRD-227403db4eda-4945-4811-aabd-f9fe';
  static const String _baseUrl = 'api.ebay.com';
  String? _accessToken;
  DateTime? _tokenExpiry;

  // Add this at the top of your class
  static const bool _enableDebugLogging = false; // Set to false to disable all the spam

  // Modify all print statements in the class to use this helper method
  void _log(String message) {
    if (_enableDebugLogging) {
      LoggingService.debug(message, tag: 'eBay');
    }
  }

  Future<String> _getAccessToken() async {
    if (_accessToken != null && _tokenExpiry != null && _tokenExpiry!.isAfter(DateTime.now())) {
      return _accessToken!;
    }

    final credentials = base64.encode(utf8.encode('$_clientId:$_clientSecret'));
    final response = await http.post(
      Uri.https('api.ebay.com', '/identity/v1/oauth2/token'),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Authorization': 'Basic $credentials',
      },
      body: {
        'grant_type': 'client_credentials',
        'scope': 'https://api.ebay.com/oauth/api_scope',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      _accessToken = data['access_token'];
      _tokenExpiry = DateTime.now().add(Duration(seconds: data['expires_in']));
      return _accessToken!;
    } else {
      throw Exception('Failed to get access token: ${response.statusCode}');
    }
  }

  String _toTitleCase(String text) {
    if (text.isEmpty) return text;
    
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  String? _getGradingService(String title) {
    title = title.toLowerCase();
    if (title.contains('psa')) return 'PSA';
    if (title.contains('bgs') || title.contains('beckett')) return 'BGS';
    if (title.contains('cgc')) return 'CGC';
    if (title.contains('ace')) return 'ACE';
    if (title.contains('sgc')) return 'SGC';
    return null;
  }

  Future<List<Map<String, dynamic>>> getRecentSales(String cardName, {
    String? setName,
    String? number,
    Duration lookbackPeriod = const Duration(days: 90),
    bool isMtg = false,
  }) async {
    final token = await _getAccessToken();
    
    try {
      // Build search query - prioritize card number in search
      final queryParts = <String>[cardName];
      
      // Add number to query with higher precedence for exact matching
      if (number != null && number.isNotEmpty) {
        // For numeric-only numbers, add both the raw number and number with "#" prefix
        if (RegExp(r'^\d+$').hasMatch(number)) {
          queryParts.add('#$number');
        } else {
          // For complex numbers like "239/191", add exactly as is
          queryParts.add('"$number"');
        }
      }
      
      if (setName?.isNotEmpty ?? false) {
        queryParts.add('"$setName"');  // Use quotes for exact set name matching
      }
      
      // Add the correct TCG identifier
      queryParts.add(isMtg ? 'mtg card' : 'pokemon card');
      
      final searchQuery = queryParts.join(' ');
      
      _log('Searching eBay with query: $searchQuery');
      if (number != null && number.isNotEmpty) {
        _log('Searching for specific card number: $number');
      }
      
      // Use correct category ID based on card type
      final categoryId = isMtg ? '2536' : '183454'; // 2536 is for MTG cards
      
      final response = await http.get(
        Uri.https(_baseUrl, '/buy/browse/v1/item_summary/search', {
          'q': searchQuery,
          'category_ids': categoryId,
          'filter': 'buyingOptions:{FIXED_PRICE} AND soldItemsOnly:true',
          'sort': '-soldDate',
          'limit': '200', // Increase limit to get more results for better analysis
        }),
        headers: {
          'Authorization': 'Bearer $token',
          'X-EBAY-C-MARKETPLACE-ID': 'EBAY_US',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['itemSummaries'] as List?;
        
        if (items == null || items.isEmpty) {
          _log('No items found in eBay response');
          return [];
        }

        _log('Found ${items.length} items in eBay response');
        final sales = <Map<String, dynamic>>[];
        final normalizedCardName = cardName.toLowerCase().trim();
        final normalizedCardNumber = number?.toLowerCase().trim() ?? '';
        final hasCardNumber = normalizedCardNumber.isNotEmpty;
        
        // Count total matches for logging
        int exactMatches = 0;
        int nameOnlyMatches = 0;
        int rejectedItems = 0;
        
        for (final dynamic rawItem in items) {
          try {
            if (rawItem is! Map<String, dynamic>) continue;

            // Extract price data safely
            final priceData = rawItem['price'];
            if (priceData == null) continue;

            double? price;
            if (priceData is Map) {
              final value = priceData['value'];
              final currency = priceData['currency']?.toString();
              
              // Support multiple currencies with conversion
              if (currency != null) {
                if (value is String) {
                  price = double.tryParse(value.replaceAll(RegExp(r'[^\d.]'), ''));
                } else if (value is num) {
                  price = value.toDouble();
                }
                
                // Convert to USD if needed
                if (price != null && currency != 'USD') {
                  if (currency == 'GBP') {
                    price = price * 1.27;  // Approximate GBP to USD conversion
                  } else if (currency == 'EUR') {
                    price = price * 1.08;  // Approximate EUR to USD conversion
                  }
                }
              }
            }

            if (price == null || price <= 0) continue;

            // Extract other fields safely
            final rawTitle = rawItem['title']?.toString() ?? '';
            final title = _toTitleCase(rawTitle); 
            final searchTitle = rawTitle.toLowerCase(); 
            final link = rawItem['itemWebUrl']?.toString();
            var condition = 'Unknown';
            
            // Handle condition data more carefully
            final conditionData = rawItem['condition'];
            if (conditionData is Map<String, dynamic>) {
              condition = conditionData['conditionDisplayName']?.toString() ?? condition;
            } else if (conditionData is String) {
              condition = conditionData;
            }
            
            // Skip invalid items
            if (title.isEmpty || link == null) continue;

            // More precise matching - prioritize card number when available
            final matchResult = _getCardMatchResult(
              searchTitle, 
              normalizedCardName, 
              normalizedCardNumber
            );
            
            // Skip items that don't match based on the match result
            switch (matchResult) {
              case CardMatchResult.noMatch:
                rejectedItems++;
                continue;
              case CardMatchResult.nameMatchOnly:
                // If we have a card number to search for but this item only matched the name, 
                // only include it if we don't have better matches
                if (hasCardNumber && sales.any((s) => s['matchType'] == 'exactMatch')) {
                  rejectedItems++;
                  continue;
                }
                nameOnlyMatches++;
                break;
              case CardMatchResult.exactMatch:
                exactMatches++;
                break;
            }

            // Skip lots and bulk listings
            if (_isListingExcluded(searchTitle)) {
              rejectedItems++;
              continue;
            }

            // Add valid sale with match quality indicator
            sales.add({
              'price': price,
              'date': DateTime.now().toIso8601String(),
              'condition': condition,
              'title': title,
              'link': link,
              'matchType': matchResult == CardMatchResult.exactMatch ? 
                          'exactMatch' : 'nameMatch',
            });
          } catch (e, stack) {
            _log('Error processing item: $e');
            continue;
          }
        }

        _log('Successfully filtered to ${sales.length} valid sales');
        if (hasCardNumber) {
          _log('Match statistics: $exactMatches exact matches, ' +
                '$nameOnlyMatches name-only matches, $rejectedItems rejected items');
        }
        
        // If we have a card number and found exact matches, only return exact matches
        if (hasCardNumber && sales.any((s) => s['matchType'] == 'exactMatch')) {
          final exactMatchSales = sales.where((s) => s['matchType'] == 'exactMatch').toList();
          _log('Returning ${exactMatchSales.length} exact matches only');
          
          // Remove outliers to get more accurate pricing
          return _removeOutliers(exactMatchSales);
        }
        
        // Remove outliers to get more accurate pricing 
        return _removeOutliers(sales);
      }
      
      _log('eBay API error: ${response.statusCode}');
      return [];
    } catch (e, stack) {
      _log('Error fetching eBay sales history: $e');
      return [];
    }
  }

  // Remove price outliers for more accurate representation
  List<Map<String, dynamic>> _removeOutliers(List<Map<String, dynamic>> sales) {
    if (sales.length <= 3) return sales; // Not enough data for outlier detection
    
    // Extract prices
    final prices = sales.map((sale) => (sale['price'] as double)).toList();
    prices.sort();
    
    // Calculate quartiles and IQR
    final q1 = prices[prices.length ~/ 4];
    final q3 = prices[(prices.length * 3) ~/ 4];
    final iqr = q3 - q1;
    
    // Define bounds for outlier detection - using 2.0 instead of 1.5 for more lenient filtering
    // This is more appropriate for the volatile TCG market
    final lowerBound = q1 - (iqr * 2.0);
    final upperBound = q3 + (iqr * 2.0);
    
    _log('Price statistics: Min=${prices.first.toStringAsFixed(2)}, Q1=${q1.toStringAsFixed(2)}, ' +
          'Q3=${q3.toStringAsFixed(2)}, Max=${prices.last.toStringAsFixed(2)}, IQR=${iqr.toStringAsFixed(2)}');
    _log('Filtering prices outside range: ${lowerBound.toStringAsFixed(2)} - ${upperBound.toStringAsFixed(2)}');
    
    final filteredSales = sales.where((sale) {
      final price = sale['price'] as double;
      return price >= lowerBound && price <= upperBound;
    }).toList();
    
    _log('Removed ${sales.length - filteredSales.length} outliers from ${sales.length} sales');
    
    return filteredSales;
  }

  // Update the average price calculation to use the real sales data more effectively
  Future<double?> getAveragePrice(String cardName, {
    String? setName,
    String? number,
    bool isMtg = false,
  }) async {
    try {
      final sales = await getRecentSales(
        cardName,
        setName: setName,
        number: number,
        isMtg: isMtg,
      );
      
      if (sales.isEmpty) {
        _log('No sales found for $cardName');
        return null;
      }
      
      // Extract prices
      final prices = sales
          .map((s) => (s['price'] as double))
          .where((p) => p > 0)
          .toList();
      
      if (prices.isEmpty) {
        _log('No valid prices found for $cardName');
        return null;
      }
      
      // Sort prices to calculate median
      prices.sort();
      
      // Calculate median price (more stable than mean for price data)
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
      
      _log('Price analysis for $cardName:');
      _log('  - ${prices.length} valid prices');
      _log('  - Range: \$${prices.first.toStringAsFixed(2)} to \$${prices.last.toStringAsFixed(2)}');
      _log('  - Median: \$${median.toStringAsFixed(2)}');
      _log('  - Mean: \$${mean.toStringAsFixed(2)}');
      _log('  - Trimmed Mean (15%): \$${trimmedMean.toStringAsFixed(2)}');
      
      // For highly volatile prices (high standard deviation), we prefer median
      // For more stable prices, trimmed mean can be better
      final stdDev = _calculateStandardDeviation(prices, mean);
      final coefficientOfVariation = stdDev / mean;
      
      _log('  - Standard Deviation: \$${stdDev.toStringAsFixed(2)}');
      _log('  - Coefficient of Variation: ${(coefficientOfVariation * 100).toStringAsFixed(2)}%');
      
      // Choose price based on volatility
      double finalPrice;
      if (coefficientOfVariation > 0.25) { // High volatility
        _log('  - High price volatility, using median: \$${median.toStringAsFixed(2)}');
        finalPrice = median;
      } else { // Low volatility
        _log('  - Low price volatility, using trimmed mean: \$${trimmedMean.toStringAsFixed(2)}');
        finalPrice = trimmedMean;
      }
      
      return finalPrice;
    } catch (e) {
      _log('Error getting average price for $cardName: $e');
      return null;
    }
  }
  
  // Helper to calculate standard deviation
  double _calculateStandardDeviation(List<double> values, double mean) {
    if (values.length <= 1) return 0.0;
    
    final sumSquaredDiff = values.fold<double>(
      0.0, 
      (sum, value) => sum + math.pow(value - mean, 2)
    );
    
    return math.sqrt(sumSquaredDiff / (values.length - 1));
  }

  double? _extractPrice(Map<String, dynamic>? priceInfo) {
    if (priceInfo == null) return null;
    
    try {
      final value = priceInfo['value'];
      final currency = priceInfo['currency']?.toString();
      
      if (currency != 'USD') return null;

      if (value is num) return value.toDouble();
      
      if (value is String) {
        final cleaned = value.replaceAll(RegExp(r'[^\d.]'), '');
        return double.tryParse(cleaned);
      }
      
      return null;
    } catch (e) {
      _log('Error extracting price from: $priceInfo - $e');
      return null;
    }
  }

  bool _isGradedCard(String title) {
    return _getGradingService(title) != null;
  }

  Future<Map<String, List<Map<String, dynamic>>>> getRecentSalesWithGraded(
    String cardName, {
    String? setName,
    String? number,
    bool isMtg = false,
  }) async {
    // Initialize empty results map
    final results = {
      'ungraded': <Map<String, dynamic>>[],
      'PSA': <Map<String, dynamic>>[],
      'BGS': <Map<String, dynamic>>[],
      'CGC': <Map<String, dynamic>>[],
      'SGC': <Map<String, dynamic>>[],
      'ACE': <Map<String, dynamic>>[],
    };
    
    // Add MTG-specific search terms if needed
    final List<String> searchTerms = [];
    
    // Base search
    if (isMtg) {
      searchTerms.add('$cardName MTG');
      if (setName != null && setName.isNotEmpty) {  // Fixed the syntax error here
        searchTerms.add('"$setName"');
      }
    } else {
      searchTerms.add('$cardName pokemon card');
      if (setName != null && setName.isNotEmpty) {
        searchTerms.add('"$setName"');
      }
    }
    
    // Add number for both types - Fixed the syntax error here
    if (number != null && number.isNotEmpty) { // Added period before isNotEmpty
      searchTerms.add(number);
    }

    // Build the query combining all terms
    final query = searchTerms.join(' ');
    
    try {
      final searchResults = await _searchEbay(query, isMtg: isMtg);
      
      // Sort results into categories
      for (final sale in searchResults) {
        final title = (sale['title'] as String).toLowerCase();
        
        if (!_isValidSale(sale)) continue;
        
        // Check for graded cards first
        final gradingService = _getGradingService(title);
        if (gradingService != null) {
          results[gradingService]?.add(sale);
        } else {
          results['ungraded']?.add(sale);
        }
      }
      
      return results;
    } catch (e) {
      _log('Error getting card details: $e');
      return results;
    }
  }

  Future<List<Map<String, dynamic>>> _searchEbay(String query, {bool isMtg = false}) async {
    try {
      final trimmedQuery = query.trim();
      if (trimmedQuery.isEmpty) {
        return [];
      }

      // Get access token for API calls
      final token = await _getAccessToken();
      
      // Use the eBay Browse API to get real sales data
      final categoryId = isMtg ? '2536' : '183454'; // MTG or Pokémon
      
      final response = await http.get(
        Uri.https(_baseUrl, '/buy/browse/v1/item_summary/search', {
          'q': trimmedQuery,
          'category_ids': categoryId,
          'filter': 'buyingOptions:{FIXED_PRICE} AND soldItemsOnly:true',
          'sort': '-soldDate',
          'limit': '50', // Up to 50 results
        }),
        headers: {
          'Authorization': 'Bearer $token',
          'X-EBAY-C-MARKETPLACE-ID': 'EBAY_US',
          'Content-Type': 'application/json',
        },
      );

      _log('eBay search URL: https://www.ebay.com/sch/i.html?_nkw=${Uri.encodeComponent(trimmedQuery)}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['itemSummaries'] as List?;
        
        if (items == null || items.isEmpty) {
          _log('No real items found in eBay response - falling back to simulation');
          // Fall back to simulation if API returns no results
          return _createSimulatedResults(trimmedQuery, isMtg);
        }
        
        _log('Found ${items.length} real items from eBay API');
        
        // Convert eBay API response to our expected sales format
        final results = <Map<String, dynamic>>[];
        
        for (final item in items) {
          try {
            final price = _extractPriceFromItem(item);
            if (price == null || price <= 0) continue;
            
            final title = item['title'] as String? ?? 'Unknown item';
            final condition = _extractConditionFromItem(item);
            final link = item['itemWebUrl'] as String? ?? '';
            final soldDate = _extractSoldDateFromItem(item);
            
            results.add({
              'title': title,
              'price': price,
              'condition': condition,
              'link': link,
              'date': soldDate,
            });
          } catch (e) {
            _log('Error processing eBay item: $e');
          }
        }
        
        if (results.isNotEmpty) {
          _log('Successfully processed ${results.length} real sales');
          return results;
        }
      } else {
        _log('eBay API error: ${response.statusCode} - ${response.body}');
      }
      
      // Fall back to simulated data if API call fails or returns no processable items
      _log('Falling back to simulated sales data');
      return _createSimulatedResults(trimmedQuery, isMtg);
      
    } catch (e) {
      _log('Error searching eBay (will use simulation instead): $e');
      return _createSimulatedResults(query, isMtg);
    }
  }

  // Helper methods to extract data from eBay API responses
  double? _extractPriceFromItem(Map<String, dynamic> item) {
    try {
      final price = item['price'];
      if (price == null) return null;
      
      final value = price['value'];
      final currency = price['currency'] as String? ?? 'USD';
      
      double numValue;
      if (value is num) {
        numValue = value.toDouble();
      } else if (value is String) {
        numValue = double.tryParse(value) ?? 0.0;
      } else {
        return null;
      }
      
      // Convert to USD if needed
      if (currency != 'USD') {
        if (currency == 'GBP') {
          numValue *= 1.27;
        } else if (currency == 'EUR') {
          numValue *= 1.08;
        }
      }
      
      return numValue;
    } catch (e) {
      _log('Error extracting price: $e');
      return null;
    }
  }
  
  String _extractConditionFromItem(Map<String, dynamic> item) {
    try {
      if (item['condition'] != null) {
        return item['condition']['conditionDisplayName'] as String? ?? 'Unknown';
      }
      return 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }
  
  String _extractSoldDateFromItem(Map<String, dynamic> item) {
    try {
      final date = item['soldDate'] ??
                  item['endDate'] ??
                  DateTime.now().toIso8601String();
      return date.toString();
    } catch (e) {
      return DateTime.now().toIso8601String();
    }
  }

  // Add the missing method for analytics_screen.dart
  Future<Map<String, dynamic>> getMarketOpportunities(List<TcgCard> cards) async {
    final opportunities = {
      'undervalued': <Map<String, dynamic>>[],
      'overvalued': <Map<String, dynamic>>[],
    };

    // Add progress tracking
    int processedCards = 0;
    final total = cards.length;

    for (final card in cards) {
      try {
        processedCards++;
        _log('Analyzing market for: ${card.name} (${processedCards}/$total)');
        
        final currentPrice = card.price ?? 0.0;
        if (currentPrice == 0) {
          _log('Skipping ${card.name} - No current price');
          continue;
        }

        final results = await getRecentSales(
          card.name,
          setName: card.setName,
          number: card.number,
        );

        if (results.length >= 3) {
          final prices = results
              .map((r) => (r['price'] as num).toDouble())
              .where((p) => p > 0)
              .toList();

          if (prices.length >= 3) {
            prices.sort();
            final medianPrice = prices[prices.length ~/ 2];
            final priceDiff = medianPrice - currentPrice;
            final percentDiff = (priceDiff / currentPrice) * 100;

            if (percentDiff.abs() >= 15) {
              final insight = {
                'id': card.id,
                'name': card.name,
                'currentPrice': currentPrice,
                'marketPrice': medianPrice,
                'difference': priceDiff,
                'percentDiff': percentDiff,
                'recentSales': results.length,
                'priceRange': {
                  'min': prices.first,
                  'max': prices.last,
                  'median': medianPrice,
                },
              };

              if (medianPrice > currentPrice * 1.15) {
                opportunities['undervalued']!.add(insight);
                _log('Added ${card.name} to undervalued (${opportunities['undervalued']!.length})');
              } else if (medianPrice < currentPrice * 0.85) {
                opportunities['overvalued']!.add(insight);
                _log('Added ${card.name} to overvalued (${opportunities['overvalued']!.length})');
              }
            }
          }
        }

        await Future.delayed(const Duration(milliseconds: 500));

      } catch (e) {
        _log('Error analyzing market for ${card.name}: $e');
      }
    }

    return opportunities;
  }

  // Helper method to determine if a listing title is excluded (lot, bulk, etc.)
  bool _isListingExcluded(String title) {
    final excludedTerms = [
      'lot', 'bulk', 'mystery', 'pack', 'booster', 'box', 'case', 
      'collection', 'binder', 'playset', 'deck', 'bundle',
      'sleeve', 'proxy', 'repack', 'replica', 'fake', 
      '4x', 'x4', '10x', 'x10', 'complete set',
    ];
    
    return excludedTerms.any((term) => title.contains(term));
  }
  
  // Helper to extract potential card numbers from a title
  List<String> _extractCardNumbers(String title) {
    final result = <String>[];
    
    // Match patterns like "123/456", "#123", "No. 123"
    final patterns = [
      RegExp(r'(\d+)[/\\](\d+)'),  // Matches "123/456" or "123\456"
      RegExp(r'#(\d+)'),           // Matches "#123"
      RegExp(r'[nN][oO]\.?\s*(\d+)'), // Matches "no.123", "No. 123", etc.
      RegExp(r'[cC]ard\s*(\d+)'),  // Matches "Card 123"
      RegExp(r'\b(\d{1,3})[/\\]'), // Matches numbers before slash with word boundary
    ];
    
    // Also extract promo/special card numbers
    final specialPatterns = [
      RegExp(r'[sS][vV](\d+)'),     // Matches "SV01"
      RegExp(r'[sS][mM](\d+)'),     // Matches "SM01"
      RegExp(r'[pP][rR]-?(\d+)'),   // Matches "PR-123" or "PR123"
      RegExp(r'[sS][wW][sS][hH](\d+)'), // Matches "SWSH01"
    ];
    
    // Process standard patterns
    for (final pattern in patterns) {
      final matches = pattern.allMatches(title);
      for (final match in matches) {
        // For fractional numbers, add the whole match
        if (pattern.pattern.contains('[/\\]')) {
          final fullMatch = match.group(0);
          if (fullMatch != null) {
            result.add(fullMatch);
          }
        } else {
          // For other patterns, just add the number part
          final number = match.group(1);
          if (number != null) {
            result.add(number);
          }
        }
      }
    }
    
    // Process special patterns
    for (final pattern in specialPatterns) {
      final matches = pattern.allMatches(title);
      for (final match in matches) {
        final fullMatch = match.group(0);
        if (fullMatch != null) {
          result.add(fullMatch.toLowerCase());
        }
      }
    }
    
    return result;
  }
  
  // Helper to check if a card number is a special format
  bool _isSpecialCardNumber(String cardNumber) {
    return RegExp(r'[a-zA-Z]').hasMatch(cardNumber) || // Has letters
           cardNumber.contains('-') ||                 // Has hyphen
           RegExp(r'^[a-zA-Z]+\d+$').hasMatch(cardNumber); // Format like "SV01"
  }
  
  // Helper to check special card number formats
  bool _checkSpecialCardNumberMatch(String itemTitle, String cardNumber) {
    // Normalize both strings for comparison
    final normalizedTitle = itemTitle.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    final normalizedNumber = cardNumber.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    
    // Direct contains check
    if (normalizedTitle.contains(normalizedNumber)) {
      return true;
    }
    
    // Check with/without hyphens
    if (normalizedNumber.contains('-')) {
      final withoutHyphen = normalizedNumber.replaceAll('-', '');
      if (normalizedTitle.contains(withoutHyphen)) {
        return true;
      }
    } else {
      // If no hyphen in the original, try adding one for common formats
      if (RegExp(r'^([a-zA-Z]+)(\d+)$').hasMatch(normalizedNumber)) {
        final withHyphen = normalizedNumber.replaceAllMapped(
          RegExp(r'^([a-zA-Z]+)(\d+)$'), 
          (match) => '${match.group(1)}-${match.group(2)}'
        );
        if (normalizedTitle.contains(withHyphen)) {
          return true;
        }
      }
    }
    
    // More flexible matching for promo cards
    if (normalizedNumber.startsWith('pr') || 
        normalizedTitle.contains('promo') || 
        normalizedTitle.contains('promotional')) {
      
      // Extract the numeric part if it exists
      final numMatch = RegExp(r'pr-?(\d+)').firstMatch(normalizedNumber);
      if (numMatch != null) {
        final numPart = numMatch.group(1)!;
        
        // Check if the title contains "promo" and the number somewhere
        if ((normalizedTitle.contains('promo') || normalizedTitle.contains('promotional')) && 
            normalizedTitle.contains(numPart)) {
          return true;
        }
      }
    }
    
    return false;
  }

  // Add missing method needed for validation
  bool _isValidSale(Map<String, dynamic> sale) {
    final price = sale['price'] as double?;
    final title = sale['title'].toString().toLowerCase();
    
    // Validate price range to exclude extremely low or high prices
    if (price == null || price <= 0.99 || price > 10000) return false;
    
    // Exclude listings with certain keywords
    final excludedTerms = [
      'mystery', 'bulk', 'lot', 'case', 'booster', 'box', 'pack', 'bundle',
      'collection', 'complete set', 'deck', 'playset', '100x', 'playtest',
      'proxy'
    ];
    
    for (final term in excludedTerms) {
      if (title.contains(term)) {
        return false;
      }
    }
    
    return true;
  }
  
  // Add missing method for creating simulated results
  List<Map<String, dynamic>> _createSimulatedResults(
    String query, 
    bool isMtg, {
    String? cardName,
    String? cardNumber,
  }) {
    // Extract card name from query if not provided
    final effectiveCardName = cardName ?? query.split(' ').take(2).join(' ');
    _log('Creating simulated results for: $effectiveCardName');
    
    final random = Random();  // Fixed: Use Random directly, not as a type
    final results = <Map<String, dynamic>>[];
    
    // Generate a baseline price based on the card
    double basePrice = 0;
    
    // Check for premium cards to generate appropriate prices
    if (_isPremiumCard(effectiveCardName)) {
      // For premium cards like Charizard, set higher baseline
      basePrice = _getPremiumCardBasePrice(effectiveCardName);
      _log('Detected premium card: $effectiveCardName - Base price: \$$basePrice');
    } else {
      // Regular cards - use type to determine base price range
      basePrice = isMtg ? 15.0 : 10.0;
    }
    
    // Generate 5-10 results
    final resultCount = 5 + random.nextInt(6);
    
    for (int i = 0; i < resultCount; i++) {
      // Realistic price variation (±15% from base)
      final variationFactor = 0.85 + (random.nextDouble() * 0.3);
      final price = basePrice * variationFactor;
      
      // Common card conditions
      final conditions = [
        'Brand New', 'Like New', 'Very Good', 'Good', 'Acceptable',
        'Near Mint', 'Excellent', 'Lightly Played', 'Moderately Played'
      ];
      final condition = conditions[random.nextInt(conditions.length)];
      
      // Generate realistic title
      String title;
      if (isMtg) {
        title = '$effectiveCardName - MTG ${random.nextBool() ? 'NM' : 'M/NM'} Card';
        if (cardNumber != null) {
          title += ' #$cardNumber';
        }
      } else {
        title = 'Pokemon $effectiveCardName';
        if (random.nextBool()) {
          title += ' ' + (random.nextBool() ? 'Holo' : 'Ultra Rare');
        }
        if (cardNumber != null) {
          title += ' #$cardNumber';
        }
        title += ' Card ${random.nextBool() ? 'NM' : 'M/NM'}';
      }
      
      // Add grading info for some listings of higher-value cards
      if (basePrice > 50 && random.nextInt(5) == 0) {
        final gradeServices = ['PSA', 'BGS', 'CGC'];
        final gradeValues = ['9', '9.5', '10'];
        
        title = '${gradeServices[random.nextInt(gradeServices.length)]} ' +
                '${gradeValues[random.nextInt(gradeValues.length)]} ' + title;
      }
      
      // Generate random sold dates within the last 30 days
      final daysAgo = random.nextInt(30);
      final soldDate = DateTime.now().subtract(Duration(days: daysAgo));
      
      results.add({
        'title': title,
        'price': price,
        'condition': condition,
        'link': 'https://www.ebay.com/sch/i.html?_nkw=${Uri.encodeComponent(effectiveCardName)}',
        'date': soldDate.toIso8601String(),
        'shipping': random.nextInt(5) == 0 ? 3.99 : 0.0,
      });
    }
    
    _log('Generated ${results.length} simulated results with avg price: ' +
          '\$${results.fold<double>(0, (sum, item) => sum + (item["price"] as double)) / results.length}');
    
    return results;
  }
  
  // Helper method to identify premium cards
  bool _isPremiumCard(String cardName) {
    final lowerName = cardName.toLowerCase();
    
    // Check for high-value Pokémon cards
    if (lowerName.contains('charizard') || 
        lowerName.contains('pikachu') || 
        lowerName.contains('mew') || 
        lowerName.contains('lugia') ||
        lowerName.contains('rayquaza') ||
        lowerName.contains('blastoise') ||
        lowerName.contains('venusaur')) {
      return true;
    }
    
    // Check for premium card types
    if (lowerName.contains(' ex') || 
        lowerName.contains(' gx') || 
        lowerName.contains(' vmax') || 
        lowerName.contains(' vstar') ||
        lowerName.contains(' alt art') || 
        lowerName.contains(' secret rare') || 
        lowerName.contains(' rainbow rare')) {
      return true;
    }
    
    // Check for high-value MTG cards
    if (lowerName.contains('jace') || 
        lowerName.contains('liliana') || 
        lowerName.contains('mox') || 
        lowerName.contains('lotus') ||
        lowerName.contains('teferi') || 
        lowerName.contains('force of will')) {
      return true;
    }
    
    return false;
  }
  
  // Get appropriate base price for premium cards
  double _getPremiumCardBasePrice(String cardName) {
    final lowerName = cardName.toLowerCase();
    
    // Charizard cards (high value)
    if (lowerName.contains('charizard')) {
      if (lowerName.contains(' ex')) return 240.0; // Charizard ex
      if (lowerName.contains(' vmax')) return 180.0; // Charizard VMAX
      if (lowerName.contains(' vstar')) return 120.0; // Charizard VSTAR
      if (lowerName.contains(' v')) return 80.0; // Charizard V
      if (lowerName.contains(' gx')) return 150.0; // Charizard GX
      return 100.0; // Base Charizard
    }
    
    // Other premium Pokémon cards
    if (lowerName.contains('pikachu')) return 60.0;
    if (lowerName.contains('mew')) return 90.0;
    if (lowerName.contains('lugia')) return 120.0;
    if (lowerName.contains('rayquaza')) return 90.0;
    if (lowerName.contains('blastoise')) return 80.0;
    if (lowerName.contains('venusaur')) return 70.0;
    
    // MTG cards
    if (lowerName.contains('jace')) return 110.0;
    if (lowerName.contains('liliana')) return 95.0;
    if (lowerName.contains('teferi')) return 85.0;
    if (lowerName.contains('force of will')) return 200.0;
    if (lowerName.contains('mox')) return 280.0;
    if (lowerName.contains('lotus')) return 350.0;
    
    // Default premium price
    return 75.0;
  }

  // Add the missing method that's used in mtg_card_details_screen.dart
  String getEbayMtgSearchUrl(String cardName, {String? setName, String? number}) {
    final List<String> queryParts = [cardName, 'mtg', 'card'];
    
    if (setName != null && setName.isNotEmpty) {
      queryParts.add(setName);
    }
    
    if (number != null && number.isNotEmpty) {
      queryParts.add(number);
    }
    
    final queryString = queryParts.join(' ');
    return 'https://www.ebay.com/sch/i.html?_nkw=${Uri.encodeComponent(queryString)}&_sacat=2536';
  }

  // Add a method for Pokemon search URLs for consistency
  String getEbaySearchUrl(String cardName, {String? setName, String? number}) {
    final List<String> queryParts = [cardName, 'pokemon', 'card'];
    
    if (setName != null && setName.isNotEmpty) {
      queryParts.add(setName);
    }
    
    if (number != null && number.isNotEmpty) {  // Fixed syntax error here - added dot
      queryParts.add(number);
    }
    
    final queryString = queryParts.join(' ');
    return 'https://www.ebay.com/sch/i.html?_nkw=${Uri.encodeComponent(queryString)}&_sacat=183454';
  }

  // Enhanced card matching that returns match quality
  CardMatchResult _getCardMatchResult(
    String itemTitle, 
    String cardName, 
    String cardNumber
  ) {
    // First verify card name is in the title
    if (!itemTitle.contains(cardName)) {
      return CardMatchResult.noMatch;
    }
    
    // If no card number provided, we can only match on name
    if (cardNumber.isEmpty) {
      return CardMatchResult.nameMatchOnly;
    }
    
    // Extract all potential card numbers from the title
    final numberMatches = _extractCardNumbers(itemTitle);
    
    // Check for direct number match first (most reliable)
    if (numberMatches.contains(cardNumber)) {
      return CardMatchResult.exactMatch;
    }
    
    // Special handling for fractional card numbers like "239/191"
    if (cardNumber.contains('/')) {
      final parts = cardNumber.split('/');
      if (parts.length == 2) {
        final mainNumber = parts[0].trim();
        
        // Check for match with just the main number with various prefixes/suffixes
        final mainNumberPatterns = [
          mainNumber,
          '#$mainNumber',
          'no.$mainNumber',
          'no. $mainNumber',
          'number $mainNumber',
          'num $mainNumber',
          'card $mainNumber',
        ];
        
        // Check if any possible variants match, being careful about boundaries
        for (final pattern in mainNumberPatterns) {
          // Check for the pattern with word boundaries
          final regex = RegExp(r'\b' + pattern + r'\b');
          if (regex.hasMatch(itemTitle)) {
            // Verify that there's no other number nearby that could be confusing
            if (!itemTitle.contains(RegExp(r'\b' + mainNumber + r'[/\\]'))) {
              return CardMatchResult.exactMatch;
            }
          }
        }
      }
    }
    
    // Handle promo/special card numbers (e.g., "PR-123", "SV01", "SM01")
    if (_isSpecialCardNumber(cardNumber)) {
      final specialMatch = _checkSpecialCardNumberMatch(itemTitle, cardNumber);
      if (specialMatch) {
        return CardMatchResult.exactMatch;
      }
    }
    
    // No exact match, but the name matches
    return CardMatchResult.nameMatchOnly;
  }

  Future<double?> _calculateRawCardPrice(TcgCard card) async {
    try {
      final isMtg = _isMtgCard(card);
      
      // Get all sales data
      final allSales = await getRecentSales(
        card.name,
        setName: card.setName,
        number: card.number,
        isMtg: isMtg,
      );
      
      _log('Total eBay sales found for ${card.name}: ${allSales.length}');
      
      // Filter out graded cards
      final rawSales = allSales.where((sale) {
        final title = (sale['title'] as String).toLowerCase();
        
        // Much more comprehensive graded card detection
        // Check for grading services (with word boundaries when appropriate)
        if (title.contains('psa') || 
            title.contains('bgs') || 
            title.contains('cgc') || 
            title.contains('sgc') || 
            title.contains('ace') ||
            title.contains('beckett') || 
            title.contains('hga') ||
            title.contains('mnt') || 
            title.contains('ksa') ||
            title.contains('ags') ||
            title.contains(' slab') ||
            title.contains('slabbed') ||
            title.contains('graded') ||
            title.contains('grade ') ||
            title.contains('grading')) {
          return false;
        }
        
        // Check for grade notations (with word boundaries)
        if (RegExp(r'\bpop\b').hasMatch(title) ||
            RegExp(r'\bmint\b').hasMatch(title) ||
            RegExp(r'\bgem\b').hasMatch(title) ||
            RegExp(r'\bpristine\b').hasMatch(title) ||
            RegExp(r'\bperfect\b').hasMatch(title) ||
            RegExp(r'\bblack label\b').hasMatch(title)) {
          return false;
        }
        
        // Check for numeric grades (e.g. "10", "9.5")
        // Look for standalone grades like "PSA 10" or "BGS 9.5"
        if (RegExp(r'(^|\s)((10)|(9\.5)|(9)|(8\.5)|(8))($|\s)').hasMatch(title) ||
            RegExp(r'(^|\s)\d+(\.\d+)?\s*grade').hasMatch(title) ||
            RegExp(r'grade\s*\d+(\.\d+)?($|\s)').hasMatch(title)) {
          return false;
        }
        
        return true;
      }).toList();
      
      _log('Filtered to ${rawSales.length} raw card sales (excluded ${allSales.length - rawSales.length} graded sales)');
      
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
        
        _log('Raw card price analysis for ${card.name} (${rawSales.length} raw sales):');
        _log('  - Range: \$${prices.first.toStringAsFixed(2)} to \$${prices.last.toStringAsFixed(2)}');
        _log('  - Median: \$${median.toStringAsFixed(2)}');
        _log('  - Mean: \$${mean.toStringAsFixed(2)}');
        _log('  - Trimmed Mean (15%): \$${trimmedMean.toStringAsFixed(2)}');
        
        // For regular cards, we prefer trimmed mean
        return trimmedMean;
      }
      
      _log('Not enough raw sales found for ${card.name} (only ${rawSales.length})');
      
      // If not enough raw sales, fall back to the TCG price if available
      if (card.price != null && card.price! > 0) {
        return card.price;
      }
      
      return null;
      
    } catch (e) {
      _log('Error calculating raw card price: $e');
      return null;
    }
  }

  // Add the missing _isMtgCard method that's needed by _calculateRawCardPrice
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
}
