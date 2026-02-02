import 'package:flutter/material.dart';

class AppColors {
  // Old Colors (For Bright/Light Mode)
  static const Color primaryOld = Color(0xFF004D40);
  static const Color secondaryOld = Color(0xFF00FF88);
  
  // New Brand Colors (For Dark Mode - Cozy & Chill)
  static const Color primary = Color(0xFFF57C00); // Vibrant Orange
  static const Color primaryDark = Color(0xFFE65100); 
  static const Color secondary = Color(0xFFFFB74D); // Soft Peach/Amber
  
  static const Color backgroundLight = Color(0xFFF5F5F5); // Clean light grey
  static const Color backgroundDark = Color(0xFF121212); // Soft Black
  static const Color surfaceDark = Color(0xFF1E1E1E); 
  
  static const Color textDark = Color(0xFF2D2D2D);
  static const Color textLight = Color(0xFFF5F5F5);

  // Default Gradients (Used in Dark Mode)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFF57C00), Color(0xFFFFB74D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Old Gradients (Used in Light Mode)
  static const LinearGradient oldGradient = LinearGradient(
    colors: [Color(0xFF002211), Color(0xFF004D40), Color(0xFF00FF88)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
