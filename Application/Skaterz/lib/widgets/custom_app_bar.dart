
import 'package:flutter/material.dart';
import 'package:skaterz/core/app_theme.dart';
import 'package:skaterz/core/constants.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onMenuTap;
  final bool isDarkMode;
  final List<Widget>? actions;

  const CustomAppBar({
    super.key,
    required this.title,
    required this.onMenuTap,
    required this.isDarkMode,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: isDarkMode ? AppColors.primaryGradient : AppColors.oldGradient,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      leading: IconButton(
        icon: const Icon(Icons.menu, color: Colors.white),
        onPressed: onMenuTap,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
