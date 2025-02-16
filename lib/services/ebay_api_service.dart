import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import '../models/tcg_card.dart';  // Add this import

class EbayApiService {
  static const String _clientId = 'SamMay-CardScan-PRD-4227403db-8b726135';
  static const String _clientSecret = 'PRD-227403db4eda-4945-4811-aabd-f9fe';
  static const String _baseUrl = 'api.ebay.com';
  String? _accessToken;
  DateTime? _tokenExpiry;

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

  // Add this helper method near the top of the class
  String _toTitleCase(String text) {
    if (text.isEmpty) return text;
    
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  // Add this method to classify grading service
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
  }) async {
    final token = await _getAccessToken();
    
    try {
      // Build search query
      final queryParts = <String>[cardName];
      if (number != null && number.isNotEmpty) {
        queryParts.add(number);
      }
      if (setName?.isNotEmpty ?? false) {
        queryParts.add(setName!);
      }
      queryParts.add('pokemon card');
      final searchQuery = queryParts.join(' ');
      
      print('Searching eBay with query: $searchQuery');
      
      final response = await http.get(
        Uri.https(_baseUrl, '/buy/browse/v1/item_summary/search', {
          'q': searchQuery,
          'category_ids': '183454',
          'filter': 'buyingOptions:{FIXED_PRICE} AND soldItemsOnly:true',  // Add soldItemsOnly filter
          'sort': '-soldDate',  // Sort by most recent sales
          'limit': '100',
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
          print('No items found in eBay response');
          return [];
        }

        print('Found ${items.length} items in eBay response');
        final sales = <Map<String, dynamic>>[];
        
        for (final dynamic rawItem in items) {
          try {
            // Ensure the item is a Map
            if (rawItem is! Map<String, dynamic>) {
              print('Invalid item format: $rawItem');
              continue;
            }

            // Extract price data safely
            final priceData = rawItem['price'];
            if (priceData == null) continue;

            double? price;
            if (priceData is Map) {
              final value = priceData['value'];
              final currency = priceData['currency']?.toString();
              
              if (currency != 'USD') continue;
              
              if (value is String) {
                price = double.tryParse(value.replaceAll(RegExp(r'[^\d.]'), ''));
              } else if (value is num) {
                price = value.toDouble();
              }
            }

            if (price == null || price <= 0) continue;

            // Extract other fields safely
            final rawTitle = rawItem['title']?.toString() ?? '';
            final title = _toTitleCase(rawTitle); // Convert to title case
            final searchTitle = rawTitle.toLowerCase(); // Use lowercase for searching
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

            // Skip if title doesn't match card name (use searchTitle for comparison)
            if (!searchTitle.contains(cardName.toLowerCase())) continue;

            // Skip if number is provided and doesn't match (use searchTitle for comparison)
            if (number?.isNotEmpty ?? false) {
              if (!searchTitle.contains(number!)) continue;
            }

            // Skip lots and bulk listings (use searchTitle for comparison)
            if (searchTitle.contains('lot') || 
                searchTitle.contains('bulk') ||
                searchTitle.contains('mystery') ||
                searchTitle.contains('pack')) {
              continue;
            }

            // Add valid sale with properly cased title
            sales.add({
              'price': price,
              'date': DateTime.now().toIso8601String(),
              'condition': condition,
              'title': title, // Use the title-cased version
              'link': link,
            });
          } catch (e, stack) {
            print('Error processing item: $e');
            print('Stack trace: $stack');
            continue;
          }
        }

        print('Successfully filtered to ${sales.length} valid sales');
        return sales;
      }
      
      print('eBay API error: ${response.statusCode}');
      print('Response body: ${response.body}');
      return [];
    } catch (e, stack) {
      print('Error fetching eBay sales history: $e');
      print('Stack trace: $stack');
      return [];
    }
  }

  // Update price extraction to be more robust
  double? _extractPrice(Map<String, dynamic>? priceInfo) {
    if (priceInfo == null) return null;
    
    try {
      // Check for required fields
      final value = priceInfo['value'];
      final currency = priceInfo['currency']?.toString();
      
      // Only process USD prices
      if (currency != 'USD') {
        return null;
      }

      // Handle different value types
      if (value is num) {
        return value.toDouble();
      }
      
      if (value is String) {
        final cleaned = value.replaceAll(RegExp(r'[^\d.]'), '');
        return double.tryParse(cleaned);
      }
      
      return null;
    } catch (e) {
      print('Error extracting price from: $priceInfo - $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> _searchWithQuery(String query) async {
    final token = await _getAccessToken();
    
    try {
      print('Searching eBay with query: $query');
      final response = await http.get(
        Uri.https(_baseUrl, '/buy/browse/v1/item_summary/search', {
          'q': query,
          'filter': 'buyingOptions:{FIXED_PRICE}',
          'sort': '-price',
          'limit': '100',
        }),
        headers: {
          'Authorization': 'Bearer $token',
          'X-EBAY-C-MARKETPLACE-ID': 'EBAY_US',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['itemSummaries'] == null) {
          print('No items found for query: $query');
          return [];
        }
        
        final results = (data['itemSummaries'] as List)
            .where((item) {
              final title = (item['title'] as String).toLowerCase();
              final price = _extractPrice(item['price']);
              
              // Debug price info
              print('Found listing: ${item['title']} - Price: ${item['price']}');
              
              // More strict filtering
              return !_isGradedCard(title) && 
                     !title.contains('lot') &&
                     !title.contains('bulk') &&
                     !title.contains('proxy') &&
                     !title.contains('mystery') &&
                     price != null &&
                     price > 0.10 && // Filter out unreasonably low prices
                     price < 10000.0; // Filter out unreasonably high prices
            })
            .map((item) {
              final price = _extractPrice(item['price']) ?? 0.0;
              return {
                'title': item['title'],
                'price': price,
                'currency': item['price']['currency'],
                'condition': item['condition'],
                'link': item['itemWebUrl'],
                'imageUrl': item['image']?['imageUrl'],
                'soldDate': item['soldDate'],
              };
            })
            .toList();

        print('Found ${results.length} valid listings');
        return results;
      } else {
        print('eBay API error: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error searching eBay: $e');
      return [];
    }
  }

  // Update isGradedCard to use the new grading service check
  bool _isGradedCard(String title) {
    return _getGradingService(title) != null;
  }

  Future<double?> getAveragePrice(String cardName, {
    String? setName,
    String? number,  // Add number parameter here too
  }) async {
    try {
      final sales = await getRecentSales(
        cardName,
        setName: setName,
        number: number,  // Pass number to getRecentSales
      );
      if (sales.isEmpty) {
        print('No sales found for: $cardName${setName != null ? ' ($setName)' : ''}');
        return null;
      }
      
      // Convert prices to numbers
      final prices = sales
          .map((s) => double.tryParse(s['price'].toString()))
          .where((p) => p != null)
          .cast<double>()
          .toList();
      
      if (prices.isEmpty) return null;
      
      // Remove extreme outliers using IQR method
      prices.sort();
      final q1 = prices[prices.length ~/ 4];
      final q3 = prices[(prices.length * 3) ~/ 4];
      final iqr = q3 - q1;
      final lowerBound = q1 - (iqr * 1.5);
      final upperBound = q3 + (iqr * 1.5);
      
      final filteredPrices = prices
          .where((p) => p >= lowerBound && p <= upperBound)
          .toList();
      
      if (filteredPrices.isEmpty) {
        print('No valid prices after filtering for: $cardName');
        return null;
      }
      
      final average = filteredPrices.reduce((a, b) => a + b) / filteredPrices.length;
      print('Found ${filteredPrices.length} valid prices for $cardName. Average: \$${average.toStringAsFixed(2)}');
      return average;
    } catch (e) {
      print('Error getting average price for $cardName: $e');
      return null;
    }
  }

  double _calculateStandardDeviation(List<double> values, double mean) {
    final squares = values.map((x) => pow(x - mean, 2));
    return sqrt(squares.reduce((a, b) => a + b) / values.length);
  }

  Future<Map<String, dynamic>> getMarketInsights(List<TcgCard> cards) async {
    final insights = {
      'marketPrices': <String, Map<String, dynamic>>{},
      'totalDifference': 0.0,
      'cardsAboveMarket': 0,
      'cardsBelowMarket': 0,
    };

    for (final card in cards) {
      try {
        final results = await getRecentSales(
          card.name,
          setName: card.setName,
          number: card.number,
        );

        if (results.isNotEmpty) {
          final prices = results
              .map((r) => double.tryParse(r['price'].toString()) ?? 0)
              .where((p) => p > 0)
              .toList();

          if (prices.isNotEmpty) {
            prices.sort();
            final avgMarketPrice = prices.reduce((a, b) => a + b) / prices.length;
            final medianPrice = prices[prices.length ~/ 2];
            final currentPrice = card.price ?? 0;
            final difference = currentPrice - avgMarketPrice;
            final percentDiff = (difference / avgMarketPrice) * 100;

            (insights['marketPrices'] as Map<String, Map<String, dynamic>>)[card.id] = {
              'name': card.name,
              'currentPrice': currentPrice,
              'avgMarketPrice': avgMarketPrice,
              'medianPrice': medianPrice,
              'lowestPrice': prices.first,
              'highestPrice': prices.last,
              'listingCount': prices.length,
              'difference': difference,
              'percentDifference': percentDiff,
            };

            insights['totalDifference'] = (insights['totalDifference'] as double) + difference;
            if (currentPrice > avgMarketPrice) {
              insights['cardsAboveMarket'] = (insights['cardsAboveMarket'] as int) + 1;
            } else if (currentPrice < avgMarketPrice) {
              insights['cardsBelowMarket'] = (insights['cardsBelowMarket'] as int) + 1;
            }
          }
        }
      } catch (e) {
        print('Error getting market insights for ${card.name}: $e');
      }
    }

    return insights;
  }

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
        print('Analyzing market for: ${card.name} (${processedCards}/$total)');
        
        final currentPrice = card.price ?? 0.0;
        if (currentPrice == 0) {
          print('Skipping ${card.name} - No current price');
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
                print('Added ${card.name} to undervalued (${opportunities['undervalued']!.length})');
              } else if (medianPrice < currentPrice * 0.85) {
                opportunities['overvalued']!.add(insight);
                print('Added ${card.name} to overvalued (${opportunities['overvalued']!.length})');
              }
            }
          }
        }

        await Future.delayed(const Duration(milliseconds: 500));

      } catch (e) {
        print('Error analyzing market for ${card.name}: $e');
      }
    }

    return opportunities;
  }

  Future<Map<String, dynamic>> getMarketActivity(List<String> cardNames) async {
    final now = DateTime.now();
    final activityMap = <String, int>{
      'last_24h': 0,
      'last_week': 0,
      'last_month': 0,
    };

    for (final name in cardNames) {
      try {
        final results = await getRecentSales(name);
        for (final sale in results) {
          final date = DateTime.tryParse(sale['soldDate'] ?? '');
          if (date != null) {
            final difference = now.difference(date);
            if (difference.inHours <= 24) activityMap['last_24h'] = (activityMap['last_24h'] ?? 0) + 1;
            if (difference.inDays <= 7) activityMap['last_week'] = (activityMap['last_week'] ?? 0) + 1;
            if (difference.inDays <= 30) activityMap['last_month'] = (activityMap['last_month'] ?? 0) + 1;
          }
        }
      } catch (e) {
        print('Error getting market activity for $name: $e');
      }
    }

    return activityMap;
  }

  Future<Map<String, List<Map<String, dynamic>>>> getRecentSalesWithGraded(String cardName, {
    String? setName,
    String? number,
    Duration lookbackPeriod = const Duration(days: 90),
  }) async {
    // Get the sales first using existing method
    final sales = await getRecentSales(
      cardName,
      setName: setName,
      number: number,
      lookbackPeriod: lookbackPeriod,
    );

    // Initialize result with empty lists for each category
    final result = {
      'ungraded': <Map<String, dynamic>>[],
      'PSA': <Map<String, dynamic>>[],
      'BGS': <Map<String, dynamic>>[],
      'CGC': <Map<String, dynamic>>[],
      'ACE': <Map<String, dynamic>>[],
      'SGC': <Map<String, dynamic>>[],
    };

    // Process sales...
    for (final sale in sales) {
      if (!_isValidSale(sale)) continue;
      
      final title = sale['title'].toString().toLowerCase();
      final gradingService = _getGradingService(title);
      
      if (gradingService != null) {
        result[gradingService]!.add(sale);
      } else {
        result['ungraded']!.add(sale);
      }
    }

    // Sort each category by date (most recent first)
    for (final sales in result.values) {
      sales.sort((a, b) {
        final dateA = DateTime.tryParse(a['date'] ?? '') ?? DateTime(1900);
        final dateB = DateTime.tryParse(b['date'] ?? '') ?? DateTime(1900);
        return dateB.compareTo(dateA);
      });
    }

    return result;
  }

  bool _isValidSale(Map<String, dynamic> sale) {
    final price = sale['price'] as double?;
    final title = sale['title'].toString().toLowerCase();
    
    // Price sanity checks
    if (price == null || price <= 0.99 || price > 10000) return false;
    
    // Filter out obvious non-card listings
    if (title.contains('mystery') || 
        title.contains('bulk') ||
        title.contains('lot') ||
        title.contains('pack') ||
        title.contains('box') ||
        title.contains('case')) {
      return false;
    }

    return true;
  }
}
