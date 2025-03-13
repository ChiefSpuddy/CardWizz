import 'dart:io';

void main() async {
  // Directory to scan
  final directory = Directory('/Users/sam.may/CardWizz/lib');
  
  // Regex patterns to look for
  final unusedVarPattern = RegExp(r'unused_local_variable|unused_field');
  final printPattern = RegExp(r'print\(');
  
  // Track findings
  final unusedVars = <String, List<String>>{};
  final printUsages = <String, List<int>>{};
  
  await for (final entity in directory.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final filePath = entity.path.replaceFirst('/Users/sam.may/CardWizz/lib/', '');
      final content = await entity.readAsString();
      final lines = content.split('\n');
      
      // Find prints
      for (var i = 0; i < lines.length; i++) {
        if (printPattern.hasMatch(lines[i])) {
          printUsages.putIfAbsent(filePath, () => []);
          printUsages[filePath]!.add(i + 1); // Line numbers start at 1
        }
      }
      
      // Extract unused var warnings from comments
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        final match = unusedVarPattern.firstMatch(line);
        if (match != null) {
          final varLine = lines[i-1]; // Usually the variable is defined on previous line
          unusedVars.putIfAbsent(filePath, () => []);
          unusedVars[filePath]!.add(varLine.trim());
        }
      }
    }
  }
  
  print('=== Files with print() calls ===');
  printUsages.forEach((file, lines) {
    print('$file: ${lines.length} print calls at lines ${lines.join(", ")}');
  });
  
  print('\n=== Unused variables ===');
  unusedVars.forEach((file, vars) {
    print('$file:');
    for (final v in vars) {
      print('  - $v');
    }
  });
}
