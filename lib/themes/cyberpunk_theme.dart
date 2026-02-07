import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CyberpunkTheme {
  static const Color backgroundBlack = Color(0xFF050505);
  static const Color neonCyan = Color(0xFF00F3FF);
  static const Color neonPink = Color(0xFFFF00FF);
  static const Color neonYellow = Color(0xFFFAFF00);
  static const Color glassWhite = Color(0x1AFFFFFF);
  static const Color textWhite = Color(0xFFE0E0E0);

  static ThemeData get theme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: neonCyan,
      scaffoldBackgroundColor: backgroundBlack,
      cardColor: const Color(0xFF101010),
      canvasColor: backgroundBlack,
      
      // Typography
      textTheme: TextTheme(
        displayLarge: GoogleFonts.orbitron(color: textWhite, fontWeight: FontWeight.bold),
        displayMedium: GoogleFonts.orbitron(color: textWhite, fontWeight: FontWeight.bold),
        displaySmall: GoogleFonts.orbitron(color: textWhite, fontWeight: FontWeight.bold),
        headlineLarge: GoogleFonts.orbitron(color: textWhite, fontWeight: FontWeight.bold),
        headlineMedium: GoogleFonts.orbitron(color: neonCyan, fontWeight: FontWeight.bold),
        headlineSmall: GoogleFonts.orbitron(color: textWhite, fontWeight: FontWeight.w600),
        titleLarge: GoogleFonts.rajdhani(color: textWhite, fontWeight: FontWeight.bold, fontSize: 20),
        titleMedium: GoogleFonts.rajdhani(color: textWhite, fontWeight: FontWeight.w600, fontSize: 18),
        titleSmall: GoogleFonts.rajdhani(color: Colors.grey, fontWeight: FontWeight.w500, fontSize: 16),
        bodyLarge: GoogleFonts.rajdhani(color: textWhite, fontSize: 16),
        bodyMedium: GoogleFonts.rajdhani(color: textWhite, fontSize: 14),
        bodySmall: GoogleFonts.rajdhani(color: Colors.grey, fontSize: 12),
      ),

      // App Bar
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.orbitron(
          color: neonCyan,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          shadows: [
            const Shadow(color: neonCyan, blurRadius: 10),
          ],
        ),
        iconTheme: const IconThemeData(color: neonCyan),
      ),

      // Bottom Navigation Bar
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: const Color(0xFF0A0A0A).withOpacity(0.9),
        selectedItemColor: neonCyan,
        unselectedItemColor: Colors.grey.withOpacity(0.5),
        selectedIconTheme: const IconThemeData(
          size: 30,
          shadows: [Shadow(color: neonCyan, blurRadius: 8)],
        ),
        unselectedIconTheme: const IconThemeData(size: 24),
        type: BottomNavigationBarType.fixed,
        elevation: 20,
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: const Color(0xFF121212),
        elevation: 5,
        shadowColor: neonCyan.withOpacity(0.4),
        shape: RoundedRectangleBorder(
          side: BorderSide(color: neonCyan.withOpacity(0.3), width: 1),
          borderRadius: BorderRadius.circular(4), // Slightly angular
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: neonCyan.withOpacity(0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: neonCyan.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(0), // Sharp on focus
          borderSide: const BorderSide(color: neonCyan, width: 2),
        ),
        hintStyle: GoogleFonts.rajdhani(color: Colors.grey),
        labelStyle: GoogleFonts.rajdhani(color: neonCyan),
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: neonCyan,
        size: 24,
      ),

      // Text Selection
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: neonPink,
        selectionColor: neonPink.withOpacity(0.3),
        selectionHandleColor: neonPink,
      ),

      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: neonPink,
        foregroundColor: textWhite,
        splashColor: neonCyan,
        elevation: 10,
        shape: const BeveledRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
      ),

      // Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: neonCyan,
        secondary: neonPink,
        surface: backgroundBlack,
        error: Colors.redAccent,
        onPrimary: Colors.black,
        onSecondary: Colors.white,
        onSurface: textWhite,
        onError: Colors.white,
      ),
    );
  }
}
