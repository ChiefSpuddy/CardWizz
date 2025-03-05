import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

void main() async {
  final projectPath = Directory.current.path;
  print('Analyzing project at: $projectPath');
  print('Scanning for potentially unused files...');
  
  // Get all Dart files in the project
  final dartFiles = await _getAllDartFiles(projectPath);
  print('Found ${dartFiles.length} Dart files in project');
  
  // Extract all imports from all files
  final allImports = await _extractAllImports(dartFiles);
  print('Found ${allImports.length} unique imports');
  
  // Get all assets from pubspec.yaml
  final pubspecFile = File(path.join(projectPath, 'pubspec.yaml'));
  final assetFiles = await _getAssetsFromPubspec(pubspecFile);
  print('Found ${assetFiles.length} assets in pubspec.yaml');
  
  // Find potentially unused files
  final potentiallyUnusedFiles = await _findPotentiallyUnusedFiles(
    projectPath, dartFiles, allImports, assetFiles);
    
  // Print results
  if (potentiallyUnusedFiles.isEmpty) {
    print('\nNo potentially unused files found. Your project looks clean!');
  } else {
    print('\nPotentially unused files (${potentiallyUnusedFiles.length}):');
    for (var file in potentiallyUnusedFiles) {
      print(' - ${file.path.replaceFirst(projectPath, '')}');
    }
    
    print('\nCAUTION: Review these files carefully before deletion.');
    print('Some files might be:');
    print(' - Dynamically imported using strings');
    print(' - Referenced in native code (Android/iOS)');
    print(' - Used as entry points for build systems');
    print(' - Required by external packages');
  }
}

Future<List<File>> _getAllDartFiles(String directory) async {
  final files = <File>[];
  await for (final entity in Directory(directory).list(recursive: true)) {
    if (entity is File && 
        entity.path.endsWith('.dart') && 
        !entity.path.contains('/.dart_tool/') &&
        !entity.path.contains('/.pub/') &&
        !entity.path.contains('/build/')) {
      files.add(entity);
    }
  }
  return files;
}

Future<Set<String>> _extractAllImports(List<File> dartFiles) async {
  final imports = <String>{};
  // Simplify the RegExp by using two separate patterns for single and double quotes
  final singleQuoteRegex = RegExp(r"import\s+'([^']*)'");
  final doubleQuoteRegex = RegExp(r'import\s+"([^"]*)"');
  
  for (final file in dartFiles) {
    final content = await file.readAsString();
    
    // Process imports with single quotes
    final singleQuoteMatches = singleQuoteRegex.allMatches(content);
    for (final match in singleQuoteMatches) {
      final importPath = match.group(1);
      if (importPath != null && !importPath.startsWith('dart:') && !importPath.startsWith('package:flutter/')) {
        imports.add(importPath);
      }
    }
    
    // Process imports with double quotes
    final doubleQuoteMatches = doubleQuoteRegex.allMatches(content);
    for (final match in doubleQuoteMatches) {
      final importPath = match.group(1);
      if (importPath != null && !importPath.startsWith('dart:') && !importPath.startsWith('package:flutter/')) {
        imports.add(importPath);
      }
    }
  }
  
  return imports;
}

Future<Set<String>> _getAssetsFromPubspec(File pubspecFile) async {
  final assets = <String>{};
  
  if (await pubspecFile.exists()) {
    final content = await pubspecFile.readAsString();
    final yamlDoc = loadYaml(content);
    
    if (yamlDoc['flutter'] != null && yamlDoc['flutter']['assets'] != null) {
      final assetsList = yamlDoc['flutter']['assets'] as YamlList;
      assets.addAll(assetsList.map((asset) => asset.toString()));
    }
  }
  
  return assets;
}

Future<List<File>> _findPotentiallyUnusedFiles(
    String projectPath, List<File> allFiles, Set<String> imports, Set<String> assets) async {
  final unusedFiles = <File>[];
  final filePathsRelative = <String>{};
  final filePathsAbsolute = <String, File>{};
  
  // Build maps for quick lookup
  for (final file in allFiles) {
    final relativePath = file.path.replaceFirst('$projectPath/', '');
    filePathsRelative.add(relativePath);
    filePathsAbsolute[relativePath] = file;
    
    // Also add path without extension
    if (relativePath.endsWith('.dart')) {
      final noExt = relativePath.substring(0, relativePath.length - 5);
      filePathsRelative.add(noExt);
      filePathsAbsolute[noExt] = file;
    }
  }
  
  // Check each file if it's imported somewhere
  for (final file in allFiles) {
    final relativePath = file.path.replaceFirst('$projectPath/', '');
    
    // Skip main.dart, generated files, and test files
    if (relativePath == 'lib/main.dart' || 
        relativePath.contains('generated') || 
        relativePath.contains('/test/') ||
        relativePath.startsWith('test/')) {
      continue;
    }
    
    // Check if this file is imported somewhere
    bool isUsed = false;
    
    // Convert lib/path/file.dart to package:app_name/path/file.dart format
    final packagePath = relativePath.startsWith('lib/') 
        ? 'package:${_getPackageName(projectPath)}/${relativePath.substring(4)}'
        : null;
        
    // Also handle relative imports
    final fileNameOnly = path.basename(relativePath);
    
    for (final imp in imports) {
      if ((packagePath != null && imp == packagePath) || 
          imp.endsWith(relativePath) ||
          imp.endsWith(fileNameOnly)) {
        isUsed = true;
        break;
      }
    }
    
    // Check if file is referenced in assets
    if (!isUsed) {
      for (final asset in assets) {
        if (relativePath.startsWith(asset) || asset.contains(fileNameOnly)) {
          isUsed = true;
          break;
        }
      }
    }
    
    if (!isUsed) {
      unusedFiles.add(file);
    }
  }
  
  return unusedFiles;
}

String _getPackageName(String projectPath) {
  try {
    final pubspecFile = File(path.join(projectPath, 'pubspec.yaml'));
    final content = pubspecFile.readAsStringSync();
    final yamlDoc = loadYaml(content);
    return yamlDoc['name'] as String;
  } catch (e) {
    print('Error getting package name: $e');
    return 'cardwizz'; // Fallback to a default name
  }
}
