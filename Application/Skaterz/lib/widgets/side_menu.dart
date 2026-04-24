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
    return Container(
      width: isDesktop ? (isExpanded ? 300 : 80) : null,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          if (isDesktop)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(2, 0),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
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

                  _buildLanguageExpansion(),

                  // Dark Mode Switch - Now clickable even when collapsed
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: isExpanded || !isDesktop ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
                      children: [
                        InkWell(
                          onTap: () => onThemeToggle(!isDarkMode),
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Icon(
                              isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded, 
                              color: isDarkMode ? AppColors.primary : AppColors.primaryOld,
                              size: 24,
                            ),
                          ),
                        ),
                        if (isExpanded || !isDesktop)
                          Switch(
                            value: isDarkMode,
                            onChanged: onThemeToggle,
                            activeColor: AppColors.primary,
                            inactiveThumbColor: AppColors.primaryOld,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (isExpanded || !isDesktop)
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  "© 2024 SKATERZ",
                  style: TextStyle(color: Colors.grey.withOpacity(0.5), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final String? base64String = userData?['profile_image'] ?? userData?['profileImage'];
    final bool hasImage = base64String != null && base64String.isNotEmpty;
    final Color textColor = isDarkMode ? Colors.white : Colors.black87;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 60, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          if (isExpanded || !isDesktop) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: isDarkMode ? AppColors.primary.withOpacity(0.3) : AppColors.primaryOld.withOpacity(0.3), width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.grey.withOpacity(0.1),
                      backgroundImage: hasImage ? MemoryImage(const Base64Decoder().convert(base64String)) : null,
                      child: !hasImage ? Icon(Icons.person_rounded, size: 30, color: isDarkMode ? AppColors.primary : AppColors.primaryOld) : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isLoggedIn ? (userData?['name'] ?? localizations.guest) : localizations.guest,
                    style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  if (isLoggedIn && userData?['username'] != null)
                    Text(
                      '@${userData?['username']}',
                      style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 12),
                    ),
                ],
              ),
            ),
          ] else if (isDesktop)
            Center(
              child: Icon(Icons.person_outline_rounded, color: isDarkMode ? AppColors.primary : AppColors.primaryOld, size: 28),
            ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    final Color iconColor = isDarkMode ? AppColors.primary : AppColors.primaryOld;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      leading: Icon(icon, color: iconColor, size: 24),
      title: (isExpanded || !isDesktop) ? Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)) : null,
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
        title: Text(localizations.language, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        children: <Widget>[
          _buildLanguageOption('🇩🇪', localizations.german, 'de'),
          _buildLanguageOption('🇬🇧', localizations.english, 'en'),
          _buildLanguageOption('🇪🇸', localizations.spanish, 'es'),
          _buildLanguageOption('🇮🇹', localizations.italian, 'it'),
          _buildLanguageOption('🇫🇷', localizations.french, 'fr'),
        ],
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _buildLanguageOption(String flag, String name, String locale) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 48, right: 24),
      title: Text('$flag  $name', style: const TextStyle(fontSize: 13)),
      onTap: () => onLanguageChange(locale),
    );
  }
}
