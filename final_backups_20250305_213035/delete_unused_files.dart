import 'dart:io';

void main() async {
  final projectPath = Directory.current.path;
  print('WARNING: This will permanently delete all .unused files.');
  print('Make sure you have thoroughly tested your app first!');
  stdout.write('Type "DELETE" to confirm: ');
  
  final input = stdin.readLineSync();
  if (input?.toUpperCase() != 'DELETE') {
    print('Operation cancelled.');
    return;
  }
  
  int deleted = 0;
  await for (final entity in Directory(projectPath).list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.unused')) {
      try {
        await entity.delete();
        print('✓ Deleted: ${entity.path}');
        deleted++;
      } catch (e) {
        print('✗ Failed to delete ${entity.path}: $e');
      }
    }
  }
  
  print('\nCleanup complete. $deleted files permanently deleted.');
}
