import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors (Cool & Modern Agricultural Palette)
  static const Color primaryLight = Color(0xFF1B5E20);      // Deep forest green
  static const Color primaryLightContainer = Color(0xFFC8E6C9); // Soft green highlight
  static const Color secondaryLight = Color(0xFF00897B);    // Cool teal green
  static const Color accentWarning = Color(0xFFE65100);     // Modern alert orange (hama)
  static const Color backgroundLight = Color(0xFFF6F8F6);    // Cool grayish off-white
  static const Color surfaceLight = Color(0xFFFFFFFF);       // Clean white
  static const Color textDark = Color(0xFF1E293B);           // Slate dark blue/gray for text
  static const Color textLightMuted = Color(0xFF64748B);     // Muted slate gray
  static const Color errorColor = Color(0xFFE11D48);         // Vibrant modern rose/red
  static const Color successColor = Color(0xFF16A34A);       // Modern green success

  // Dark Mode Colors
  static const Color primaryDark = Color(0xFF4CAF50);
  static const Color primaryDarkContainer = Color(0xFF1B5E20);
  static const Color secondaryDark = Color(0xFF26A69A);
  static const Color backgroundDark = Color(0xFF0F172A);     // Slate 900
  static const Color surfaceDark = Color(0xFF1E293B);        // Slate 800
  static const Color textLight = Color(0xFFF8FAFC);          // Slate 50
  static const Color textDarkMuted = Color(0xFF94A3B8);      // Slate 400

  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryLight,
      colorScheme: const ColorScheme.light(
        primary: primaryLight,
        onPrimary: Colors.white,
        primaryContainer: primaryLightContainer,
        secondary: secondaryLight,
        onSecondary: Colors.white,
        surface: surfaceLight,
        onSurface: textDark,
        error: errorColor,
        onError: Colors.white,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: backgroundLight,
      textTheme: GoogleFonts.poppinsTextTheme(
        ThemeData.light().textTheme.copyWith(
          displayLarge: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 32),
          titleLarge: TextStyle(color: textDark, fontWeight: FontWeight.w600, fontSize: 20),
          titleMedium: TextStyle(color: textDark, fontWeight: FontWeight.w500, fontSize: 16),
          bodyLarge: TextStyle(color: textDark, fontSize: 16),
          bodyMedium: TextStyle(color: textLightMuted, fontSize: 14),
          labelLarge: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textDark),
        titleTextStyle: TextStyle(
          color: textDark,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceLight,
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.04),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryLight,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryLight,
          side: const BorderSide(color: primaryLight, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor),
        ),
        labelStyle: TextStyle(color: textLightMuted, fontFamily: 'Poppins'),
        hintStyle: TextStyle(color: textLightMuted.withOpacity(0.6), fontFamily: 'Poppins'),
      ),
    );
  }

  // Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryDark,
      colorScheme: const ColorScheme.dark(
        primary: primaryDark,
        onPrimary: Colors.black,
        primaryContainer: primaryDarkContainer,
        secondary: secondaryDark,
        onSecondary: Colors.black,
        surface: surfaceDark,
        onSurface: textLight,
        error: errorColor,
        onError: Colors.black,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: backgroundDark,
      textTheme: GoogleFonts.poppinsTextTheme(
        ThemeData.dark().textTheme.copyWith(
          displayLarge: TextStyle(color: textLight, fontWeight: FontWeight.bold, fontSize: 32),
          titleLarge: TextStyle(color: textLight, fontWeight: FontWeight.w600, fontSize: 20),
          titleMedium: TextStyle(color: textLight, fontWeight: FontWeight.w500, fontSize: 16),
          bodyLarge: TextStyle(color: textLight, fontSize: 16),
          bodyMedium: TextStyle(color: textDarkMuted, fontSize: 14),
          labelLarge: TextStyle(color: textLight, fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textLight),
        titleTextStyle: TextStyle(
          color: textLight,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceDark,
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryDark,
          foregroundColor: Colors.black,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryDark,
          side: const BorderSide(color: primaryDark, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white10),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryDark, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor),
        ),
        labelStyle: TextStyle(color: textDarkMuted, fontFamily: 'Poppins'),
        hintStyle: TextStyle(color: textDarkMuted.withOpacity(0.6), fontFamily: 'Poppins'),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: surfaceDark,
        surfaceTintColor: Colors.transparent,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: surfaceDark,
        headerBackgroundColor: backgroundDark,
        headerForegroundColor: textLight,
        surfaceTintColor: Colors.transparent,
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryDark;
          return null;
        }),
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return textLight;
        }),
        yearForegroundColor: WidgetStateProperty.all(textLight),
        weekdayStyle: const TextStyle(color: textDarkMuted),
        cancelButtonStyle: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(primaryDark),
        ),
        confirmButtonStyle: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(primaryDark),
        ),
      ),
    );
  }
}
