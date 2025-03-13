import 'dart:io';
import '../lib/utils/cleanup_tools.dart';

Future<void> main() async {
  // 1. Replace print statements with LoggingService
  await CleanupTools.replacePrintsWithLogging('/Users/sam.may/CardWizz/lib');
  
  // 2. Define commonly unused imports to remove
  final unusedImports = [
    'package:lottie/lottie.dart',
    '../constants/app_colors.dart',
    '../models/tcg_card.dart', // Only remove from files where it's unused
    'dart:math', // Only remove from files where it's unused
    'package:flutter/foundation.dart', // Only if unnecessary
  ];
  
  // 3. Remove unused imports
  await CleanupTools.removeUnusedImports('/Users/sam.may/CardWizz/lib', unusedImports);
  
  print('Cleanup completed successfully!');
}
