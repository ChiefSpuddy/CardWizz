/// Collection of String extension methods used throughout the app
extension StringExtensions on String {
  /// Capitalizes the first letter of the string
  String capitalize() {
    return isNotEmpty ? '${this[0].toUpperCase()}${substring(1)}' : this;
  }
  
  /// Converts snake_case to Title Case
  String toTitleCase() {
    return split('_')
        .map((word) => word.capitalize())
        .join(' ');
  }
  
  /// Checks if string is a valid URL
  bool isValidUrl() {
    final urlPattern = RegExp(
      r'^(http|https):\/\/[a-zA-Z0-9-_]+(\.[a-zA-Z0-9-_]+)+([\/\?#].*)?$',
      caseSensitive: false,
    );
    return urlPattern.hasMatch(this);
  }
}
