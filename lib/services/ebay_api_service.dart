import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

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
    
    final response = await http.get(
      Uri.https(_baseUrl, '/buy/browse/v1/item_summary/search', {
        'q': query,
        'filter': 'buyingOptions:{FIXED_PRICE}',
        'sort': '-price',
        'limit': '100', // Increased to get more results
      }),
      headers: {
        'Authorization': 'Bearer $token',
        'X-EBAY-C-MARKETPLACE-ID': 'EBAY_US',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['itemSummaries'] == null) return [];
      
      final results = (data['itemSummaries'] as List)
          .where((item) {
            final title = (item['title'] as String).toLowerCase();
            // Less aggressive filtering
            return !_isGradedCard(title) && 
                   !title.contains('lot') &&
                   !title.contains('bulk') &&
                   item['price'] != null;
          })
          .map((item) => {
            'title': item['title'],
            'price': item['price']['value'],
            'currency': item['price']['currency'],
            'condition': item['condition'],
            'link': item['itemWebUrl'],
            'imageUrl': item['image']?['imageUrl'],
            'soldDate': item['soldDate'],
          })
          .toList();

      return results;
    } else {
      print('eBay API error: ${response.statusCode} - ${response.body}');
      return [];
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

  Future<Map<String, dynamic>> getMarketInsights(List<String> cardNames) async {
    int totalListings = 0;
    double averagePrice = 0;
    int processedCards = 0;
    final priceRanges = <String, int>{
      'under_5': 0,
      '5_to_20': 0,
      '20_to_50': 0,
      '50_to_100': 0,
      'over_100': 0,
    };

    for (final name in cardNames) {
      try {
        final results = await getRecentSales(name);
        if (results.isNotEmpty) {
          final prices = results
              .map((r) => double.tryParse(r['price'].toString()) ?? 0)
              .where((p) => p > 0)
              .toList();

          if (prices.isNotEmpty) {
            totalListings += prices.length;
            averagePrice += prices.reduce((a, b) => a + b) / prices.length;
            processedCards++;

            for (final price in prices) {
              if (price < 5) priceRanges['under_5'] = (priceRanges['under_5'] ?? 0) + 1;
              else if (price < 20) priceRanges['5_to_20'] = (priceRanges['5_to_20'] ?? 0) + 1;
              else if (price < 50) priceRanges['20_to_50'] = (priceRanges['20_to_50'] ?? 0) + 1;
              else if (price < 100) priceRanges['50_to_100'] = (priceRanges['50_to_100'] ?? 0) + 1;
              else priceRanges['over_100'] = (priceRanges['over_100'] ?? 0) + 1;
            }
          }
        }
      } catch (e) {
        print('Error getting market insights for $name: $e');
      }
    }

    return {
      'totalListings': totalListings,
      'averagePrice': processedCards > 0 ? averagePrice / processedCards : 0,
      'priceRanges': priceRanges,
      'processedCards': processedCards,
    };
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
