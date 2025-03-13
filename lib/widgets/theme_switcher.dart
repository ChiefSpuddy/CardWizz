import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../utils/color_extensions.dart';

class ThemeSwitcher extends StatelessWidget {
  final bool showLabel;
  final bool useBigSize;
  final bool useCompactSize;
  final EdgeInsets? padding;
  
  const ThemeSwitcher({
    Key? key,
    this.showLabel = false,
    this.useBigSize = false,
    this.useCompactSize = false,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    
    // Determine icon size based on params
    final double iconSize = useBigSize 
        ? 24.0 
        : (useCompactSize ? 16.0 : 20.0);
    
    return InkWell(
      onTap: () => themeProvider.toggleTheme(),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(8.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withAlpha((0.8 * 255).round()), // Fixed: Using extension method and withAlpha
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return ScaleTransition(
                    scale: animation,
                    child: FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                  );
                },
                child: isDarkMode
                    ? Icon(
                        Icons.dark_mode,
                        key: const ValueKey('dark'),
                        size: iconSize,
                        color: colorScheme.primary,
                      )
                    : Icon(
                        Icons.light_mode,
                        key: const ValueKey('light'),
                        size: iconSize,
                        color: colorScheme.primary,
                      ),
              ),
              if (showLabel) ...[
                const SizedBox(width: 8),
                Text(
                  isDarkMode ? 'Dark Mode' : 'Light Mode',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface, // Fixed: Using onSurface instead of onBackground
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ThemeModeSelector extends StatelessWidget {
  const ThemeModeSelector({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;
    final currentThemeMode = themeProvider.themeMode;
    
    // Get appropriate UI text for each theme mode
    String getModeText(ThemeMode mode) {
      switch (mode) {
        case ThemeMode.system: return 'System';
        case ThemeMode.light: return 'Light';
        case ThemeMode.dark: return 'Dark';
      }
    }
    
    // Get appropriate icon for each theme mode
    IconData getModeIcon(ThemeMode mode) {
      switch (mode) {
        case ThemeMode.system: return Icons.brightness_auto;
        case ThemeMode.light: return Icons.light_mode;
        case ThemeMode.dark: return Icons.dark_mode;
      }
    }
    
    // Create option for each theme mode
    Widget buildThemeModeOption(ThemeMode mode) {
      final isSelected = currentThemeMode == mode;
      
      return InkWell(
        onTap: () => themeProvider.setThemeMode(mode),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected 
                ? colorScheme.primary.withAlpha((0.2 * 255).round()) // Fixed: Using withAlpha
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected 
                  ? colorScheme.primary 
                  : colorScheme.primary.withAlpha((0.2 * 255).round()), // Fixed: Using withAlpha
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Icon(
                getModeIcon(mode),
                color: isSelected ? colorScheme.primary : colorScheme.onSurface.withAlpha((0.7 * 255).round()),
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                getModeText(mode),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                ),
              ),
              if (isSelected) ...[
                const Spacer(),
                Icon(
                  Icons.check_circle,
                  color: colorScheme.primary,
                  size: 20,
                ),
              ],
            ],
          ),
        ),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'Choose Theme',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          buildThemeModeOption(ThemeMode.system),
          const SizedBox(height: 10),
          buildThemeModeOption(ThemeMode.light),
          const SizedBox(height: 10),
          buildThemeModeOption(ThemeMode.dark),
        ],
      ),
    );
  }
}
