import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/logging_service.dart';

/// Service for tracking and optimizing app performance
class PerformanceService {
  static PerformanceService? _instance;
  
  static PerformanceService get instance {
    _instance ??= PerformanceService._();
    return _instance!;
  }
  
  PerformanceService._();
  
  // Performance metrics
  final Map<String, List<int>> _metrics = {};
  
  // Last cold start time
  DateTime? _appColdStartTime;
  
  /// Initialize performance monitoring
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final lastRunTime = prefs.getInt('last_run_timestamp');
    final now = DateTime.now().millisecondsSinceEpoch;
    
    // Store current run time
    await prefs.setInt('last_run_timestamp', now);
    
    // Track if this is a cold or warm start
    final instance = PerformanceService.instance;
    instance._appColdStartTime = DateTime.now();
    
    // If last run was > 30 minutes ago, this is a cold start
    final isColdStart = lastRunTime == null || (now - lastRunTime) > 30 * 60 * 1000;
    
    if (kDebugMode) {
      developer.log('App ${isColdStart ? "cold" : "warm"} start detected');
    }
    
    // Start a trace for the app start type
    instance.startTrace(isColdStart ? 'cold_start' : 'warm_start');
  }
  
  /// Start a performance trace
  void startTrace(String name) {
    try {
      if (kDebugMode) {
        developer.log('Started trace: $name');
      }
    } catch (e) {
      LoggingService.debug('Error starting trace $name: $e');
    }
  }
  
  /// Stop a performance trace
  void stopTrace(String name) {
    try {
      if (kDebugMode) {
        developer.log('Stopped trace: $name');
      }
    } catch (e) {
      LoggingService.debug('Error stopping trace $name: $e');
    }
  }
  
  /// Track a specific metric
  void trackMetric(String name, int value) {
    if (!_metrics.containsKey(name)) {
      _metrics[name] = [];
    }
    _metrics[name]!.add(value);
    
    if (kDebugMode && _metrics[name]!.length % 10 == 0) {
      final avg = _metrics[name]!.reduce((a, b) => a + b) / _metrics[name]!.length;
      developer.log('Average $name: ${avg.toStringAsFixed(2)}ms (${_metrics[name]!.length} samples)');
    }
  }
  
  /// Track screen render time
  void trackScreenRender(BuildContext context, String screenName) {
    final stopwatch = Stopwatch()..start();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final renderTime = stopwatch.elapsedMilliseconds;
      trackMetric('${screenName}_render', renderTime);
      
      if (kDebugMode) {
        developer.log('Rendered $screenName in ${renderTime}ms');
      }
    });
  }
  
  /// Track how long it takes to load data
  Future<T> trackDataLoad<T>(Future<T> future, String operation) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = await future;
      final loadTime = stopwatch.elapsedMilliseconds;
      trackMetric('${operation}_load', loadTime);
      return result;
    } catch (e) {
      stopwatch.stop();
      trackMetric('${operation}_error', stopwatch.elapsedMilliseconds);
      rethrow;
    }
  }
  
  /// Get app startup duration
  Duration? getAppStartupDuration() {
    if (_appColdStartTime != null) {
      return DateTime.now().difference(_appColdStartTime!);
    }
    return null;
  }
}
