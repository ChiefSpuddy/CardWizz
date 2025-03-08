import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

/// Generate a simple CardWizz logo and save it to the app's documents directory
Future<String> generateLogoAndSave() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  
  // Logo size
  const size = Size(400, 400);
  
  // Background
  final bgPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.fill;
  canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);
  
  // Card shadow
  final shadowPaint = Paint()
    ..color = Colors.black.withOpacity(0.3)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
  canvas.drawRoundRect(
    Rect.fromLTWH(80, 80, 240, 320),
    20, 20, 
    shadowPaint
  );
  
  // Card
  final cardPaint = Paint()
    ..color = const Color(0xFF4A8FE7)
    ..style = PaintingStyle.fill;
  canvas.drawRoundRect(
    Rect.fromLTWH(70, 70, 240, 320), 
    20, 20, 
    cardPaint
  );
  
  // Card border
  final borderPaint = Paint()
    ..color = const Color(0xFF2C6BC8)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 8;
  canvas.drawRoundRect(
    Rect.fromLTWH(70, 70, 240, 320),
    20, 20, 
    borderPaint
  );
  
  // Card inner details
  final textPaint = Paint()
    ..color = Colors.white.withOpacity(0.8)
    ..style = PaintingStyle.fill;
  
  // Title bar
  canvas.drawRoundRect(
    Rect.fromLTWH(95, 100, 190, 40),
    10, 10, 
    textPaint
  );
  
  // Text lines
  canvas.drawRoundRect(
    Rect.fromLTWH(95, 160, 190, 15),
    5, 5, 
    textPaint
  );
  canvas.drawRoundRect(
    Rect.fromLTWH(95, 190, 190, 15),
    5, 5, 
    textPaint
  );
  canvas.drawRoundRect(
    Rect.fromLTWH(95, 220, 150, 15),
    5, 5, 
    textPaint
  );
  
  // Card icon
  final iconPaint = Paint()
    ..color = const Color(0xFF2C6BC8)
    ..style = PaintingStyle.fill;
  canvas.drawCircle(
    Offset(size.width / 2, 300),
    40, 
    iconPaint
  );
  
  // Icon border
  final iconBorderPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = 5;
  canvas.drawCircle(
    Offset(size.width / 2, 300),
    40, 
    iconBorderPaint
  );
  
  // Letter "W" in the center
  final textStyle = TextStyle(
    color: Colors.white,
    fontSize: 48, 
    fontWeight: FontWeight.bold
  );
  final textSpan = TextSpan(text: 'W', style: textStyle);
  final textPainter = TextPainter(
    text: textSpan,
    textDirection: TextDirection.ltr,
  )..layout();
  
  textPainter.paint(
    canvas, 
    Offset(
      size.width / 2 - textPainter.width / 2, 
      280 - textPainter.height / 2
    )
  );
  
  // End recording and convert to image
  final picture = recorder.endRecording();
  final image = await picture.toImage(size.width.toInt(), size.height.toInt());
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  final buffer = byteData!.buffer.asUint8List();
  
  // Save the image
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/cardwizz_logo.png');
  await file.writeAsBytes(buffer);
  
  return file.path;
}
