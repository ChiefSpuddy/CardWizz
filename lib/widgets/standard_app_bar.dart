import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class StandardAppBar extends StatelessWidget implements PreferredSizeWidget {
  final List<Widget>? actions;
  final String? title;
  final bool transparent;
  final double elevation;
  final VoidCallback? onLeadingPressed;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool useBlack;
  final bool compact;
  final bool floating;
  
  // Updated constructor with compact parameter and floating
  const StandardAppBar({
    Key? key,
    this.actions,
    this.title,
    this.transparent = true, // Default to transparent
    this.elevation = 0,
    this.onLeadingPressed,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.backgroundColor,
    this.foregroundColor,
    this.useBlack = false,
    this.compact = true, // Default to compact mode
    this.floating = false, // New parameter for floating app bar
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Determine app bar colors based on transparent flag and provided colors
    final appBarBackgroundColor = useBlack 
        ? Colors.black 
        : (transparent 
            ? Colors.transparent 
            : backgroundColor ?? colorScheme.surface);
    
    final effectiveForegroundColor = foregroundColor ?? 
        (useBlack ? Colors.white : colorScheme.onSurface);
    
    // Create a container with a subtle gradient background for floating style
    return Container(
      decoration: BoxDecoration(
        color: floating ? Colors.transparent : appBarBackgroundColor,
        // Add a subtle gradient for floating style
        gradient: floating ? LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            isDark 
              ? Colors.black.withOpacity(0.8) 
              : Colors.white.withOpacity(0.9),
            isDark 
              ? Colors.black.withOpacity(0.1)
              : Colors.white.withOpacity(0.2),
          ],
        ) : null,
        // Add a subtle bottom border instead of harsh elevation shadow
        border: elevation > 0 && !transparent && !floating ? 
          Border(
            bottom: BorderSide(
              color: colorScheme.outlineVariant.withOpacity(0.15),
              width: 0.5, // Thinner line for subtlety
            ),
          ) : null,
      ),
      child: Padding(
        padding: floating ? const EdgeInsets.only(bottom: 8.0) : EdgeInsets.zero,
        child: AppBar(
          backgroundColor: Colors.transparent, // Make AppBar transparent since container has the color
          elevation: 0, // Remove elevation since we're using a custom border
          scrolledUnderElevation: transparent ? 0 : 0.5, // Reduced from 2 to 0.5
          centerTitle: title != null,
          automaticallyImplyLeading: automaticallyImplyLeading,
          leading: leading ?? (onLeadingPressed != null 
              ? IconButton(
                  icon: const Icon(Icons.menu, size: 22), // Slightly smaller icon
                  padding: EdgeInsets.zero, // Remove padding for more compact look
                  onPressed: onLeadingPressed,
                ) 
              : null),
          titleSpacing: 8, // Reduced spacing for more compact look
          // Reduce vertical padding of app bar to make it more compact
          toolbarHeight: compact ? kToolbarHeight - 8 : kToolbarHeight, // 8px less height in compact mode
          title: title != null ? Text(
            title!,
            style: TextStyle(
              fontSize: compact ? 17 : 20, // Smaller font size for compact mode
              fontWeight: FontWeight.w600,
              color: effectiveForegroundColor,
            ),
          ) : null,
          actions: actions,
          iconTheme: IconThemeData(color: effectiveForegroundColor, size: compact ? 22 : 24),
          actionsIconTheme: IconThemeData(color: effectiveForegroundColor, size: compact ? 22 : 24),
        ),
      ),
    );
  }
  
  @override
  Size get preferredSize => Size.fromHeight(
    compact 
      ? (floating ? kToolbarHeight - 4 : kToolbarHeight - 8) 
      : kToolbarHeight
  );
  
  /// Static method to conditionally create AppBar only if user is signed in
  static PreferredSizeWidget? createIfSignedIn(
    BuildContext context, {
    String? title,
    List<Widget>? actions,
    bool transparent = true, // Default to transparent
    double elevation = 0,
    VoidCallback? onLeadingPressed,
    bool useBlack = false,
    bool compact = true, // Default to compact
    bool floating = false, // Default to not floating
  }) {
    final isAuthenticated = context.watch<AppState>().isAuthenticated;
    
    if (!isAuthenticated) {
      return null;
    }
    
    return StandardAppBar(
      title: title,
      actions: actions,
      transparent: transparent,
      elevation: elevation,
      onLeadingPressed: onLeadingPressed,
      useBlack: useBlack,
      compact: compact,
      floating: floating,
    );
  }
}
