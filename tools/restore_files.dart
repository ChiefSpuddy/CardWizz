import 'dart:io';

void main() async {
  final projectPath = Directory.current.path;
  print('Restoring renamed files...');
  
  int restored = 0;
  await for (final entity in Directory(projectPath).list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.unused')) {
      final originalPath = entity.path.substring(0, entity.path.length - 7);
      try {
        await entity.rename(originalPath);
        print('✓ Restored: ${entity.path}');
        restored++;
      } catch (e) {
        print('✗ Failed to restore ${entity.path}: $e');
      }
    }
  }
  
  print('\nRestoration complete. $restored files restored.');
}
