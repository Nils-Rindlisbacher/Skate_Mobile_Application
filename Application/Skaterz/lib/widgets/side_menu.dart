import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:skaterz/l10n/app_localizations.dart';
import 'package:skaterz/core/constants.dart';

class SideMenu extends StatelessWidget {
  const SideMenu({
    super.key,
    required this.localizations,
    required this.isLoggedIn,
    required this.onProfileTap,
    required this.onProgressTap,
    required this.onLeaderboardTap,
    required this.onTrickListTap,
    required this.onFriendsTap,
    required this.onSessionGoalsTap,
    required this.onEquipmentTap,
    required this.onSettingsTap,
    required this.onLanguageChange,
    required this.isDarkMode,
    required this.onThemeToggle,
    this.userData,
    this.isExpanded = true,
    this.isDesktop = false,
    this.onToggleMenu,
  });

  final AppLocalizations localizations;
  final bool isLoggedIn;
  final Map<String, dynamic>? userData;
  final VoidCallback onProfileTap;
  final VoidCallback onProgressTap;
  final VoidCallback onLeaderboardTap;
  final VoidCallback onTrickListTap;
  final VoidCallback onFriendsTap;
  final VoidCallback onSessionGoalsTap;
  final VoidCallback onEquipmentTap;
  final VoidCallback onSettingsTap;
  final Function(String) onLanguageChange;
  final bool isDarkMode;
  final Function(bool) onThemeToggle;
  final bool isExpanded;
  final bool isDesktop;
  final VoidCallback? onToggleMenu;

  void _onTileTap(BuildContext context, VoidCallback originalOnTap) {
    if (!isDesktop) {
      Navigator.pop(context);
    }
    originalOnTap();
  }

  @override
  Widget build(BuildContext context) {
    final double headerHeight = isDesktop && !isExpanded ? kToolbarHeight : 240.0;

    return Drawer(
      elevation: 0,
      width: isDesktop ? (isExpanded ? 280 : 80) : null,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          _buildHeader(context, headerHeight),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: <Widget>[
                _buildMenuItem(context, Icons.person_outline_rounded, localizations.profileMenuItem, onProfileTap),
                _buildMenuItem(context, Icons.analytics_outlined, localizations.progressTrackerMenuItem, onProgressTap),
                _buildMenuItem(context, Icons.emoji_events_outlined, localizations.leaderboardMenuItem, onLeaderboardTap),
                _buildMenuItem(context, Icons.people_outline_rounded, localizations.friends, onFriendsTap),
                _buildMenuItem(context, Icons.format_list_bulleted_rounded, localizations.trickListMenuItem, onTrickListTap),
                _buildMenuItem(context, Icons.ads_click_rounded, localizations.sessionGoalsMenuItem, onSessionGoalsTap),
                _buildMenuItem(context, Icons.construction_outlined, localizations.equipmentMenuItem, onEquipmentTap),
                _buildMenuItem(context, Icons.settings_outlined, localizations.settingsMenuItem, onSettingsTap),
                
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Divider(height: 1, thickness: 0.5),
                ),

                if (isExpanded || !isDesktop)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: SwitchListTile(
                      secondary: Icon(isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded, color: isDarkMode ? AppColors.primary : AppColors.primaryOld),
                      title: Text(localizations.darkMode, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      value: isDarkMode,
                      onChanged: onThemeToggle,
                      activeColor: isDarkMode ? AppColors.primary : AppColors.primaryOld,
                    ),
                  )
                else
                  IconButton(
                    icon: Icon(isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded, color: isDarkMode ? AppColors.primary : AppColors.primaryOld),
                    onPressed: () => onThemeToggle(!isDarkMode),
                  ),

                _buildLanguageExpansion(),
              ],
            ),
          ),
          if (isExpanded || !isDesktop)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                "© 2024 SKATERZ",
                style: TextStyle(color: Colors.grey.withValues(alpha: 0.5), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, double height) {
    return InkWell(
      onTap: () {
        if (isDesktop) {
          onToggleMenu?.call();
        } else {
          Navigator.pop(context);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          // SWITCHED ORIENTATION: bottomCenter to topCenter instead of topLeft to bottomRight
          gradient: LinearGradient(
            colors: isDarkMode ? [Color(0xFFFFB74D), Color(0xFFF57C00)] : [Color(0xFF00FF88), Color(0xFF002211)],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
          borderRadius: BorderRadius.zero,
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isExpanded || !isDesktop) ...[
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                  child: _buildUserAvatar(size: 40),
                ),
                const SizedBox(height: 16),
                Text(
                  isLoggedIn ? (userData?['name'] ?? '') : localizations.guest,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20),
                ),
                if (isLoggedIn)
                  Text(
                    '@${userData?['username'] ?? ''}',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
                  ),
              ] else 
                const Icon(Icons.menu_rounded, color: Colors.white, size: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserAvatar({double size = 30}) {
    if (isLoggedIn) {
      final img = userData?['profile_image'] ?? userData?['profileImage'];
      if (img != null) {
        return CircleAvatar(
          radius: size,
          backgroundImage: MemoryImage(base64Decode(img)),
        );
      }
    }
    return CircleAvatar(
      radius: size,
      backgroundColor: Colors.white12,
      child: Icon(Icons.person_rounded, size: size * 1.2, color: Colors.white),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    final Color iconColor = isDarkMode ? AppColors.primary : AppColors.primaryOld;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      leading: Icon(icon, color: iconColor, size: 24),
      title: (isExpanded || !isDesktop) ? Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)) : null,
      onTap: () => _onTileTap(context, onTap),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildLanguageExpansion() {
    final Color iconColor = isDarkMode ? AppColors.primary : AppColors.primaryOld;
    if (isExpanded || !isDesktop) {
      return ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 24),
        leading: Icon(Icons.language_rounded, color: iconColor),
        title: Text(localizations.language, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        children: <Widget>[
          _buildLanguageOption('🇩🇪', localizations.german, 'de'),
          _buildLanguageOption('🇬🇧', localizations.english, 'en'),
          _buildLanguageOption('🇪🇸', localizations.spanish, 'es'),
          _buildLanguageOption('🇮🇹', localizations.italian, 'it'),
          _buildLanguageOption('🇫🇷', localizations.french, 'fr'),
        ],
      );
    } else {
      return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 24),
        leading: Icon(Icons.language_rounded, color: iconColor),
        onTap: onToggleMenu,
      );
    }
  }

  Widget _buildLanguageOption(String flag, String name, String locale) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 48, right: 24),
      title: Text('$flag  $name', style: const TextStyle(fontSize: 14)),
      onTap: () => onLanguageChange(locale),
    );
  }
}
