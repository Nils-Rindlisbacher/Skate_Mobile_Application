import 'package:flutter/material.dart';
import 'package:skaterz/core/app_theme.dart';
import 'package:skaterz/core/constants.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onMenuTap;
  final bool isDarkMode;
  final List<Widget>? actions;
  final bool isEmbedded; 
  final bool showMenuButton;
  final bool isExpanded;
  final bool isDesktop;

  const CustomAppBar({
    super.key,
    required this.title,
    required this.onMenuTap,
    required this.isDarkMode,
    this.actions,
    this.isEmbedded = false,
    this.showMenuButton = true,
    this.isExpanded = true,
    this.isDesktop = false,
  });

  @override
  Widget build(BuildContext context) {
    double leadingWidth = 56.0;
    Widget? leading;

    if (showMenuButton) {
      if (isDesktop) {
        leadingWidth = isExpanded ? 320 : 100;
        leading = Container(
          width: leadingWidth,
          alignment: isExpanded ? Alignment.centerLeft : Alignment.center,
          padding: isExpanded ? const EdgeInsets.only(left: 24.0) : EdgeInsets.zero,
          child: IconButton(
            icon: Icon(Icons.menu, color: Colors.white, size: isExpanded ? 24 : 26),
            onPressed: onMenuTap,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(), // Removes extra padding/constraints
            alignment: isExpanded ? Alignment.centerLeft : Alignment.center,
            splashRadius: 24,
          ),
        );
      } else {
        // Mobile alignment: matches SideMenu's ListTile horizontal padding of 24
        leadingWidth = 72;
        leading = Container(
          width: 72,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 24.0),
          child: IconButton(
            icon: const Icon(Icons.menu, color: Colors.white, size: 24),
            onPressed: onMenuTap,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            alignment: Alignment.centerLeft,
            splashRadius: 24,
          ),
        );
      }
    }

    final Widget appBarBody = AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false, // Ensure we have full control over the leading area
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: isDarkMode ? AppColors.primaryGradient : AppColors.oldGradient,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      leadingWidth: leadingWidth,
      leading: leading,
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
