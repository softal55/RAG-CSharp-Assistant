import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      primaryColor: Colors.blueAccent,
      scaffoldBackgroundColor: const Color(0xFF121212), // Deep dark background
      
      // Top AppBar styling
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      
      // Text Field styling (The chat input box)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        hintStyle: const TextStyle(color: Colors.grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
      
      // Color Scheme for Chat Bubbles and Icons
      colorScheme: ColorScheme.dark(
        primary: Colors.blueAccent,
        secondary: Colors.blue[300]!,
        surface: const Color(0xFF2A2A2A), // Bot bubble color
        onSurface: Colors.white,          // Text color on bot bubble
      ),
    );
  }
}