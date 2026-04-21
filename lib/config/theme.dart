import 'package:flutter/material.dart';

/// SnackBars after async work (e.g. image picker) without unsafe [BuildContext] ancestor lookup.
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class AppTheme {
  // Primary colors
  static const Color primaryColor = Color(0xFF2196F3);
  static const Color primaryLight = Color(0xFF64B5F6);
  static const Color primaryDark = Color(0xFF1976D2);

  // Accent colors
  static const Color accentColor = Color(0xFF00BCD4);
  static const Color likeColor = Color(0xFFF44336);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFFC107);
  static const Color errorColor = Color(0xFFF44336);

  // Neutral colors
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color dividerColor = Color(0xFFE0E0E0);

  /// Home live 2D — teal / indigo / violet (distinct from generic lottery orange slabs).
  static const Color brandLiveCardSurface = Color(0xFFFFFFFF);
  static const Color brandLiveCardBorder = Color(0xFFCBD5E1);
  static const Color brandLiveCardShadow = Color(0x140F172A);

  static const Color brandLiveHeaderStart = Color(0xFF0D9488);
  static const Color brandLiveHeaderEnd = Color(0xFF4F46E5);
  static const Color brandLiveHeaderStartAlt = Color(0xFF6366F1);
  static const Color brandLiveHeaderEndAlt = Color(0xFF9333EA);

  static const Color brandLiveBadgeBg = Color(0xFF0F766E);
  static const Color brandLiveBadgeFg = Color(0xFFFFFFFF);

  static const Color brandHeroDigit = Color(0xFF0F766E);
  static const Color brandHeroCanvas = Color(0xFFF8FAFC);
  static const Color brandMarketMicroDigit = Color(0xFF115E59);

  static const Color brandFeedCta = Color(0xFF2563EB);
  static const Color brandPlayCta = Color(0xFF0D9488);

  static List<Color> brandLiveHeaderGradientColors(bool alternate) => alternate
      ? [brandLiveHeaderStartAlt, brandLiveHeaderEndAlt]
      : [brandLiveHeaderStart, brandLiveHeaderEnd];

  // Spacing
  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 12.0;
  static const double paddingL = 16.0;
  static const double paddingXL = 24.0;

  // Border radius
  static const double radiusS = 4.0;
  static const double radiusM = 8.0;
  static const double radiusL = 12.0;
  static const double radiusXL = 16.0;

  // Icon sizes
  static const double iconS = 16.0;
  static const double iconM = 20.0;
  static const double iconL = 24.0;

  // Avatar sizes
  static const double avatarS = 32.0;
  static const double avatarM = 40.0;
  static const double avatarL = 56.0;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: accentColor,
        error: errorColor,
        background: backgroundColor,
        surface: cardColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      cardColor: cardColor,
      dividerColor: dividerColor,
      
      appBarTheme: const AppBarTheme(
        backgroundColor: cardColor,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
      
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textPrimary),
        displayMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: textPrimary),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: textPrimary),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: textSecondary),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cardColor),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: cardColor,
          padding: const EdgeInsets.symmetric(horizontal: paddingXL, vertical: paddingM),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusM),
          ),
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: backgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: paddingL,
          vertical: paddingM,
        ),
      ),
      
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusM),
        ),
      ),
    );
  }
}
