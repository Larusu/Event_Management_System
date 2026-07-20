import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get light {
    const colorScheme = ColorScheme.light(
      primary: Color(0xFF00364D),
      error: Colors.red,
      surface: Colors.white,
      onSurface: Colors.black,
      onPrimary: Colors.white,
      onSurfaceVariant: Colors.grey,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter',
      colorScheme: colorScheme,
      textTheme: TextTheme(
        titleMedium: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
        ),
        bodySmall: const TextStyle(
          fontSize: 12,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          color: colorScheme.onSurfaceVariant,
        ),
        bodyMedium: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w300,
        ),
      ),
    );
  }

  static ThemeData get dark {
    const colorScheme = ColorScheme.dark(
      primary: Color(0xFF4DA6C9),
      error: Color(0xFFEF5350),
      surface: Color(0xFF121212),
      onSurface: Colors.white,
      onPrimary: Colors.white,
      onSurfaceVariant: Color(0xFFB0B0B0),
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter',
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF121212),
      cardTheme: const CardThemeData(
        color: Color(0xFF1E1E1E),
      ),
      textTheme: TextTheme(
        titleMedium: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: colorScheme.onSurface,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          color: colorScheme.onSurfaceVariant,
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w300,
          color: colorScheme.onSurface,
        ),
      ),
    );
  }
}
