class AppMetadata {
  static const String appName = 'CardWizz';
  static const String version = '1.0.0';
  static const String buildNumber = '1';
  static const String description = '''
Track your Pokémon card collection with ease. Features:
• Search the comprehensive card database
• Track your collection and wishlist
• Check market prices and trends
• Organize cards in custom binders
• Scan cards to add them quickly
''';
  
  static const Map<String, String> storeMetadata = {
    'android': {
      'package': 'com.cardwizz.app',
      'minSdkVersion': '21',
      'targetSdkVersion': '33',
    },
    'ios': {
      'bundleId': 'com.cardwizz.app',
      'minVersion': '14.0',
    },
  };
}
