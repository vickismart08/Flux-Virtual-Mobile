import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color warmBeige = Color(0xFFF9F7F3);
  static const Color softOrange = Color(0xFFD97757);
  static const Color darkBrown = Color(0xFF3B2F2F);
  static const Color lightGray = Color(0xFFE5E7EB);
  static const Color white = Color(0xFFFFFFFF);

  static const Color darkBg = Color(0xFF1C1C1E);
  static const Color darkSurface = Color(0xFF2C2C2E);
  static const Color darkCard = Color(0xFF3A3A3C);
}


class ThemeNotifier extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;

  void setMode(ThemeMode mode) {
    _mode = mode;
    notifyListeners();
  }
}

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,

    scaffoldBackgroundColor: AppColors.warmBeige,

    textTheme: GoogleFonts.interTextTheme(
      const TextTheme(
        bodyLarge:  TextStyle(color: AppColors.darkBrown, fontSize: 16),
        bodyMedium: TextStyle(color: AppColors.darkBrown, fontSize: 14),
        headlineLarge:  TextStyle(color: AppColors.darkBrown, fontSize: 32, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: AppColors.darkBrown, fontSize: 24, fontWeight: FontWeight.w600),
      ),
    ),

    primaryTextTheme: GoogleFonts.interTextTheme().apply(
      bodyColor: AppColors.darkBrown,
      displayColor: AppColors.darkBrown,
    ),

    colorScheme: ColorScheme.light(
      primary: AppColors.softOrange,
      secondary: AppColors.darkBrown,
      surface: AppColors.white,
      background: AppColors.warmBeige,
      onPrimary: AppColors.white,
      onSecondary: AppColors.white,
      onSurface: AppColors.darkBrown,
      onBackground: AppColors.darkBrown,
       outline: AppColors.darkBrown,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.warmBeige,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(
        color: AppColors.darkBrown,
      ),
      titleTextStyle: TextStyle(
        color: AppColors.darkBrown,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.softOrange,
        foregroundColor: AppColors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppColors.lightGray,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppColors.lightGray,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppColors.softOrange,
          width: 2,
        ),
      ),
      hintStyle: const TextStyle(
        color: Colors.grey,
      ),
    ),

    cardTheme: CardThemeData(
      color: AppColors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
    ),

    dividerColor: AppColors.lightGray,
  );

   static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.darkBg,
    textTheme: GoogleFonts.interTextTheme(
      const TextTheme(
        bodyLarge:  TextStyle(color: AppColors.white, fontSize: 16),
        bodyMedium: TextStyle(color: AppColors.white, fontSize: 14),
        headlineLarge:  TextStyle(color: AppColors.white, fontSize: 32, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: AppColors.white, fontSize: 24, fontWeight: FontWeight.w600),
      ),
    ),

    primaryTextTheme: GoogleFonts.interTextTheme().apply(
      bodyColor: AppColors.white,
      displayColor: AppColors.white,
    ),
    colorScheme: ColorScheme.dark(
      primary: AppColors.softOrange,
      secondary: AppColors.softOrange,
      surface: AppColors.darkSurface,
      background: AppColors.darkBg,
      onPrimary: AppColors.white,
      onSecondary: AppColors.white,
      onSurface: AppColors.white,
      onBackground: AppColors.white,
      outline: AppColors.softOrange,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkBg,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: AppColors.white),
      titleTextStyle: TextStyle(
        color: AppColors.white,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.softOrange,
        foregroundColor: AppColors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.softOrange, width: 2),
      ),
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
    ),cardTheme: CardThemeData(
      color: AppColors.darkSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    dividerColor: Colors.white12,
  );
}