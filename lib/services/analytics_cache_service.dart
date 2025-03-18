import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tcg_card.dart';
import '../services/logging_service.dart';
import '../models/tcg_set.dart'; // Add import for TcgSet

/// Service for caching analytics data to improve performance and reduce API calls
class AnalyticsCacheService {
  static const String _topMoversKey = 'cached_top_movers';
  static const String _topMoversTimestampKey = 'cached_top_movers_timestamp';
  static const String _marketInsightsKey = 'cached_market_insights';
  static const String _marketInsightsTimestampKey = 'cached_market_insights_timestamp';
  static const String _portfolioChartKey = 'cached_portfolio_chart';
  static const String _portfolioChartTimestampKey = 'cached_portfolio_chart_timestamp';
  
  // Cache expiration durations
  static const Duration _topMoversCacheExpiry = Duration(hours: 3);
  static const Duration _marketInsightsCacheExpiry = Duration(days: 1);
  static const Duration _portfolioChartCacheExpiry = Duration(hours: 12);
  
  // Cache top movers data
  Future<void> cacheTopMovers(List<Map<String, dynamic>> topMovers) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Serialize the data - we need to create a simple representation since we can't store complex objects
      final List<Map<String, dynamic>> serializableMovers = [];
      
      for (final mover in topMovers) {
        final card = mover['card'] as TcgCard;
        
        // Create a simplified version that can be serialized
        serializableMovers.add({
          'cardId': card.id,
          'cardName': card.name,
          'cardSet': card.setName,
          'cardNumber': card.number,
          'cardPrice': card.price,
          'cardImageUrl': card.imageUrl,
          'change': mover['change'],
          'period': mover['period'].toString(),
          'changeAmount': mover['changeAmount'],
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
      
      // Store the timestamp
      await prefs.setString(_topMoversTimestampKey, DateTime.now().toIso8601String());
      
      // Store the serialized data
      await prefs.setString(_topMoversKey, jsonEncode(serializableMovers));
      
      LoggingService.debug('Cached ${topMovers.length} top movers');
    } catch (e) {
      LoggingService.debug('Error caching top movers: $e');
    }
  }
  
  // Add the missing method
  Future<void> clearTopMoversCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_topMoversKey);
      await prefs.remove(_topMoversTimestampKey);
      LoggingService.debug('Cleared top movers cache');
    } catch (e) {
      LoggingService.debug('Error clearing top movers cache: $e');
    }
  }
  
  // Get cached top movers - Fix the async/await pattern
  Future<List<Map<String, dynamic>>?> getTopMovers() async {
    try {
      // Fix: Changed from .sync to await
      final prefs = await SharedPreferences.getInstance();
      
      final timestampStr = prefs.getString(_topMoversTimestampKey);
      if (timestampStr == null) return null;
      
      // Check if cache is expired
      final timestamp = DateTime.parse(timestampStr);
      if (DateTime.now().difference(timestamp) > _topMoversCacheExpiry) {
        LoggingService.debug('Top movers cache expired, returning null');
        return null;
      }
      
      final cachedData = prefs.getString(_topMoversKey);
      if (cachedData == null) return null;
      
      // Parse the cached data
      final List<dynamic> decoded = jsonDecode(cachedData);
      
      LoggingService.debug('Loaded ${decoded.length} top movers from cache');
      
      // Fix: Create dummy TcgSet for card construction
      final dummySet = TcgSet(id: 'cached', name: 'Unknown Set');
      
      // This is placeholder data since we can't fully reconstruct TcgCard objects
      // In a real implementation, you'd use the cardIds to fetch the full cards
      return decoded.map<Map<String, dynamic>>((item) {
        return {
          'card': TcgCard(
            id: item['cardId'],
            name: item['cardName'],
            setName: item['cardSet'],
            number: item['cardNumber'],
            price: item['cardPrice'],
            imageUrl: item['cardImageUrl'],
            set: dummySet, // Add the required set parameter
          ),
          'change': item['change'],
          'period': item['period'],
          'changeAmount': item['changeAmount'],
        };
      }).toList();
    } catch (e) {
      LoggingService.debug('Error loading top movers from cache: $e');
      return null;
    }
  }
  
  // Cache market insights data
  Future<void> cacheMarketInsights(Map<String, dynamic> insights) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Store the timestamp
      await prefs.setString(
        _marketInsightsTimestampKey, 
        DateTime.now().toIso8601String()
      );
      
      // Store the serialized data - simplify the complex objects
      final serializable = _simplifyMarketInsights(insights);
      await prefs.setString(_marketInsightsKey, jsonEncode(serializable));
      
      LoggingService.debug('Cached market insights');
    } catch (e) {
      LoggingService.debug('Error caching market insights: $e');
    }
  }
  
  // Helper to simplify complex market insights for serialization
  Map<String, dynamic> _simplifyMarketInsights(Map<String, dynamic> insights) {
    final result = <String, dynamic>{};
    
    // Process each category (undervalued, overvalued)
    for (final entry in insights.entries) {
      if (entry.value is List) {
        result[entry.key] = (entry.value as List).map((item) {
          // Each item needs to be simplified if it contains card objects
          if (item is Map<String, dynamic> && item.containsKey('id')) {
            return {
              'id': item['id'],
              'name': item['name'],
              'currentPrice': item['currentPrice'],
              'marketPrice': item['marketPrice'],
              'difference': item['difference'],
              'percentDiff': item['percentDiff'],
              'recentSales': item['recentSales'],
              'priceRange': item['priceRange'],
            };
          }
          return item;
        }).toList();
      } else {
        result[entry.key] = entry.value;
      }
    }
    
    return result;
  }
  
  // Get cached market insights - Fix the async/await pattern
  Future<Map<String, dynamic>?> getMarketInsights() async {
    try {
      // Fix: Changed from .sync to await
      final prefs = await SharedPreferences.getInstance();
      
      final timestampStr = prefs.getString(_marketInsightsTimestampKey);
      if (timestampStr == null) return null;
      
      // Check if cache is expired
      final timestamp = DateTime.parse(timestampStr);
      if (DateTime.now().difference(timestamp) > _marketInsightsCacheExpiry) {
        LoggingService.debug('Market insights cache expired, returning null');
        return null;
      }
      
      final cachedData = prefs.getString(_marketInsightsKey);
      if (cachedData == null) return null;
      
      // Parse the cached data
      final Map<String, dynamic> decoded = jsonDecode(cachedData);
      
      LoggingService.debug('Loaded market insights from cache');
      return decoded;
    } catch (e) {
      LoggingService.debug('Error loading market insights from cache: $e');
      return null;
    }
  }
  
  // New methods for portfolio chart caching
  Future<void> cachePortfolioChart(List<(DateTime, double)> chartPoints) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Convert to serializable format
      final serializablePoints = chartPoints.map((point) => {
        'timestamp': point.$1.toIso8601String(),
        'value': point.$2,
      }).toList();
      
      // Store the timestamp and data
      await prefs.setString(_portfolioChartTimestampKey, DateTime.now().toIso8601String());
      await prefs.setString(_portfolioChartKey, jsonEncode(serializablePoints));
      
      LoggingService.debug('Cached portfolio chart data with ${chartPoints.length} points');
    } catch (e) {
      LoggingService.debug('Error caching portfolio chart: $e');
    }
  }
  
  Future<List<(DateTime, double)>?> getPortfolioChart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final timestampStr = prefs.getString(_portfolioChartTimestampKey);
      if (timestampStr == null) return null;
      
      // Check if cache is expired
      final timestamp = DateTime.parse(timestampStr);
      if (DateTime.now().difference(timestamp) > _portfolioChartCacheExpiry) {
        LoggingService.debug('Portfolio chart cache expired, returning null');
        return null;
      }
      
      final cachedData = prefs.getString(_portfolioChartKey);
      if (cachedData == null) return null;
      
      // Parse the cached data
      final List<dynamic> decoded = jsonDecode(cachedData);
      
      // Convert back to typed data
      final chartPoints = decoded.map<(DateTime, double)>((item) {
        final timestamp = DateTime.parse(item['timestamp']);
        final value = (item['value'] as num).toDouble();
        return (timestamp, value);
      }).toList();
      
      LoggingService.debug('Loaded ${chartPoints.length} portfolio chart points from cache');
      return chartPoints;
    } catch (e) {
      LoggingService.debug('Error loading portfolio chart from cache: $e');
      return null;
    }
  }
  
  Future<void> clearPortfolioChartCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_portfolioChartKey);
      await prefs.remove(_portfolioChartTimestampKey);
      LoggingService.debug('Cleared portfolio chart cache');
    } catch (e) {
      LoggingService.debug('Error clearing portfolio chart cache: $e');
    }
  }

  // Clear all analytics caches
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_topMoversKey);
      await prefs.remove(_topMoversTimestampKey);
      await prefs.remove(_marketInsightsKey);
      await prefs.remove(_marketInsightsTimestampKey);
      await prefs.remove(_portfolioChartKey);
      await prefs.remove(_portfolioChartTimestampKey);
      
      LoggingService.debug('Cleared all analytics caches');
    } catch (e) {
      LoggingService.debug('Error clearing analytics caches: $e');
    }
  }

  // Helper method to check if cache is available and valid
  Future<bool> isTopMoversCacheValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final timestampStr = prefs.getString(_topMoversTimestampKey);
      if (timestampStr == null) return false;
      
      // Check if cache is expired
      final timestamp = DateTime.parse(timestampStr);
      if (DateTime.now().difference(timestamp) > _topMoversCacheExpiry) {
        return false;
      }
      
      final cachedData = prefs.getString(_topMoversKey);
      return cachedData != null;
    } catch (e) {
      return false;
    }
  }

  // Similar helper for market insights
  Future<bool> isMarketInsightsCacheValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final timestampStr = prefs.getString(_marketInsightsTimestampKey);
      if (timestampStr == null) return false;
      
      // Check if cache is expired
      final timestamp = DateTime.parse(timestampStr);
      if (DateTime.now().difference(timestamp) > _marketInsightsCacheExpiry) {
        return false;
      }
      
      final cachedData = prefs.getString(_marketInsightsKey);
      return cachedData != null;
    } catch (e) {
      return false;
    }
  }
}
