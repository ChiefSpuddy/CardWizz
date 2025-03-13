import '../services/logging_service.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Create a custom card back to replace copyrighted images
Future<Uint8List> createCardBack() async {
  // Create a picture recorder
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final size = const Size(300, 420);
  
  // Background
  final bgPaint = Paint()..color = const Color(0xFF2962FF);
  canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);
  
  // Card pattern
  final patternPaint = Paint()
    ..color = const Color(0xFF1565C0)
    ..style = PaintingStyle.fill;
  
  // Draw some diagonal stripes
  for (int i = -300; i < 300; i += 40) {
    canvas.drawRect(
      Rect.fromLTWH(i.toDouble(), 0, 20, size.height),
      patternPaint,
    );
  }
  
  // Border
  final borderPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = 12;
  canvas.drawRect(
    Rect.fromLTWH(15, 15, size.width - 30, size.height - 30),
    borderPaint,
  );
  
  // Center circle
  final circlePaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = 8;
  canvas.drawCircle(
    Offset(size.width / 2, size.height / 2),
    80,
    circlePaint,
  );
  
  // Fill circle
  final circleFillPaint = Paint()
    ..color = const Color(0xFF1565C0)
    ..style = PaintingStyle.fill;
  canvas.drawCircle(
    Offset(size.width / 2, size.height / 2),
    76,
    circleFillPaint,
  );
  
  // Text
  final textStyle = TextStyle(
    color: Colors.white,
    fontSize: 28,
    fontWeight: FontWeight.bold,
  );
  final textSpan = TextSpan(
    text: 'CW',
    style: textStyle,
  );
  final textPainter = TextPainter(
    text: textSpan,
    textDirection: TextDirection.ltr,
  );
  textPainter.layout();
  textPainter.paint(
    canvas,
    Offset(
      size.width / 2 - textPainter.width / 2,
      size.height / 2 - textPainter.height / 2,
    ),
  );
  
  // Finalize the image
  final picture = recorder.endRecording();
  final img = await picture.toImage(size.width.toInt(), size.height.toInt());
  final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
  
  return byteData!.buffer.asUint8List();
}

/// Replaces all pokemon card back images with our custom one
Future<void> replacePokemonCardBacks() async {
  try {
    // Generate our custom card back
    final bytes = await createCardBack();
    
    // Define all file paths that might contain pokemon images
    final pathsToReplace = [
      '/Users/sam.may/CardWizz/assets/images/cardback.png',
      '/Users/sam.may/CardWizz/assets/images/mtgback.png',
      '/Users/sam.may/CardWizz/assets/images/pokeback.png',
      '/Users/sam.may/CardWizz/assets/images/back.png',
    ];
    
    // Replace each file
    for (final path in pathsToReplace) {
      try {
        final file = File(path);
        if (await file.exists()) {
          LoggingService.debug('Replacing card back at $path');
          await file.writeAsBytes(bytes);
        }
      } catch (e) {
        LoggingService.debug('Error replacing file at $path: $e');
      }
    }
    
    LoggingService.debug('Successfully replaced all pokemon card back images');
  } catch (e) {
    LoggingService.debug('Error in replacePokemonCardBacks: $e');
  }
}
