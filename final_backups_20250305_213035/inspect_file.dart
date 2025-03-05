import 'dart:io';

void main() async {
  final projectPath = Directory.current.path;
  stdout.write('Enter the file path to inspect (relative to $projectPath): ');
  final relativePath = stdin.readLineSync();
  
  if (relativePath == null || relativePath.isEmpty) {
    print('No file path provided. Exiting.');
    return;
  }
  
  final filePath = '$projectPath/$relativePath';
  final file = File(filePath);
  
  if (!await file.exists()) {
    print('❌ File not found at: $filePath');
    return;
  }
  
  print('\nInspecting file: $filePath');
  
  final content = await file.readAsString();
  final lines = content.split('\n');
  
  print('\nFile has ${lines.length} lines');

  stdout.write('Enter line number to view (or range like "40-45"): ');
  final lineInput = stdin.readLineSync();
  
  if (lineInput == null || lineInput.isEmpty) {
    print('No line number provided. Exiting.');
    return;
  }

  if (lineInput.contains('-')) {
    // Handle range
    final parts = lineInput.split('-');
    if (parts.length == 2) {
      final start = int.tryParse(parts[0].trim());
      final end = int.tryParse(parts[1].trim());
      
      if (start != null && end != null && start > 0 && end <= lines.length && start <= end) {
        print('\nShowing lines $start to $end:');
        for (int i = start - 1; i < end; i++) {
          print('${i + 1}: ${lines[i]}');
        }
      } else {
        print('Invalid line range. Line numbers should be between 1 and ${lines.length}');
      }
    } else {
      print('Invalid range format. Please use format like "40-45"');
    }
  } else {
    // Handle single line
    final lineNumber = int.tryParse(lineInput);
    if (lineNumber != null && lineNumber > 0 && lineNumber <= lines.length) {
      print('\nLine $lineNumber: ${lines[lineNumber - 1]}');
      
      // Show some context
      final contextStart = (lineNumber - 3).clamp(0, lines.length - 1);
      final contextEnd = (lineNumber + 2).clamp(0, lines.length - 1);
      
      if (contextStart < lineNumber - 1 || contextEnd > lineNumber - 1) {
        print('\nContext:');
        for (int i = contextStart; i <= contextEnd; i++) {
          print('${i + 1}${i == lineNumber - 1 ? ' >>> ' : ': '}${lines[i]}');
        }
      }
      
      // Ask if user wants to edit the line
      stdout.write('\nDo you want to edit this line? (y/n): ');
      final edit = stdin.readLineSync()?.toLowerCase() == 'y';
      
      if (edit) {
        print('Enter the new content for line $lineNumber:');
        final newContent = stdin.readLineSync();
        
        if (newContent != null) {
          lines[lineNumber - 1] = newContent;
          await file.writeAsString(lines.join('\n'));
          print('✅ Line $lineNumber updated');
        } else {
          print('No content provided. Line not modified.');
        }
      }
      
      // Ask if user wants to delete the line
      stdout.write('\nDo you want to delete this line? (y/n): ');
      final delete = stdin.readLineSync()?.toLowerCase() == 'y';
      
      if (delete) {
        lines.removeAt(lineNumber - 1);
        await file.writeAsString(lines.join('\n'));
        print('✅ Line $lineNumber deleted');
      }
      
      // Ask if user wants to comment out the line
      if (!delete && !edit) {
        stdout.write('\nDo you want to comment out this line? (y/n): ');
        final comment = stdin.readLineSync()?.toLowerCase() == 'y';
        
        if (comment) {
          lines[lineNumber - 1] = '// ' + lines[lineNumber - 1];
          await file.writeAsString(lines.join('\n'));
          print('✅ Line $lineNumber commented out');
        }
      }
    } else {
      print('Invalid line number. Line number should be between 1 and ${lines.length}');
    }
  }
}
