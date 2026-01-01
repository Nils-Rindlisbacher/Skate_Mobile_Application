import 'package:flutter/material.dart';

class AppColors {
  // Primary colors based on Session Goals page
  static const Color primaryDark = Color(0xFF002211);
  static const Color primary = Color(0xFF004D40);
  static const Color secondary = Color(0xFF00FF88); // Session Goals accent mint
  
  static const Color surfaceDark = Color(0xFF122626);
  static const Color backgroundDark = Color(0xFF0A1212);
  
  // Updated Gradients to match Session Goals Page exactly
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryDark, primary, secondary],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient reverseGradient = LinearGradient(
    colors: [secondary, primary, primaryDark],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
