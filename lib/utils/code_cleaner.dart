import 'dart:io';
import 'package:path/path.dart' as path;

/**
 * This utility helps identify potentially unused files in your Flutter project.
 * This is not meant to be run as part of the app, but as a standalone script
 * to help you clean your codebase.
 */
class CodeCleaner {
  static void analyzeImports() {
    print('📊 Starting code analysis for unused files...');
    
    final projectDir = Directory('/Users/sam.may/CardWizz');
    final libDir = Directory('${projectDir.path}/lib');
    
    if (!libDir.existsSync()) {
      print('❌ Error: Could not find lib directory at ${libDir.path}');
      return;
    }
    
    // Map of all Dart files in the project
    Map<String, bool> allDartFiles = {};
    Map<String, int> importCount = {};
    
    // First pass: collect all Dart files
    _collectDartFiles(libDir, allDartFiles);
    print('📁 Found ${allDartFiles.length} Dart files in the project');
    
    // Second pass: analyze imports
    _analyzeFilesForImports(libDir, allDartFiles, importCount);
    
    // Find unused files (not imported anywhere)
    final unusedFiles = allDartFiles.entries
      .where((entry) => !entry.value && !_isEntryPoint(entry.key))
      .map((entry) => entry.key)
      .toList();
      
    // Find rarely used files (imported only once)
    final rarelyUsedFiles = importCount.entries
      .where((entry) => entry.value == 1)
      .map((entry) => entry.key)
      .toList();
    
    // Output results
    print('\n🔍 ANALYSIS RESULTS:');
    print('${unusedFiles.length} potentially unused files found:');
    for (var file in unusedFiles) {
      print('  - $file');
    }
    
    print('\n📉 ${rarelyUsedFiles.length} files imported only once:');
    for (var file in rarelyUsedFiles.take(10)) {
      print('  - $file');
    }
    
    print('\n⚠️ Note: This analysis is not perfect. Some files might be:');
    print('   1. Entry points (like main.dart)');
    print('   2. Referenced dynamically');
    print('   3. Used in assets or as part of other mechanisms');
    print('   Always review before deleting any files.');
  }
  
  static bool _isEntryPoint(String filePath) {
    final basename = path.basename(filePath);
    return basename == 'main.dart' ||
           basename == 'app.dart' ||
           basename.contains('_app.dart');
  }
  
  static void _collectDartFiles(Directory dir, Map<String, bool> allDartFiles) {
    final entities = dir.listSync(recursive: true);
    
    for (var entity in entities) {
      if (entity is File && entity.path.endsWith('.dart')) {
        final relativePath = entity.path.replaceAll('${dir.parent.path}/', '');
        allDartFiles[relativePath] = false;  // Mark as not referenced initially
      }
    }
  }
  
  static void _analyzeFilesForImports(
    Directory dir,
    Map<String, bool> allDartFiles,
    Map<String, int> importCount
  ) {
    final entities = dir.listSync(recursive: true);
    
    for (var entity in entities) {
      if (entity is File && entity.path.endsWith('.dart')) {
        final fileContent = entity.readAsStringSync();
        final lines = fileContent.split('\n');
        
        for (var line in lines) {
          if (line.trim().startsWith('import ')) {
            // Fix: Using double quotes for the outer string to avoid single quote issues
            final importMatch = RegExp("import\\s+['\"](.+?)['\"]").firstMatch(line);
            if (importMatch != null) {
              final importPath = importMatch.group(1)!;
              
              // Only care about project imports (not packages)
              if (!importPath.startsWith('package:') && !importPath.startsWith('dart:')) {
                // Resolve the import path to file system path
                String resolvedPath;
                
                if (importPath.startsWith('../')) {
                  // Handle relative imports with parent directory references
                  final currentDir = path.dirname(entity.path);
                  resolvedPath = path.normalize(path.join(currentDir, importPath));
                } else if (importPath.startsWith('./')) {
                  // Handle explicit relative imports
                  final currentDir = path.dirname(entity.path);
                  resolvedPath = path.normalize(path.join(currentDir, importPath.substring(2)));
                } else {
                  // Handle imports from lib
                  resolvedPath = 'lib/$importPath';
                }
                
                // Add .dart extension if missing
                if (!resolvedPath.endsWith('.dart')) {
                  resolvedPath = '$resolvedPath.dart';
                }
                
                resolvedPath = path.normalize(resolvedPath);
                
                // Check if this is a project file and mark it as referenced
                for (var filePath in allDartFiles.keys) {
                  if (resolvedPath.endsWith(filePath) || filePath.endsWith(resolvedPath)) {
                    allDartFiles[filePath] = true;  // Mark as referenced
                    
                    // Count imports
                    importCount[filePath] = (importCount[filePath] ?? 0) + 1;
                  }
                }
              }
            }
          }
        }
      }
    }
  }
  
