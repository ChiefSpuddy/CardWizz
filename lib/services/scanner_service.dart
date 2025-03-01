import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';  // Add this import
import '../services/tcg_api_service.dart';  // Add this import
import '../models/tcg_card.dart';  // Add this import

class ScannerService {
  final textRecognizer = TextRecognizer();
  final _apiService = TcgApiService();

  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<String> recognizeText(String imagePath) async {
    final inputImage = InputImage.fromFile(File(imagePath));
    final recognizedText = await textRecognizer.processImage(inputImage);
    return recognizedText.text;
  }

  Future<Map<String, String?>> extractCardInfo(String text) async {
    print('Raw text from image: $text');
    
    final lines = text.split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    String? number;
    String? name;
    
    // Look for card name first with more lenient matching
    for (var line in lines) {
      // Clean line of special characters and normalize spaces
      final cleanLine = line
          .replaceAll(RegExp(r'[^A-Za-z\s-]'), '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
          
      // Skip short lines and common non-name text
      if (cleanLine.length < 3 || _isCommonText(cleanLine)) {
        continue;
      }
      
      name = cleanLine;
      print('Found potential name: $name');
      break;
    }

    // Look for card number with better pattern matching
    for (var line in lines.reversed) {
      // Try exact number pattern first (e.g. "006/091")
      var match = RegExp(r'(?:^|\D)0*(\d{1,3})/\d+(?:$|\D)').firstMatch(line);
      if (match != null) {
        number = match.group(1)!.padLeft(3, '0');
        print('Found number pattern: $number');
        break;
      }

      // Fallback to looking for isolated numbers
      match = RegExp(r'(?:^|\D)0*(\d{1,3})(?:$|\D)').firstMatch(line);
      if (match != null) {
        number = match.group(1)!.padLeft(3, '0');
        print('Found isolated number: $number');
        break;
      }
    }

    return {
      'number': number,
      'name': name,
    };
  }

  bool _isCommonText(String text) {
    final commonWords = {
      'BASIC', 'ENERGY', 'TRAINER', 'ITEM', 'BASIG',
      'RESISTANCE', 'WEAKNESS', 'RETREAT', 'POKEMON',
      'HP', 'STAGE', 'EVOLVES', 'FROM', 'SET',
    };
    return commonWords.contains(text.toUpperCase());
  }

  Future<List<TcgCard>> _searchByName(String name) async {
    try {
      final nameQuery = 'name:"$name"';
      final results = await _apiService.searchCards(
        query: nameQuery,
        pageSize: 5
      );
      
      final List<dynamic> cardData = results['data'] as List? ?? [];
      return cardData
          .map((card) => TcgCard.fromJson(card as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error searching by name: $e');
      return [];
    }
  }

  Future<List<TcgCard>> _searchByNumber(String number, String setCode) async {
    try {
      final numberQuery = 'number:"$number" set.id:"$setCode"';
      final results = await _apiService.searchCards(
        query: numberQuery,
        pageSize: 5
      );
      
      final List<dynamic> cardData = results['data'] as List? ?? [];
      return cardData
          .map((card) => TcgCard.fromJson(card as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error searching by number: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> searchCard(String? number, String? name) async {
    try {
      // Try name search first for better accuracy
      if (name != null) {
        // Remove 'BASIG' from name if present
        final cleanName = name.replaceAll('BASIG', '').trim();
        final nameQuery = 'name:"$cleanName"'; // Fixed quotes
        print('Trying name search: $nameQuery');

        final results = await _apiService.searchCards(
          query: 'name:"$cleanName"',
          pageSize: 5
        );
        if (results['data'] != null && (results['data'] as List).isNotEmpty) {
          final card = results['data'][0];
          print('Found by name: ${card['name']} #${card['number']}');
          return card;
        }
      }

      // Then try number search as fallback
      if (number != null) {
        // Try with both padded and unpadded numbers
        final numberQuery = 'number:"$number"'; // Fixed quotes
        print('Trying number search: $numberQuery');

        final results = await _apiService.searchCards(
          query: 'number:"$number"',
          pageSize: 5
        );
        if (results['data'] != null && (results['data'] as List).isNotEmpty) {
          final card = results['data'][0];
          print('Found by number: ${card['name']} #${card['number']}');
          return card;
        }
      }
    } catch (e) {
      print('Error searching for card: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> processCapturedImage(String imagePath) async {
    try {
      final rawText = await recognizeText(imagePath);
      print('Raw text from image:\n$rawText');
      
      String? number;
      String? name;
      String? setNumber;

      // Clean up the text and split into lines
      final lines = rawText.split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();
      
      // Look for card name first
      for (var line in lines.take(5)) {
        var cleanLine = line
            .replaceAll(RegExp(r'[^A-Za-z\s-]'), '')
            .replaceAll(RegExp(r'(BASIG|AS|AIS|ASIS)'), '')  // Remove common OCR artifacts
            .trim();
            
        if (cleanLine.length > 2 && !_isCommonText(cleanLine)) {
          name = cleanLine.trim();  // Ensure clean trimming
          print('Found name: $name');
          break;
        }
      }

      // Look for card number
      for (var line in lines.reversed) {
        final fullMatch = RegExp(r'(\d{1,3})/(\d{1,3})').firstMatch(line);
        if (fullMatch != null) {
          number = fullMatch.group(1)!;
          setNumber = fullMatch.group(2);
          print('Found number: $number/$setNumber');
          break;
        }
      }

      if (name != null || number != null) {
        // Try exact number search first as it's most reliable
        if (number != null) {
          print('Trying number search: number:"$number"');
          final results = await _apiService.searchCards(
            query: 'number:"$number"',
            pageSize: 5,
          );
          if (results['data'] != null && (results['data'] as List).isNotEmpty) {
            return (results['data'] as List).first;
          }
        }

        // Try name search if number search failed
        if (name != null) {
          // Clean name for better matching
          final cleanName = name.replaceAll('Pokémon', '').trim();
          print('Trying name search: name:"$cleanName"');
          final results = await _apiService.searchCards(
            query: 'name:"$cleanName"',
            pageSize: 5,
          );
          if (results['data'] != null && (results['data'] as List).isNotEmpty) {
            return (results['data'] as List).first;
          }
        }
      }
      
      return null;
    } catch (e) {
      print('Error processing card: $e');
      return null;
    }
  }

  void dispose() {
    textRecognizer.close();
  }
}
