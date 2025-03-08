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
  
  // Updated constructor with compact parameter
  const StandardAppBar({
    Key? key,
    this.actions,
    this.title,
    this.transparent = false,
    this.elevation = 0,
    this.onLeadingPressed,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.backgroundColor,
    this.foregroundColor,
    this.useBlack = false,
    this.compact = true, // Default to compact mode
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // Determine app bar colors based on transparent flag and provided colors
    final appBarBackgroundColor = useBlack 
        ? Colors.black 
        : (transparent 
            ? Colors.transparent 
            : backgroundColor ?? colorScheme.surface);
    
    final effectiveForegroundColor = foregroundColor ?? 
        (useBlack ? Colors.white : colorScheme.onSurface);
    
    // Create a container with a subtle bottom border instead of using elevation
    return Container(
      decoration: BoxDecoration(
        color: appBarBackgroundColor,
        // Add a subtle bottom border instead of harsh elevation shadow
        border: elevation > 0 && !transparent ? 
          Border(
            bottom: BorderSide(
              color: colorScheme.outlineVariant.withOpacity(0.15),
              width: 0.5, // Thinner line for subtlety
            ),
          ) : null,
      ),
      child: AppBar(
        backgroundColor: Colors.transparent, // Make AppBar transparent since container has the color
        elevation: 0, // Remove elevation since we're using a custom border
        scrolledUnderElevation: transparent ? 0 : 0.5, // Reduced from 2 to 0.5
        centerTitle: true,
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
          '',  // Empty string instead of title to remove text but keep layout
          style: TextStyle(
            color: effectiveForegroundColor,
            fontWeight: FontWeight.bold,
          ),
        ) : null,
        actions: actions,
        iconTheme: IconThemeData(color: effectiveForegroundColor, size: 22), // Smaller icon size
        actionsIconTheme: IconThemeData(color: effectiveForegroundColor, size: 22), // Smaller icon size
      ),
    );
  }
  
  @override
  Size get preferredSize => Size.fromHeight(compact ? kToolbarHeight - 8 : kToolbarHeight);
  
  /// Static method to conditionally create AppBar only if user is signed in
  static PreferredSizeWidget? createIfSignedIn(
    BuildContext context, {
    String? title,
    List<Widget>? actions,
    bool transparent = false,
    double elevation = 0,
    VoidCallback? onLeadingPressed,
    bool useBlack = false,
    bool compact = true, // Default to compact
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
    );
  }
}
