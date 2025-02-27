import 'package:flutter/material.dart';

class AppColors {
  // Base Colors - beautiful, modern palette
  static const primary = Color(0xFF6366F1);    // Soft indigo
  static const secondary = Color(0xFF818CF8);  // Light indigo
  static const tertiary = Color(0xFF14B8A6);   // Teal accent
  static const background = Color(0xFFF8FAFC); // Cool gray
  static const darkBackground = Color(0xFF0F172A); // Slate dark background
  static const surface = Colors.white;
  static const error = Color(0xFFF43F5E);      // Soft rose
  static const success = Color(0xFF10B981);    // Emerald green
  static const warning = Color(0xFFFBBF24);    // Amber
  
  // Text Colors
  static const textPrimary = Color(0xFF1E293B);     // Slate 800
  static const textSecondary = Color(0xFF64748B);   // Slate 500
  static const textLight = Color(0xFF94A3B8);       // Slate 400
  static const textDark = Color(0xFF303030);        // Slate 900
  
  // Game Specific Colors - Enhanced
  static const primaryPokemon = Color(0xFF3F51B5);  // Richer Pokémon blue
  static const secondaryPokemon = Color(0xFFFFD700); // Vibrant Pokémon yellow
  static const primaryJapanese = Color(0xFFD32F2F);  // Rich Japanese red
  static const secondaryJapanese = Color(0xFFFFFFFF); // White
  static const primaryMtg = Color(0xFF795548);      // Modern MTG brown
  static const secondaryMtg = Color(0xFFFFB300);    // Modern MTG gold

  // Returns gradient colors based on game type
  static List<Color> getGradientForGameType(String gameType, {bool isDark = false}) {
    if (isDark) {
      return [searchHeaderDark, searchHeaderDarkGradient];
    }
    return [searchHeaderLight, searchHeaderLightGradient];
  }

  // Card type colors - more vibrant
  static const Map<String, Color> pokemonTypeColors = {
    'Colorless': Color(0xFFA8A878),
    'Darkness': Color(0xFF705848),
    'Dragon': Color(0xFF6F35FC),
    'Fairy': Color(0xFFEE99AC),
    'Fighting': Color(0xFFC22E28),
    'Fire': Color(0xFFF08030),
    'Grass': Color(0xFF7AC74C),
    'Lightning': Color(0xFFF7D02C),
    'Metal': Color(0xFFB8B8D0),
    'Psychic': Color(0xFFF95587),
    'Water': Color(0xFF6390F0),
  };

  // MTG colors - more vibrant
  static const Map<String, Color> mtgColors = {
    'White': Color(0xFFF9FAFB),
    'Blue': Color(0xFF1E40AF),
    'Black': Color(0xFF1E1B1C),
    'Red': Color(0xFFB91C1C),
    'Green': Color(0xFF15803D),
    'Colorless': Color(0xFFE2E8F0),
    'Gold': Color(0xFFEAB308),
  };

  // Rarity gradients - more premium
  static List<Color> getRarityGradient(String rarity) {
    final rarityLower = rarity.toLowerCase();
    
    if (rarityLower.contains('hyper') || rarityLower.contains('secret')) {
      return const [Color(0xFF9333EA), Color(0xFF7E22CE)]; // Purple for hyper/secret rare
    } else if (rarityLower.contains('ultra')) {
      return const [Color(0xFFEA580C), Color(0xFFC2410C)]; // Orange for ultra rare
    } else if (rarityLower.contains('rare') && !rarityLower.contains('ultra')) {
      return const [Color(0xFFEAB308), Color(0xFFCA8A04)]; // Gold for rare
    } else if (rarityLower.contains('uncommon')) {
      return const [Color(0xFF0EA5E9), Color(0xFF0284C7)]; // Blue for uncommon
    } else {
      return const [Color(0xFF6B7280), Color(0xFF4B5563)]; // Grey for common
    }
  }

