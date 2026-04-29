import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:skaterz/l10n/app_localizations.dart';

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
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: isDesktop ? (isExpanded ? 320 : 100) : null,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          if (isDesktop)
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.05),
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
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Divider(height: 1, thickness: 0.5, color: colorScheme.outline),
                  ),

                  _buildLanguageExpansion(context),

                  // Dark Mode Toggle - Integrated into menu list for perfect alignment
                  _buildMenuItem(
                    context, 
                    isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded, 
                    localizations.darkMode, 
                    () => onThemeToggle(!isDarkMode)
                  ),
                ],
              ),
            ),
            if (isExpanded || !isDesktop)
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  "© 2024 SKATERZ",
                  style: TextStyle(color: colorScheme.onSurface.withOpacity(0.3), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    if (isDesktop && !isExpanded) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final String? base64String = userData?['profile_image'] ?? userData?['profileImage'];
    final bool hasImage = base64String != null && base64String.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 60, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: colorScheme.primary.withOpacity(0.3), width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: colorScheme.onSurface.withOpacity(0.05),
                    backgroundImage: hasImage 
                        ? MemoryImage(const Base64Decoder().convert(base64String)) 
                        : const AssetImage('assets/Default_Profile_Pic.png') as ImageProvider,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  isLoggedIn ? (userData?['name'] ?? localizations.guest) : localizations.guest,
                  style: TextStyle(color: colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                if (isLoggedIn && userData?['username'] != null)
                  Text(
                    '@${userData?['username']}',
                    style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6), fontSize: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // If collapsed on desktop, center the icon
    if (isDesktop && !isExpanded) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Tooltip(
          message: title,
          child: InkWell(
            onTap: () => _onTileTap(context, onTap),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 48,
              width: double.infinity,
              child: Center(
                child: Icon(icon, color: colorScheme.primary, size: 26),
              ),
            ),
          ),
        ),
      );
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      leading: Icon(icon, color: colorScheme.primary, size: 24),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: colorScheme.onSurface)),
      onTap: () => _onTileTap(context, onTap),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildLanguageExpansion(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (isExpanded || !isDesktop) {
      return ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 24),
        leading: Icon(Icons.language_rounded, color: colorScheme.primary),
        title: Text(localizations.language, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: colorScheme.onSurface)),
        children: <Widget>[
          _buildLanguageOption(context, '🇩🇪', localizations.german, 'de'),
          _buildLanguageOption(context, '🇬🇧', localizations.english, 'en'),
          _buildLanguageOption(context, '🇪🇸', localizations.spanish, 'es'),
          _buildLanguageOption(context, '🇮🇹', localizations.italian, 'it'),
          _buildLanguageOption(context, '🇫🇷', localizations.french, 'fr'),
        ],
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _buildLanguageOption(BuildContext context, String flag, String name, String locale) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 48, right: 24),
      title: Text('$flag  $name', style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface)),
      onTap: () => onLanguageChange(locale),
    );
  }
}
