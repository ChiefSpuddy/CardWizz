import 'dart:io';

// For a tool script, we'll keep print statements since this isn't production code running in the app
void main() async {
  // Directory to scan
  final directory = Directory('/Users/sam.may/CardWizz/lib');
  
  // Maps to track imports
  final importCounts = <String, int>{};
  final filesByImport = <String, Set<String>>{};
  
  await for (final entity in directory.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final content = await entity.readAsString();
      final lines = content.split('\n');
      
      for (final line in lines) {
        if (line.trim().startsWith('import ')) {
          final import = line.trim();
          importCounts[import] = (importCounts[import] ?? 0) + 1;
          
          filesByImport[import] ??= <String>{};
          filesByImport[import]!.add(entity.path);
        }
      }
    }
  }
  
  print('=== Import Analysis ===');
  
  // Sort imports by frequency
  final sortedImports = importCounts.entries.toList()
    ..sort((a, b) => a.value.compareTo(b.value));
  
  // Print rarely used imports
  print('\n=== Potentially Unused/Rarely Used Imports ===');
  for (final entry in sortedImports) {
    if (entry.value < 3) {  // Threshold for "rarely used"
      print('${entry.key} (used in ${entry.value} files):');
      for (final file in filesByImport[entry.key]!) {
        print('  - ${file.replaceFirst('/Users/sam.may/CardWizz/lib/', '')}');
      }
      print('');
    }
  }
}
