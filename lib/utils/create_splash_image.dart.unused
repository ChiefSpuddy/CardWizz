import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Utility function to generate and save a splash logo if it doesn't exist
Future<void> createSplashLogoIfNeeded() async {
  try {
    // Get the app's temporary directory instead of using an absolute path
    final tempDir = await getTemporaryDirectory();
    final splashDir = Directory('${tempDir.path}/splash');
    
    // Create the directory if it doesn't exist
    if (!await splashDir.exists()) {
      await splashDir.create(recursive: true);
    }
    
    final File splashLogo = File('${splashDir.path}/splash_logo.png');
    
    // Check if splash logo already exists
    if (await splashLogo.exists()) {
      print('Splash logo already exists at ${splashLogo.path}');
      return;
    }
    
    // Generate a simple logo - try to get an asset from the bundle
    try {
      // Try to load cardback.png from the asset bundle
      final ByteData data = await rootBundle.load('assets/images/cardback.png');
      final Uint8List bytes = data.buffer.asUint8List();
      await splashLogo.writeAsBytes(bytes);
      print('Generated splash logo at ${splashLogo.path}');
    } catch (e) {
      print('Error loading splash image from assets: $e');
      
      // As a fallback, create a very simple image with Flutter
      // We'll skip this for now as it requires more complex logic
      print('Could not create splash logo: $e');
    }
  } catch (e) {
    // Just log the error but don't rethrow - allow app to continue
    print('Error in createSplashLogoIfNeeded: $e');
  }
}