  static List<String> getUnusedWidgets() {
    print('🔍 Searching for unused widget classes...');
    
    final libDir = Directory('/Users/sam.may/CardWizz/lib');
    final unusedWidgets = <String>[];
    final definedWidgets = <String, String>{};  // widget name -> file path
    
    if (!libDir.existsSync()) {
      print('❌ Error: Could not find lib directory');
      return unusedWidgets;
    }
    
    // First pass: find all widget classes
    _findWidgetClasses(libDir, definedWidgets);
    
    // Second pass: check where widgets are used
    final usedWidgets = <String>{};
    _findWidgetUsages(libDir, definedWidgets.keys.toList(), usedWidgets);
    
    // Find unused widgets
    for (var widgetName in definedWidgets.keys) {
      if (!usedWidgets.contains(widgetName) && 
          !_isLikelyEntryPointWidget(widgetName)) {
        unusedWidgets.add('${widgetName} (${definedWidgets[widgetName]})');
      }
    }
    
    return unusedWidgets;
  }
  
  static bool _isLikelyEntryPointWidget(String widgetName) {
    return widgetName == 'MyApp' || 
           widgetName == 'App' || 
           widgetName == 'MainApp' ||
           widgetName.contains('Screen') ||  // Many screens are used via routes
           widgetName.contains('Page');      // Pages may be referenced via routes
  }
  
  static void _findWidgetClasses(Directory dir, Map<String, String> widgets) {
    final entities = dir.listSync(recursive: true);
    
    for (var entity in entities) {
      if (entity is File && entity.path.endsWith('.dart')) {
        final fileContent = entity.readAsStringSync();
        final lines = fileContent.split('\n');
        
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i].trim();
          
          // Look for class declarations that extend/implement Widget
          final classMatch = RegExp(r'class\s+(\w+)\s+extends\s+(\w+)').firstMatch(line);
          if (classMatch != null) {
            final className = classMatch.group(1);
            final parentClass = classMatch.group(2);
            
            if (className != null && parentClass != null) {
              if (_isWidgetBaseClass(parentClass) || 
                  (i > 0 && lines[i-1].contains('StatelessWidget')) ||
                  (i > 0 && lines[i-1].contains('StatefulWidget'))) {
                widgets[className] = _getRelativePath(entity.path);
              }
            }
          }
        }
      }
    }
  }
  
  static bool _isWidgetBaseClass(String className) {
    return className == 'StatelessWidget' || 
           className == 'StatefulWidget' || 
           className == 'Widget' ||
           className.endsWith('Widget');
  }
  
  static void _findWidgetUsages(Directory dir, List<String> widgetNames, Set<String> usedWidgets) {
    final entities = dir.listSync(recursive: true);
    
    for (var entity in entities) {
      if (entity is File && entity.path.endsWith('.dart')) {
        final fileContent = entity.readAsStringSync();
        
        for (var widgetName in widgetNames) {
          // Look for widget usage patterns
          final widgetUsagePattern1 = RegExp(r'<\s*' + widgetName + r'\s*>');
          final widgetUsagePattern2 = RegExp(r'new\s+' + widgetName);
          final widgetUsagePattern3 = RegExp(r':\s*' + widgetName + r'\(');
          final widgetUsagePattern4 = RegExp(r'=\s*' + widgetName + r'\(');
          final widgetUsagePattern5 = RegExp(r'const\s+' + widgetName + r'\(');
          
          if (widgetUsagePattern1.hasMatch(fileContent) ||
              widgetUsagePattern2.hasMatch(fileContent) ||
              widgetUsagePattern3.hasMatch(fileContent) ||
              widgetUsagePattern4.hasMatch(fileContent) ||
              widgetUsagePattern5.hasMatch(fileContent)) {
            usedWidgets.add(widgetName);
          }
        }
      }
    }
  }
  
  static String _getRelativePath(String absolutePath) {
    final projectDir = '/Users/sam.may/CardWizz';
    return absolutePath.replaceFirst('$projectDir/', '');
  }
  
  static void printFilesSortedBySize() {
    final libDir = Directory('/Users/sam.may/CardWizz/lib');
    Map<String, int> fileSizes = {};
    
    if (!libDir.existsSync()) {
      print('❌ Error: Could not find lib directory');
      return;
    }
    
    final entities = libDir.listSync(recursive: true);
    for (var entity in entities) {
      if (entity is File && entity.path.endsWith('.dart')) {
        final size = entity.lengthSync();
        fileSizes[_getRelativePath(entity.path)] = size;
      }
    }
    
    // Sort files by size (largest first)
    final sortedFiles = fileSizes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    print('\n📊 FILES BY SIZE (largest first):');
    for (var i = 0; i < sortedFiles.length && i < 20; i++) {
      final entry = sortedFiles[i];
      final sizeKb = entry.value / 1024;
      print('${i+1}. ${entry.key}: ${sizeKb.toStringAsFixed(1)} KB');
    }
  }
}

// Entry point to run the code cleaner
void main() {
  CodeCleaner.analyzeImports();
  
  print('\n==================================\n');
  
  final unusedWidgets = CodeCleaner.getUnusedWidgets();
  print('\n🧩 POTENTIALLY UNUSED WIDGETS:');
  for (var widget in unusedWidgets) {
    print('  - $widget');
  }
  
  print('\n==================================\n');
  
  CodeCleaner.printFilesSortedBySize();
  
  print('\n✅ Analysis complete. Review the results before removing any files.');
  print('Remember that some files might be referenced through routes or reflection!');
}
