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
    // Profi-Fix: Weiten exakt an Sidebar anpassen für nahtlosen Übergang
    double leadingWidth = isDesktop ? (isExpanded ? 280 : 72) : 72;
    Widget? leading;

    if (showMenuButton) {
      leading = Container(
        width: leadingWidth,
        // Profi-Fix: Button bleibt IMMER an der gleichen Position (24px vom Rand)
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24.0),
        child: IconButton(
          icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 24),
          onPressed: onMenuTap,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          splashRadius: 24,
        ),
      );
    }

    final Widget appBarBody = AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
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