  // Price gradients - more informative and beautiful
  static List<Color> getPriceGradient(double price) {
    if (price > 100) {
      return const [Color(0xFFEF4444), Color(0xFFDC2626)]; // High value
    } else if (price > 50) {
      return const [Color(0xFFF97316), Color(0xFFEA580C)]; // Medium-high value
    } else if (price > 10) {
      return const [Color(0xFFEAB308), Color(0xFFCA8A04)]; // Medium value
    } else {
      return const [Color(0xFF22C55E), Color(0xFF16A34A)]; // Low value
    }
  }

  // Beautiful shadows for cards and components
  static List<BoxShadow> getCardShadow({double elevation = 1.0}) {
    return [
      BoxShadow(
        color: Colors.black.withOpacity(0.05 * elevation),
        blurRadius: 10 * elevation,
        offset: Offset(0, 4 * elevation),
        spreadRadius: 0,
      ),
      BoxShadow(
        color: Colors.black.withOpacity(0.03 * elevation),
        blurRadius: 25 * elevation,
        offset: Offset(0, 10 * elevation),
        spreadRadius: -5,
      ),
    ];
  }

  // Theme data helper
  static ThemeData getThemeData(bool isDark) {
    final ColorScheme colorScheme = isDark 
        ? const ColorScheme.dark(
            primary: primary,
            secondary: secondary,
            tertiary: tertiary,
            background: darkBackground,
            surface: Color(0xFF1E1E1E),
            error: error,
          )
        : const ColorScheme.light(
            primary: primary,
            secondary: secondary,
            tertiary: tertiary,
            background: background,
            surface: surface,
            error: error,
          );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      splashColor: primary.withOpacity(0.1),
      highlightColor: primary.withOpacity(0.05),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      scaffoldBackgroundColor: isDark ? darkBackground : background,
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent, // Changed to transparent
        foregroundColor: isDark ? Colors.white : textPrimary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ),
    );
  }

  // Search-specific colors
  static const searchBarLight = Color(0xFFFFFFFF);  // Slate 100
  static const searchBarDark = Color(0xFF303030);   // Slate 800
  
  static const searchIconLight = Color(0xFF757575);  // Slate 500
  static const searchIconDark = Color(0xFFBDBDBD);   // Slate 400
  
  static const searchHintLight = Color(0xFF9E9E9E);  // Slate 400
  static const searchHintDark = Color(0xFF707070);   // Slate 500

  // Search bar gradient based on mode
  static List<Color> getSearchBarGradient(bool isDark) {
    return isDark
        ? [
            const Color(0xFF1E293B).withOpacity(0.95),  // Slate 800
            const Color(0xFF0F172A).withOpacity(0.95),  // Slate 900
          ]
        : [
            Colors.white.withOpacity(0.95),
            const Color(0xFFF8FAFC).withOpacity(0.95),  // Slate 50
          ];
  }

  // Search header colors
  static const searchHeaderDark = Color(0xFF1E293B);  // Slate 800
  static const searchHeaderDarkGradient = Color(0xFF0F172A);  // Slate 900
  static const searchHeaderLight = Color(0xFFFFFFFF);  // White
  static const searchHeaderLightGradient = Color(0xFFF8FAFC);  // Slate 50

  // Search header gradient based on mode
  static List<Color> getSearchHeaderGradient(bool isDark) {
    return isDark
        ? [searchHeaderDark, searchHeaderDarkGradient]
        : [searchHeaderLight, searchHeaderLightGradient];
  }

  // Helper method to get the appropriate color for a value/price
  static Color getValueColor(double value) {
    if (value >= 100) {
      return const Color(0xFFC62828);  // Expensive - Red
    } else if (value >= 50) {
      return const Color(0xFFEF6C00);  // High value - Orange
    } else if (value >= 10) {
      return const Color(0xFF2E7D32);  // Medium value - Green
    } else if (value >= 5) {
      return const Color(0xFF1976D2);  // Low value - Blue
    } else {
      return const Color(0xFF757575);  // Very low value - Grey
    }
  }
}
