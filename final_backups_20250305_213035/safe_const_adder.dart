import 'dart:io';

void main() async {
  final projectPath = Directory.current.path;
  print('CardWizz Safe Const Constructor Adder');
  print('================================\n');
  
  // Common widgets that can typically be constant if they don't contain dynamic content
  final constCandidates = [
    'Text(',
    'Icon(',
    'SizedBox(',
    'Padding(',
    'Container(',
    'Row(',
    'Column(',
    'Card(',
    'Divider(',
    'CircleAvatar(',
  ];
  
  // Patterns that indicate a widget cannot be const
  final nonConstPatterns = [
    'Theme.of(',
    'MediaQuery.of(',
    'Navigator.',
    'Provider.of(',
    'widget.',
    '.shade',
    '${',
    '.toStringAsFixed',
    '.toString(',
    '_', // Variables typically start with _
    '!.', // Null assertion
    '?.', // Null-aware access
    'context.watch',
    'context.read',
    'setState(',
  ];
  
  int filesProcessed = 0;
  int totalConstAdded = 0;
  
  print('Scanning Dart files to safely add const constructors...');
  
  await for (final entity in Directory('$projectPath/lib').list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      filesProcessed++;
      final content = await entity.readAsString();
      final lines = content.split('\n');
      bool modified = false;
      
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        
        // Skip lines that already have const
        if (line.startsWith('const ') || line.contains(' const ')) {
          continue;
        }
        
        // Check for any of our widget candidates
        for (final candidate in constCandidates) {
          if (line.startsWith(candidate) || (line.contains(' $candidate') && !line.contains('//'))) {
            // Check if line contains any patterns that would make it non-constant
            bool canBeConst = true;
            for (final pattern in nonConstPatterns) {
              if (line.contains(pattern)) {
                canBeConst = false;
                break;
              }
            }
            
            // Check additional 3 lines ahead for patterns that would make it non-constant
            // (for multi-line widget declarations)
            if (canBeConst && i + 3 < lines.length) {
              for (int j = i + 1; j <= i + 3 && j < lines.length; j++) {
                for (final pattern in nonConstPatterns) {
                  if (lines[j].contains(pattern)) {
                    canBeConst = false;
                    break;
                  }
                }
                if (!canBeConst) break;
              }
            }
            
            if (canBeConst) {
              // Get the indentation of the current line
              final originalLine = lines[i];
              final leadingSpaces = originalLine.length - originalLine.trimLeft().length;
              final indent = ' ' * leadingSpaces;
              
              // Add const to the beginning with the same indentation
              lines[i] = '$indent' + 'const ' + originalLine.trimLeft();
              modified = true;
              totalConstAdded++;
              break;
            }
          }
        }
      }
      
      // Save changes if any were made
      if (modified) {
        final newContent = lines.join('\n');
        await entity.writeAsString(newContent);
        print('✅ Added const constructors to: ${entity.path.replaceFirst(projectPath, '')}');
      }
    }
  }
  
  print('\nProcess completed:');
  print('- Files processed: $filesProcessed');
  print('- Const constructors safely added: $totalConstAdded');
  
  if (totalConstAdded > 0) {
    print('\nThe tool attempted to only add const where it\'s safe to do so.');
    print('Please test your app to ensure no new compilation errors were introduced.');
  } else {
    print('\nNo safe const additions were identified.');
  }
}
