/// LUÉN — dark luxury theme
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LuenColors {
  static const background    = Color(0xFF0F0F0F);
  static const surface       = Color(0xFF161616);
  static const surfaceAlt    = Color(0xFF1E1E1E);
  static const border        = Color(0xFF2A2A2A);
  static const foreground    = Color(0xFFEDEDED);
  static const mutedFg       = Color(0xFF8A8A8A);
  static const primary       = Color(0xFFD4A857); // gold
  static const primaryOn     = Color(0xFF0F0F0F);
  static const danger        = Color(0xFFB94F4F);
  static const success       = Color(0xFF6FA572);
}

ThemeData buildLuenTheme({Color? primaryOverride, Color? bgOverride}) {
  final primary = primaryOverride ?? LuenColors.primary;
  final bg      = bgOverride      ?? LuenColors.background;

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bg,
    colorScheme: ColorScheme.dark(
      primary: primary,
      onPrimary: LuenColors.primaryOn,
      secondary: primary,
      surface: LuenColors.surface,
      onSurface: LuenColors.foreground,
      error: LuenColors.danger,
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
      displayLarge:  GoogleFonts.playfairDisplay(fontSize: 48, color: LuenColors.foreground, letterSpacing: 1.0),
      headlineLarge: GoogleFonts.playfairDisplay(fontSize: 32, color: LuenColors.foreground),
      headlineMedium:GoogleFonts.playfairDisplay(fontSize: 24, color: LuenColors.foreground),
      titleLarge:    GoogleFonts.playfairDisplay(fontSize: 20, color: LuenColors.foreground),
    ).apply(bodyColor: LuenColors.foreground, displayColor: LuenColors.foreground),
    appBarTheme: AppBarTheme(
      backgroundColor: bg,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.playfairDisplay(fontSize: 18, color: LuenColors.foreground, letterSpacing: 4.0),
      iconTheme: const IconThemeData(color: LuenColors.foreground),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: LuenColors.surface,
      selectedItemColor: LuenColors.primary,
      unselectedItemColor: LuenColors.mutedFg,
      type: BottomNavigationBarType.fixed,
      showUnselectedLabels: true,
      selectedLabelStyle: TextStyle(fontSize: 10, letterSpacing: 2.0),
      unselectedLabelStyle: TextStyle(fontSize: 10, letterSpacing: 2.0),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: LuenColors.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(2), borderSide: const BorderSide(color: LuenColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(2), borderSide: BorderSide(color: primary)),
      labelStyle: const TextStyle(color: LuenColors.mutedFg, letterSpacing: 2.0, fontSize: 11),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: LuenColors.primaryOn,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(2))),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        textStyle: const TextStyle(fontSize: 12, letterSpacing: 4.0, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: LuenColors.foreground,
        side: const BorderSide(color: LuenColors.border),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(2))),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        textStyle: const TextStyle(fontSize: 12, letterSpacing: 4.0, fontWeight: FontWeight.w500),
      ),
    ),
    dividerColor: LuenColors.border,
  );
}
