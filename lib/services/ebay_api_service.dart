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

  Future<List<Map<String, dynamic>>> getRecentSales(String cardName, {
    String? setName,
    String? number,  // Add card number parameter
  }) async {
    final token = await _getAccessToken();
    
    // Build search query with card number
    String baseQuery = '$cardName pokemon card';
    if (number != null) {
      baseQuery += ' $number';  // Add card number to search
    }
    
    // Build filters
    const excludedTerms = '-psa -bgs -cgc -ace -graded -sgc -case -slab';
    
    // Try first with set name if provided
    List<Map<String, dynamic>> results = [];
    if (setName != null) {
      results = await _searchWithQuery('$baseQuery $setName $excludedTerms');
    }
    
    // If no results or no set name, try without set name
    if (results.isEmpty) {
      results = await _searchWithQuery('$baseQuery $excludedTerms');
    }
    
    return results;
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

  double? _extractPrice(Map<String, dynamic>? priceInfo) {
    if (priceInfo == null) return null;
    
    try {
      final value = priceInfo['value'];
      if (value == null) return null;
      
      // Handle different numeric formats
      if (value is num) {
        return value.toDouble();
      } else if (value is String) {
        return double.tryParse(value);
      }
      
      return null;
    } catch (e) {
      print('Error extracting price: $e');
      return null;
    }
  }

  bool _isGradedCard(String title) {
    final gradingTerms = [
      'psa', 'bgs', 'cgc', 'ace', 'graded', 'sgc',
      'gem mint', 'pristine', 'grade'
    ];
    return gradingTerms.any((term) => title.contains(term));
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

    for (final card in cards) {
      try {
        print('Analyzing market for: ${card.name} (${card.setName ?? 'Unknown Set'})');
        final currentPrice = (card.price ?? 0).toDouble();
        
        // Skip cards with no price
        if (currentPrice == 0) {
          print('Skipping ${card.name} - No current price');
          continue;
        }

        final results = await getRecentSales(
          card.name,
          setName: card.setName,
          number: card.number,
        );

        // Debug the results
        print('Found ${results.length} listings for ${card.name}');

        if (results.length >= 3) { // Require at least 3 listings for comparison
          // Extract and validate prices
          final prices = results
              .map((r) => r['price'])
              .whereType<num>()
              .map((p) => p.toDouble())
              .where((p) => p > 0)
              .toList();

          if (prices.length >= 3) { // Also require at least 3 valid prices
            prices.sort();

            // Calculate median instead of average for more stability
            final medianPrice = prices[prices.length ~/ 2];
            final priceDiff = medianPrice - currentPrice;
            final percentDiff = (priceDiff / currentPrice) * 100;

            print('Analysis for ${card.name}:');
            print('- Current price: \$${currentPrice.toStringAsFixed(2)}');
            print('- Market price: \$${medianPrice.toStringAsFixed(2)}');
            print('- Difference: ${priceDiff.toStringAsFixed(2)}');
            print('- Percent diff: ${percentDiff.toStringAsFixed(1)}%');

            // Adjust thresholds for opportunities
            if (percentDiff.abs() >= 20) { // Increase threshold to 20%
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

              // Changed logic - undervalued when market price is higher
              if (medianPrice > currentPrice * 1.2) { // 20% higher
                print('Adding ${card.name} to undervalued opportunities');
                opportunities['undervalued']!.add(insight);
              } else if (medianPrice < currentPrice * 0.8) { // 20% lower
                print('Adding ${card.name} to overvalued opportunities');
                opportunities['overvalued']!.add(insight);
              }
            }
          }
        }

        // Add delay to avoid rate limiting
        await Future.delayed(const Duration(milliseconds: 500));

      } catch (e) {
        print('Error analyzing market for ${card.name}: $e');
        continue;
      }
    }

    // Sort by potential profit/savings
    for (final category in opportunities.keys) {
      opportunities[category]!.sort((a, b) {
        // Fix type casting by doing it separately
        final aMarket = (a['marketPrice'] as num).toDouble();
        final aCurrent = (a['currentPrice'] as num).toDouble();
        final bMarket = (b['marketPrice'] as num).toDouble();
        final bCurrent = (b['currentPrice'] as num).toDouble();
        
        // Calculate differences
        final aDiff = (aMarket - aCurrent).abs();
        final bDiff = (bMarket - bCurrent).abs();
        
        return bDiff.compareTo(aDiff);
      });
    }

    print('Analysis complete:');
    print('- Undervalued cards: ${opportunities['undervalued']!.length}');
    print('- Overvalued cards: ${opportunities['overvalued']!.length}');

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
}
