import 'package:uni_links/uni_links.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final _deepLinkStream = StreamController<String>.broadcast();
  Stream<String> get deepLinks => _deepLinkStream.stream;

  Future<void> initialize() async {
    // Handle links that opened the app
    try {
      final initialLink = await getInitialLink();
      if (initialLink != null) {
        _handleDeepLink(initialLink);
      }
    } on PlatformException {
      // Handle exception
    }

    // Handle links while app is running
    uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        _handleDeepLink(uri.toString());
      }
    }, onError: (err) {
      print('Deep link error: $err');
    });
  }

  void _handleDeepLink(String link) {
    _deepLinkStream.add(link);
  }

  void dispose() {
    _deepLinkStream.close();
  }

  static Future<void> handleDeepLink(String link) async {
    final uri = Uri.parse(link);
    
    switch (uri.path) {
      case '/card':
        final cardId = uri.queryParameters['id'];
        if (cardId != null) {
          // Navigate to card details
        }
        break;
      case '/collection':
        final binderId = uri.queryParameters['binder'];
        if (binderId != null) {
          // Navigate to binder
        }
        break;
      // Add more deep link handlers
    }
  }
}
