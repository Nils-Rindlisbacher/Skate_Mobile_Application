import 'package:flutter/material.dart';

class AppColors {
  // Default values
  static Color primaryOld = const Color(0xFF004D40);
  static Color secondaryOld = const Color(0xFF00FF88);
  
  static Color primary = const Color(0xFFF57C00); 
  static Color primaryDark = const Color(0xFFE65100); 
  static Color secondary = const Color(0xFFFFB74D); 
  
  static Color sidebarTop = const Color(0xFFFFB74D);
  static Color sidebarBottom = const Color(0xFFF57C00);

  static const Color backgroundLight = Color(0xFFF5F5F5); 
  static const Color backgroundDark = Color(0xFF121212); 
  static const Color surfaceDark = Color(0xFF1E1E1E); 
  
  static const Color textDark = Color(0xFF2D2D2D);
  static const Color textLight = Color(0xFFF5F5F5);
  static const Color success = Color(0xFF66BB6A);

  static LinearGradient getDynamicGradient(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? primaryGradient : oldGradient;
  }

  static Color getDynamicPrimary(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? primary : primaryOld;
  }

  static LinearGradient get primaryGradient => LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get oldGradient => LinearGradient(
    colors: [primaryOld, secondaryOld],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static LinearGradient getSidebarGradient(bool isDarkMode) {
    return LinearGradient(
      colors: [sidebarTop, sidebarBottom],
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
    );
  }
}
