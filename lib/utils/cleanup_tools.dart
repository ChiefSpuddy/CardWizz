import 'dart:io';
import '../services/logging_service.dart';

/// A utility class with static methods to help clean up the codebase.
class CleanupTools {
  /// Replaces all print statements with LoggingService calls
  static Future<void> replacePrintsWithLogging(String directoryPath) async {
    final directory = Directory(directoryPath);
    if (!await directory.exists()) {
      LoggingService.warning('Directory does not exist: $directoryPath', tag: 'Cleanup');
      return;
    }
    
    int fileCount = 0;
    int replacementCount = 0;
    
    await for (final entity in directory.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        final content = await entity.readAsString();
        
        // Skip files that already import the logging service
        if (content.contains("import '../services/logging_service.dart'") || 
            content.contains("import 'package:cardwizz/services/logging_service.dart'")) {
          continue;
        }
        
        // Find all print statements
        final printRegex = RegExp(r'print\((.*?)\);', multiLine: true);
        final matches = printRegex.allMatches(content);
        
        if (matches.isNotEmpty) {
          fileCount++;
          replacementCount += matches.length;
          
          // Add import statement
          var updatedContent = "import '../services/logging_service.dart';\n$content";
          
          // Replace print statements
          updatedContent = updatedContent.replaceAllMapped(
            printRegex,
            (match) {
              final argument = match.group(1);
              return 'LoggingService.debug($argument);';
            }
          );
          
          // Write the updated content back to the file
          await entity.writeAsString(updatedContent);
        }
      }
    }
    
    LoggingService.info('Replaced $replacementCount print statements in $fileCount files', tag: 'Cleanup');
  }
  
  /// Removes unused imports based on a list
  static Future<void> removeUnusedImports(String directoryPath, List<String> unusedImports) async {
    final directory = Directory(directoryPath);
    if (!await directory.exists()) {
      LoggingService.warning('Directory does not exist: $directoryPath', tag: 'Cleanup');
      return;
    }
    
    int fileCount = 0;
    int removalCount = 0;
    
    await for (final entity in directory.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        var content = await entity.readAsString();
        final lines = content.split('\n');
        final newLines = <String>[];
        bool modified = false;
        
        for (final line in lines) {
          final trimmed = line.trim();
          bool shouldKeep = true;
          
          for (final unusedImport in unusedImports) {
            if (trimmed.startsWith('import') && trimmed.contains(unusedImport)) {
              shouldKeep = false;
              removalCount++;
              modified = true;
              break;
            }
          }
          
          if (shouldKeep) {
            newLines.add(line);
          }
        }
        
        if (modified) {
          fileCount++;
          await entity.writeAsString(newLines.join('\n'));
        }
      }
    }
    
    LoggingService.info('Removed $removalCount unused imports from $fileCount files', tag: 'Cleanup');
  }
}
