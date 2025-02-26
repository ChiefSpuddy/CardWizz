import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../constants/app_colors.dart';

class ThemeSwitcher extends StatelessWidget {
  final bool showLabel;
  final bool useTile;
  
  const ThemeSwitcher({
    Key? key, 
    this.showLabel = true,
    this.useTile = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    if (useTile) {
      return ListTile(
        leading: Icon(
          isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: const Text('Dark Mode'),
        trailing: Switch(
          value: isDarkMode,
          activeColor: Theme.of(context).colorScheme.primary,
          onChanged: (_) => themeProvider.toggleTheme(),
        ),
        onTap: () => themeProvider.toggleTheme(),
      );
    }

    return GestureDetector(
      onTap: () => themeProvider.toggleTheme(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return RotationTransition(
                  turns: animation,
                  child: ScaleTransition(
                    scale: animation,
                    child: child,
                  ),
                );
              },
              child: Icon(
                isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                key: ValueKey<bool>(isDarkMode),
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            if (showLabel) ...[
              const SizedBox(width: 8),
              Text(
                isDarkMode ? 'Dark Mode' : 'Light Mode',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onBackground,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// A more advanced theme settings dialog
class ThemeSettingsDialog extends StatelessWidget {
  const ThemeSettingsDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return AlertDialog(
      title: const Text('Appearance'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildThemeOption(
            context,
            title: 'Light',
            icon: Icons.light_mode_rounded,
            isSelected: themeProvider.themeMode == ThemeMode.light,
            onTap: () => themeProvider.setLightMode(),
          ),
          const SizedBox(height: 8),
          _buildThemeOption(
            context,
            title: 'Dark',
            icon: Icons.dark_mode_rounded,
            isSelected: themeProvider.themeMode == ThemeMode.dark,
            onTap: () => themeProvider.setDarkMode(),
          ),
          const SizedBox(height: 8),
          _buildThemeOption(
            context,
            title: 'System',
            icon: Icons.brightness_auto,
            isSelected: themeProvider.themeMode == ThemeMode.system,
            onTap: () => themeProvider.setSystemMode(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildThemeOption(
    BuildContext context, {
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outline.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? colorScheme.primary : colorScheme.onSurface,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? colorScheme.primary : colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }

  // Show the dialog
  static Future<void> show(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return const ThemeSettingsDialog();
      },
    );
  }
}
