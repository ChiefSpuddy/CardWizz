/// Utility methods for string manipulation

/// Extension methods on String for common operations
extension StringUtils on String {
  /// Capitalizes the first letter of a string
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }

  /// Capitalizes the first letter of each word in a string
  String titleCase() {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize()).join(' ');
  }

  /// Truncates a string to a maximum length and adds an ellipsis if needed
  String truncate(int maxLength, {String ellipsis = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - ellipsis.length)}$ellipsis';
  }

  /// Shortens a string while keeping the beginning and end
  String shorten(int maxLength, {String middle = '...'}) {
    if (length <= maxLength) return this;
    
    final charsToShow = (maxLength - middle.length) ~/ 2;
    final start = substring(0, charsToShow);
    final end = substring(length - charsToShow);
    
    return '$start$middle$end';
  }

  /// Converts a camelCase or PascalCase string to title case with spaces
  String camelCaseToTitleCase() {
    if (isEmpty) return this;
    return replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(0)}')
        .trim()
        .capitalize();
  }

  /// Converts a snake_case string to title case with spaces
  String snakeCaseToTitleCase() {
    if (isEmpty) return this;
    return split('_')
        .map((word) => word.capitalize())
        .join(' ');
  }

  /// Checks if a string contains another string, case insensitive
  bool containsIgnoreCase(String other) {
    return toLowerCase().contains(other.toLowerCase());
  }
  
  /// Removes all HTML tags from a string
  String stripHtml() {
    return replaceAll(RegExp(r'<[^>]*>'), '');
  }
  
  /// Formats a card number with leading zeros 
  /// (e.g., "1" becomes "001" if totalCards is 100+)
  String formatCardNumber({int? totalCards}) {
    if (isEmpty || int.tryParse(this) == null) return this;
    
    // Determine padding based on total cards
    int padLength = 1;
    if (totalCards != null) {
      if (totalCards >= 100) padLength = 3;
      else if (totalCards >= 10) padLength = 2;
    } else {
      // Default padding based on common card numbering
      padLength = 3;
    }
    
    return padLeft(padLength, '0');
  }
  
  /// Formats a price string with currency symbol
  String formatPrice({String symbol = '\$', bool showCents = true}) {
    final value = double.tryParse(this);
    if (value == null) return this;
    
    if (showCents) {
      return '$symbol${value.toStringAsFixed(2)}';
    } else {
      return '$symbol${value.toStringAsFixed(0)}';
    }
  }
}
