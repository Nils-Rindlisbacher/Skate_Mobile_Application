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
    final double headerHeight = isDesktop && !isExpanded ? kToolbarHeight : 200.0;

    return Drawer(
      elevation: 0,
      width: isDesktop ? (isExpanded ? 250 : 80) : null,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          _buildHeader(context, headerHeight),
          const SizedBox(height: 8),
          _buildMenuItem(context, Icons.person, localizations.profileMenuItem, onProfileTap),
          _buildMenuItem(context, Icons.list_alt, localizations.trickListMenuItem, onTrickListTap),
          _buildMenuItem(context, Icons.trending_up, localizations.progressTrackerMenuItem, onProgressTap),
          _buildMenuItem(context, Icons.emoji_events, localizations.leaderboardMenuItem, onLeaderboardTap),
          _buildMenuItem(context, Icons.track_changes, localizations.sessionGoalsMenuItem, onSessionGoalsTap),
          _buildMenuItem(context, Icons.handyman, localizations.equipmentMenuItem, onEquipmentTap),
          _buildMenuItem(context, Icons.settings, localizations.settingsMenuItem, onSettingsTap),
          
          const Divider(height: 1),

          // Dark Mode Switch in Side Menu (Moved down to be over language selection)
          if (isExpanded || !isDesktop)
            SwitchListTile(
              secondary: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode, color: AppColors.primary),
              title: Text(localizations.darkMode),
              value: isDarkMode,
              onChanged: onThemeToggle,
              activeColor: AppColors.primary,
            )
          else
            IconButton(
              icon: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode, color: AppColors.primary),
              onPressed: () => onThemeToggle(!isDarkMode),
            ),

          _buildLanguageExpansion(),
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
      splashColor: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: height,
        padding: EdgeInsets.symmetric(
          vertical: isDesktop && !isExpanded ? 0 : 20,
          horizontal: isExpanded ? 16 : 0,
        ).copyWith(top: isDesktop && !isExpanded ? 0 : 40),
        decoration: BoxDecoration(
          borderRadius: (isDesktop && isExpanded)
              ? const BorderRadius.only(bottomRight: Radius.circular(40))
              : BorderRadius.zero,
          gradient: AppColors.reverseGradient,
        ),
        child: ClipRect(
          child: OverflowBox(
            minHeight: 0,
            maxHeight: 200,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isExpanded || !isDesktop) _buildUserAvatar(),
                if (isExpanded || !isDesktop) ...[
                  const SizedBox(height: 16),
                  Text(
                    isLoggedIn ? (userData?['name'] ?? '') : localizations.guest,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  if (isLoggedIn)
                    Text(
                      '@${userData?['username'] ?? ''}',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                    ),
                ],
                if (isDesktop && !isExpanded) const Icon(Icons.menu, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserAvatar() {
    if (isLoggedIn) {
      final img = userData?['profile_image'] ?? userData?['profileImage'];
      if (img != null) {
        return CircleAvatar(
          radius: 30,
          backgroundImage: MemoryImage(base64Decode(img)),
        );
      }
    }
    return const CircleAvatar(
      radius: 30,
      backgroundColor: Colors.white24,
      child: Icon(Icons.person, size: 35, color: Colors.white),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Padding(
        padding: isExpanded ? EdgeInsets.zero : const EdgeInsets.only(left: 12),
        child: Icon(icon, color: AppColors.primary),
      ),
      title: (isExpanded || !isDesktop) ? Text(title) : null,
      onTap: () => _onTileTap(context, onTap),
    );
  }

  Widget _buildLanguageExpansion() {
    if (isExpanded || !isDesktop) {
      return ExpansionTile(
        leading: const Icon(Icons.language, color: AppColors.primary),
        title: Text(localizations.language),
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
        leading: const Padding(
          padding: EdgeInsets.only(left: 12),
          child: Icon(Icons.language, color: AppColors.primary),
        ),
        onTap: onToggleMenu,
      );
    }
  }

  Widget _buildLanguageOption(String flag, String name, String locale) {
    return ListTile(
      title: Text('$flag  $name'),
      onTap: () => onLanguageChange(locale),
    );
  }
}
