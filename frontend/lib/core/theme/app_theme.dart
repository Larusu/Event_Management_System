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
}
