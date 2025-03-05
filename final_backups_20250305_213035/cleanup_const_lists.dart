import 'dart:io';

void main() async {
  final projectPath = Directory.current.path;
  print('CardWizz Const List Cleanup');
  print('=========================\n');
  
  final mainDartPath = '$projectPath/lib/main.dart';
  final mainDartFile = File(mainDartPath);
  
  if (!await mainDartFile.exists()) {
    print('❌ main.dart not found');
    return;
  }
  
  // Create backup
  final backupPath = '$projectPath/lib/main.dart.backup3';
  await mainDartFile.copy(backupPath);
  print('✅ Created backup at $backupPath');
  
  final content = await mainDartFile.readAsString();
  
  // Pattern for potentially problematic const lists with delegates or similar patterns
  final patterns = [
    RegExp(r'const\s*\[\s*AppLocalizationsDelegate\(\s*\)'),
    RegExp(r'const\s*\[\s*.*?Delegate\(\)'),
    RegExp(r'const\s*\[\s*.*?\.delegate'),
    RegExp(r'localizationsDelegates:\s*const\s*\['),
    RegExp(r'delegates:\s*const\s*\['),
  ];
  
  String modifiedContent = content;
  int replacements = 0;
  
  for (final pattern in patterns) {
    final matches = pattern.allMatches(content);
    for (final match in matches) {
      final matchedText = match.group(0)!;
      final replacementText = matchedText.replaceFirst('const', '');
      modifiedContent = modifiedContent.replaceAll(matchedText, replacementText);
      replacements++;
    }
  }
  
  // Special handling for specific patterns if needed
  if (modifiedContent.contains('localizationsDelegates: [')) {
    print('✓ Found and fixed localizationsDelegates list');
  }
  
  if (replacements > 0) {
    await mainDartFile.writeAsString(modifiedContent);
    print('✅ Made $replacements replacements to fix const lists');
  } else {
    print('⚠️ No problematic const lists found');
    
    // Last resort - completely remove const from the MaterialApp
    final materialAppPattern = RegExp(r'return\s+MaterialApp\(');
    String lastResortContent = content;
    
    if (materialAppPattern.hasMatch(content)) {
      // Find all const expressions within the MaterialApp section
      int materialAppStart = content.indexOf(materialAppPattern);
      if (materialAppStart >= 0) {
        // Count opening and closing parentheses to find the end
        int openParens = 1;
        int closeParens = 0;
        int materialAppEnd = materialAppStart;
        
        for (int i = materialAppStart + 'return MaterialApp('.length; i < content.length; i++) {
          if (content[i] == '(') openParens++;
          if (content[i] == ')') closeParens++;
          
          if (openParens == closeParens) {
            materialAppEnd = i;
            break;
          }
        }
        
        if (materialAppEnd > materialAppStart) {
          final materialAppSection = content.substring(materialAppStart, materialAppEnd);
          final cleanedSection = materialAppSection.replaceAll('const [', '[');
          
          lastResortContent = content.replaceRange(materialAppStart, materialAppEnd, cleanedSection);
          await mainDartFile.writeAsString(lastResortContent);
          print('✅ Removed const from all lists in MaterialApp builder');
        }
      }
    }
  }
  
  print('\nNext step: Run flutter run to verify the fix');
}
