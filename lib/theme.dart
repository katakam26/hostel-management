import 'package:flutter/material.dart';

/// Central app theme so every screen shares the same look.
class AppTheme {
  static ThemeData get light => ThemeData(
        colorSchemeSeed: const Color(0xFF3D5AFE),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          ),
        ),
      );
}
