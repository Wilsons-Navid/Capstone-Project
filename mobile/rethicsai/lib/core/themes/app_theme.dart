import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum DrawerThemeMode {
  normal,      // Default African sunset theme
  emergency,   // Calming greens for crisis situations
  professional, // Institutional blues for admin
  night,       // Dark mode for evening use
}

class AppTheme {
  // Premium African-inspired color palette - Earth Tones Collection
  static const Color primaryColor = Color(0xFF2D1B14); // Rich Charcoal Brown
  static const Color primaryLight = Color(0xFF3E2723); // Warm Dark Brown
  static const Color primaryDark = Color(0xFF1A0E0A); // Deep Earth
  
  static const Color secondaryColor = Color(0xFFCC8800); // Sunset Amber
  static const Color secondaryLight = Color(0xFFD4A158); // Soft Amber
  static const Color secondaryDark = Color(0xFFB8860B); // Dark Amber
  
  static const Color accentColor = Color(0xFF9CAF88); // Acacia Green
  static const Color accentLight = Color(0xFFAED581); // Light Acacia
  static const Color accentDark = Color(0xFF8A9B5A); // Deep Acacia
  
  // Status colors
  static const Color errorColor = Color(0xFFCD5C5C); // Clay Red
  static const Color errorLight = Color(0xFFE57373); // Light Clay
  static const Color warningColor = Color(0xFFD4A574); // Amber Warning
  static const Color warningLight = Color(0xFFFFB74D); // Light Amber
  static const Color successColor = Color(0xFF388E3C); // Success Green
  static const Color successLight = Color(0xFF4CAF50); // Light Success
  static const Color infoColor = Color(0xFF1976D2); // Info Blue
  static const Color infoLight = Color(0xFF2196F3); // Light Info
  
  // Authentic African earth tones
  static const Color saharaGold = Color(0xFFD4A574); // Refined Sahara Sand
  static const Color baobabBrown = Color(0xFF8B4513); // Authentic Baobab
  static const Color savannaTan = Color(0xFFDEB887); // Savanna Grass
  static const Color kilimanjaro = Color(0xFF5D4037); // Mountain Rock
  static const Color victoriaBlue = Color(0xFF4A6FA5); // Softer Victoria Falls
  static const Color clayRed = Color(0xFFCD5C5C); // African Clay
  static const Color copperAccent = Color(0xFFB87333); // Copper Highlight
  
  // Neutral colors
  static const Color surfaceLight = Color(0xFFFAFAFA);
  static const Color surfaceDark = Color(0xFF121212);
  static const Color surfaceVariant = Color(0xFFF5F5F5);
  static const Color outline = Color(0xFFE0E0E0);
  static const Color outlineVariant = Color(0xFFEEEEEE);
  
  // Text colors
  static const Color onPrimary = Colors.white;
  static const Color onSecondary = Colors.white;
  static const Color onSurface = Color(0xFF1C1B1F);
  static const Color onSurfaceVariant = Color(0xFF49454F);
  
  // Design constants
  static const double radiusXS = 4.0;
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 20.0;
  static const double radiusXXL = 24.0;
  
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;
  
  static const double iconSizeS = 16.0;
  static const double iconSizeM = 24.0;
  static const double iconSizeL = 32.0;
  static const double iconSizeXL = 48.0;
  
  static const double elevationS = 2.0;
  static const double elevationM = 4.0;
  static const double elevationL = 8.0;
  static const double elevationXL = 12.0;
  
