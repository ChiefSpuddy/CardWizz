import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class StandardAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool transparent;
  final double elevation;
  final VoidCallback? onLeadingPressed;
  final Widget? leading;
  final PreferredSizeWidget? bottom;

  const StandardAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.transparent = false,
    this.elevation = 0,
    this.onLeadingPressed,
    this.leading,
    this.bottom,
  }) : super(key: key);
  
  @override
  Size get preferredSize => Size.fromHeight(bottom != null ? kToolbarHeight + bottom!.preferredSize.height : kToolbarHeight);
  
  /// Factory method to create an AppBar only when the user is signed in
  static AppBar? createIfSignedIn(
    BuildContext context, {
    required String title,
    List<Widget>? actions,
    bool transparent = false,
    double elevation = 0,
    VoidCallback? onLeadingPressed,
    Widget? leading,
    PreferredSizeWidget? bottom,
  }) {
    final isSignedIn = context.watch<AppState>().isAuthenticated;
    
    // Return null when not signed in so no AppBar is displayed
    if (!isSignedIn) {
      return null;
    }
    
    // Create a custom leading widget that uses onLeadingPressed if provided
    final customLeading = onLeadingPressed != null && leading == null
        ? IconButton(
            icon: const Icon(Icons.menu),
            onPressed: onLeadingPressed,
          )
        : leading;
    
    return AppBar(
      title: Text(title),
      actions: actions,
      elevation: elevation,
      backgroundColor: transparent ? Colors.transparent : null,
      leading: customLeading,
      bottom: bottom,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    // Create a custom leading widget that uses onLeadingPressed if provided
    final customLeading = onLeadingPressed != null && leading == null
        ? IconButton(
            icon: const Icon(Icons.menu),
            onPressed: onLeadingPressed,
          )
        : leading;
        
    return AppBar(
      title: Text(title),
      actions: actions,
      elevation: elevation,
      backgroundColor: transparent ? Colors.transparent : null,
      leading: customLeading,
      bottom: bottom,
    );
  }
}
