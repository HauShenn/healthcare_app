// theme_constants.dart

import 'package:flutter/material.dart';

class ThemeConstants {
  // Font Sizes
  static const double headerSize = 32.0;
  static const double titleSize = 28.0;
  static const double subtitleSize = 24.0;
  static const double bodySize = 20.0;

  // Icon Sizes
  static const double iconLarge = 40.0;
  static const double iconMedium = 32.0;
  static const double iconSmall = 24.0;

  // Spacing
  static const double spacingLarge = 24.0;
  static const double spacingMedium = 16.0;
  static const double spacingSmall = 12.0;

  // Colors
  static MaterialColor primaryTeal = Colors.teal;

  // Gradients
  static LinearGradient mainGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.teal.shade700, Colors.teal.shade50],
  );

  // Card Styles
  static BoxDecoration cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 10,
        offset: Offset(0, 4),
      ),
    ],
  );

  // Text Styles
  static TextStyle headerStyle = TextStyle(
    fontSize: headerSize,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static TextStyle titleStyle = TextStyle(
    fontSize: titleSize,
    fontWeight: FontWeight.bold,
    color: Colors.teal.shade800,
  );

  static TextStyle subtitleStyle = TextStyle(
    fontSize: subtitleSize,
    color: Colors.teal.shade700,
  );

  static TextStyle bodyStyle = TextStyle(
    fontSize: bodySize,
    color: Colors.grey.shade800,
  );

  // Button Styles
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.teal.shade600,
    foregroundColor: Colors.white,
    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15),
    ),
    textStyle: TextStyle(
      fontSize: subtitleSize,
      fontWeight: FontWeight.bold,
    ),
  );
}