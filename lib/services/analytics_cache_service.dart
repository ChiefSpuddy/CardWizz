import 'package:flutter/foundation.dart';
import '../models/tcg_card.dart';

/// Service for caching analytics data to prevent rebuilding data
/// unnecessarily and maintain consistency across the app.
class AnalyticsCacheService {
  // Singleton pattern
  static final AnalyticsCacheService _instance = AnalyticsCacheService._internal();
  factory AnalyticsCacheService() => _instance;
  AnalyticsCacheService._internal();

  // Cache for top movers data
  List<Map<String, dynamic>>? _topMoversCache;
  DateTime? _topMoversCacheTime;
  static const Duration _topMoversCacheDuration = Duration(minutes: 10);

  // Cache for market insights data
  Map<String, dynamic>? _marketInsightsCache;
  DateTime? _marketInsightsCacheTime;
  static const Duration _marketInsightsCacheDuration = Duration(hours: 1);

  // Cache for portfolio analysis data
  Map<String, dynamic>? _portfolioAnalysisCache;
  DateTime? _portfolioAnalysisCacheTime;
  static const Duration _portfolioAnalysisCacheDuration = Duration(minutes: 30);

  // Methods for top movers
  List<Map<String, dynamic>>? getTopMovers() {
    if (_topMoversCache == null) return null;
    
    // Check if cache has expired
    if (_topMoversCacheTime != null && 
        DateTime.now().difference(_topMoversCacheTime!) > _topMoversCacheDuration) {
      _topMoversCache = null;
      return null;
    }
    
    return _topMoversCache;
  }
  
  void cacheTopMovers(List<Map<String, dynamic>> movers) {
    _topMoversCache = movers;
    _topMoversCacheTime = DateTime.now();
  }
  
  void clearTopMoversCache() {
    _topMoversCache = null;
    _topMoversCacheTime = null;
  }

  // Methods for market insights
  Map<String, dynamic>? getMarketInsights() {
    if (_marketInsightsCache == null) return null;
    
    // Check if cache has expired
    if (_marketInsightsCacheTime != null && 
        DateTime.now().difference(_marketInsightsCacheTime!) > _marketInsightsCacheDuration) {
      _marketInsightsCache = null;
      return null;
    }
    
    return _marketInsightsCache;
  }
  
  // Update to handle the opportunities format we're using
  void cacheMarketInsights(Map<String, List<Map<String, dynamic>>> insights) {
    _marketInsightsCache = insights;
    _marketInsightsCacheTime = DateTime.now();
  }
  
  // Add the missing method for clearing market insights cache
  void clearMarketInsightsCache() {
    _marketInsightsCache = null;
    _marketInsightsCacheTime = null;
  }

  // Methods for portfolio analysis
  Map<String, dynamic>? getPortfolioAnalysis() {
    if (_portfolioAnalysisCache == null) return null;
    
    // Check if cache has expired
    if (_portfolioAnalysisCacheTime != null && 
        DateTime.now().difference(_portfolioAnalysisCacheTime!) > _portfolioAnalysisCacheDuration) {
      _portfolioAnalysisCache = null;
      return null;
    }
    
    return _portfolioAnalysisCache;
  }
  
  void cachePortfolioAnalysis(Map<String, dynamic> analysis) {
    _portfolioAnalysisCache = analysis;
    _portfolioAnalysisCacheTime = DateTime.now();
  }
  
  void clearPortfolioAnalysisCache() {
    _portfolioAnalysisCache = null;
    _portfolioAnalysisCacheTime = null;
  }
  
  // Clear all caches
  void clearAllCaches() {
    clearTopMoversCache();
    clearMarketInsightsCache();
    clearPortfolioAnalysisCache();
  }
}
