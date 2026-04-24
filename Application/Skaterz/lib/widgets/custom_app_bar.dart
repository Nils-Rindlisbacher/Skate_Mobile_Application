import 'package:flutter/material.dart';
import 'package:skaterz/core/app_theme.dart';
import 'package:skaterz/core/constants.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onMenuTap;
  final bool isDarkMode;
  final List<Widget>? actions;
  final bool isEmbedded; 
  final bool showMenuButton; // New property to toggle menu button visibility

  const CustomAppBar({
    super.key,
    required this.title,
    required this.onMenuTap,
    required this.isDarkMode,
    this.actions,
    this.isEmbedded = false,
    this.showMenuButton = true, // Default to true for mobile
  });

  @override
  Widget build(BuildContext context) {
    final Widget appBarBody = AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: isDarkMode ? AppColors.primaryGradient : AppColors.oldGradient,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      leading: showMenuButton 
          ? IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: onMenuTap,
            )
          : null, // Hide if not needed (e.g., on Desktop where it's in the Sidebar)
      iconTheme: const IconThemeData(color: Colors.white),
      actions: actions,
    );

    if (!isEmbedded) return appBarBody;

    return Container(
      decoration: BoxDecoration(
        gradient: isDarkMode ? AppColors.primaryGradient : AppColors.oldGradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: appBarBody,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
