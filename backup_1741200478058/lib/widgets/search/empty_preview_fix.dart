import 'package:flutter/material.dart';

/// A utility class with static methods to help build empty preview widgets
/// without causing Hero conflicts.
class EmptyPreviewBuilder {

  /// Creates an empty preview widget for search results
  /// Designed to avoid hero tag conflicts by not using hero animations for empty states
  static Widget buildEmptyPreview(BuildContext context, {Color? backgroundColor}) {
    return Container(
      color: backgroundColor ?? Theme.of(context).colorScheme.surfaceVariant,
      child: const Center(
        child: Icon(
          Icons.search,
          size: 24,
          color: Colors.grey,
        ),
      ),
    );
  }

  /// Creates an empty preview widget specifically for image placeholders
  static Widget buildImagePlaceholder(BuildContext context, {double? size}) {
    return Container(
      width: size,
      height: size,
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: size != null ? size / 3 : 20,
          color: Colors.grey,
        ),
      ),
    );
  }
}
