class LaunchConfig {
  static const bool enableAnalytics = true;
  static const bool enableCrashReporting = true;
  static const int cacheExpirationDays = 7;
  static const int maxLocalStorageMB = 100;
  
  static const apiConfig = {
    'production': 'https://api.cardwizz.com',
    'staging': 'https://staging.cardwizz.com',
    'timeout': 30000, // milliseconds
  };

  static const features = {
    'enableScanning': true,
    'enableCloudBackup': true,
    'enablePriceAlerts': true,
    'maxCollectionSize': 10000,
    'maxBindersCount': 50,
  };
}
