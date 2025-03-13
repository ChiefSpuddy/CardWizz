import '../services/logging_service.dart';
import 'dart:io';

void main() {
  // Directory to search
  final directory = Directory('/Users/sam.may/CardWizz/lib');
  
  // Get all file paths
  final List<String> paths = [];
  _getAllFilePaths(directory, paths);
  
  // Get all imported file paths
  final Map<String, List<String>> imports = _getFileImports(paths);
  
  // Find files that are never imported
  final List<String> unused = _findUnused(paths, imports);
  
  // Print results
  LoggingService.debug('Found ${unused.length} potentially unused files:');
  for (final path in unused) {
    LoggingService.debug('- $path');
  }
}

void _getAllFilePaths(Directory directory, List<String> paths) {
  final List<FileSystemEntity> entities = directory.listSync();
  
  for (final entity in entities) {
    if (entity is File && entity.path.endsWith('.dart')) {
      paths.add(entity.path);
    } else if (entity is Directory) {
      _getAllFilePaths(entity, paths);
    }
  }
}

Map<String, List<String>> _getFileImports(List<String> paths) {
  final Map<String, List<String>> imports = {};
  
  for (final path in paths) {
    final file = File(path);
    final content = file.readAsStringSync();
    final lines = content.split('\n');
    
    for (final line in lines) {
      if (line.trim().startsWith('import ')) {
        // Fix: Using double quotes for the outer string to avoid single quote issues
        final match = RegExp("import\\s+['\"](.+)['\"]").firstMatch(line);
        if (match != null) {
          final import = match.group(1)!;
          
          if (!import.startsWith('dart:') && !import.startsWith('package:')) {
            final importPath = _resolveImportPath(path, import);
            
            if (importPath != null) {
              imports[path] ??= [];
              imports[path]!.add(importPath);
            }
          }
        }
      }
    }
  }
  
  return imports;
}

String? _resolveImportPath(String currentPath, String import) {
  final directory = Directory(currentPath).parent.path;
  
  if (import.startsWith('./')) {
    return '$directory/${import.substring(2)}.dart';
  } else if (import.startsWith('../')) {
    return '$directory/$import.dart';
  } else {
    // Assuming the import is from the lib directory
    final libPath = _findLibPath(currentPath);
    if (libPath != null) {
      return '$libPath/$import.dart';
    }
  }
  
  return null;
}

String? _findLibPath(String path) {
  final parts = path.split('/');
  final libIndex = parts.indexOf('lib');
  
  if (libIndex >= 0) {
    return parts.sublist(0, libIndex + 1).join('/');
  }
  
  return null;
}

List<String> _findUnused(List<String> paths, Map<String, List<String>> imports) {
  final Set<String> importedFiles = {};
  
  for (final importList in imports.values) {
    importedFiles.addAll(importList);
  }
  
  // Files that contain 'main.dart' or 'app.dart' in their path are entry points
  final entryPoints = paths.where((path) => 
    path.contains('main.dart') || path.contains('app.dart')).toSet();
  
  // Files that are never imported by other files (except entry points)
  return paths.where((path) => 
    !importedFiles.contains(path) && !entryPoints.contains(path)).toList();
}