  // Premium gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryColor, primaryLight],
    stops: [0.0, 1.0],
  );
  
  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondaryColor, secondaryLight],
    stops: [0.0, 1.0],
  );
  
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentColor, accentLight],
    stops: [0.0, 1.0],
  );
  
  static const LinearGradient africanSunsetGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [saharaGold, secondaryColor, baobabBrown],
    stops: [0.0, 0.7, 1.0],
  );

  // Crisis/Emergency mode gradient - calming earth tones with warm clay
  static const LinearGradient emergencyGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [clayRed, Color(0xFF8D5524), baobabBrown],
    stops: [0.0, 0.6, 1.0],
  );

  // Professional mode gradient - bronze and charcoal sophistication
  static const LinearGradient professionalGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primaryColor, copperAccent, baobabBrown],
    stops: [0.0, 0.5, 1.0],
  );

  // Night mode gradient - warm indigo with copper accents
  static const LinearGradient nightModeGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF2C3E50), copperAccent, primaryDark],
    stops: [0.0, 0.4, 1.0],
  );
  
  static const LinearGradient savannaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [savannaTan, saharaGold, baobabBrown],
    stops: [0.0, 0.5, 1.0],
  );
  
  // Background gradients
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [surfaceLight, surfaceVariant],
    stops: [0.0, 1.0],
  );
  
  static const LinearGradient darkBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [surfaceDark, Color(0xFF1B1B1B)],
    stops: [0.0, 1.0],
  );
  
  // Card gradients
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Colors.white, surfaceVariant],
    stops: [0.0, 1.0],
  );
  
  static const LinearGradient premiumCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Colors.white, Color(0xFFF8F9FA), surfaceVariant],
    stops: [0.0, 0.5, 1.0],
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        error: errorColor,
        surface: Colors.white,
        onSurface: const Color(0xFF1A1A1A),
      ),
      textTheme: GoogleFonts.poppinsTextTheme(
        const TextTheme(
          displayLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
          displayMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.25,
          ),
          displaySmall: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
          headlineLarge: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
          headlineMedium: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.15,
          ),
          headlineSmall: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.15,
          ),
          titleLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.15,
          ),
          titleMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
          ),
          titleSmall: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.normal,
            letterSpacing: 0.5,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            letterSpacing: 0.25,
          ),
          bodySmall: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.normal,
            letterSpacing: 0.4,
          ),
          labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
          ),
          labelMedium: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
          labelSmall: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: primaryColor,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: primaryColor,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: onPrimary,
          elevation: elevationS,
          shadowColor: primaryColor.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(horizontal: spacingL, vertical: spacingM),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusM),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: spacingL, vertical: spacingM),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusM),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: spacingM, vertical: spacingS),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusS),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            letterSpacing: 0.25,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: const BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: const BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: const BorderSide(color: errorColor, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: spacingM, vertical: spacingM),
        hintStyle: TextStyle(color: onSurfaceVariant.withOpacity(0.6)),
        labelStyle: const TextStyle(color: onSurface),
        floatingLabelStyle: const TextStyle(color: secondaryColor),
      ),
      cardTheme: CardThemeData(
        elevation: elevationS,
        shadowColor: primaryColor.withOpacity(0.1),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusL),
        ),
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.all(spacingS),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        elevation: 8,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: secondaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        primary: accentColor,
        secondary: secondaryColor,
        tertiary: primaryColor,
        error: errorColor,
        surface: const Color(0xFF1E1E1E),
        onSurface: Colors.white,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(
        ThemeData.dark().textTheme,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: accentColor,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.black,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[900],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[700]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[700]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: TextStyle(color: Colors.grey[400]),
        labelStyle: const TextStyle(color: Colors.white),
        floatingLabelStyle: const TextStyle(color: accentColor),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        color: const Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Color(0xFF1E1E1E),
        selectedItemColor: accentColor,
        unselectedItemColor: Colors.grey,
        elevation: 8,
      ),
    );
  }

  // Helper methods for context-aware drawer themes
  static LinearGradient getDrawerGradient(DrawerThemeMode mode) {
    switch (mode) {
      case DrawerThemeMode.emergency:
        return emergencyGradient;
      case DrawerThemeMode.professional:
        return professionalGradient;
      case DrawerThemeMode.night:
        return nightModeGradient;
      case DrawerThemeMode.normal:
      default:
        return africanSunsetGradient;
    }
  }

  static Color getDrawerTextColor(DrawerThemeMode mode) {
    switch (mode) {
      case DrawerThemeMode.emergency:
      case DrawerThemeMode.professional:
      case DrawerThemeMode.night:
        return Colors.white;
      case DrawerThemeMode.normal:
      default:
        return Colors.white;
    }
  }

  static List<Shadow> getDrawerTextShadows(DrawerThemeMode mode) {
    switch (mode) {
      case DrawerThemeMode.emergency:
      case DrawerThemeMode.professional:
        return [
          const Shadow(
            offset: Offset(0, 2),
            blurRadius: 4,
            color: Colors.black54,
          ),
        ];
      case DrawerThemeMode.night:
        return [
          const Shadow(
            offset: Offset(0, 1),
            blurRadius: 3,
            color: Colors.black87,
          ),
        ];
      case DrawerThemeMode.normal:
      default:
        return [
          const Shadow(
            offset: Offset(0, 2),
            blurRadius: 4,
            color: Colors.black45,
          ),
        ];
    }
  }
}

// Custom extension for theme context
extension ThemeExtension on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
}