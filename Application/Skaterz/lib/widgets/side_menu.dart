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
    required this.onSessionGoalsTap,
    required this.onSettingsTap,
    required this.onLanguageChange,
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
  final VoidCallback onSettingsTap;
  final Function(String) onLanguageChange;
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
    // Standard height for AppBar in Flutter is kToolbarHeight
    final double headerHeight = isDesktop && !isExpanded ? kToolbarHeight : 200.0;

    return Drawer(
      elevation: 0,
      width: isDesktop ? (isExpanded ? 250 : 80) : null,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          InkWell(
            onTap: () {
              if (isDesktop) {
                onToggleMenu?.call();
              } else {
                Navigator.pop(context);
              }
            },
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: headerHeight,
              padding: EdgeInsets.only(
                top: isDesktop && !isExpanded ? 0 : 40,
                bottom: isDesktop && !isExpanded ? 0 : 20,
                left: isExpanded ? 16 : 0,
                right: isExpanded ? 16 : 0
              ),
              decoration: BoxDecoration(
                borderRadius: (isDesktop && isExpanded)
                    ? const BorderRadius.only(bottomRight: Radius.circular(40))
                    : BorderRadius.zero,
                gradient: const LinearGradient(
                  // Side Menu: Black on the RIGHT
                  colors: [Color(0xFF00FF88), Color(0xFF004D40), Color(0xFF002211)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: ClipRect(
                child: OverflowBox(
                  minHeight: 0,
                  maxHeight: 200,
                  alignment: Alignment.center,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isExpanded || !isDesktop)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isLoggedIn)
                              if (userData?['profile_image'] != null || userData?['profileImage'] != null)
                                CircleAvatar(
                                  radius: 30,
                                  backgroundImage: MemoryImage(
                                    base64Decode(userData?['profile_image'] ?? userData?['profileImage']),
                                  ),
                                )
                              else
                                const CircleAvatar(
                                  radius: 30,
                                  backgroundColor: Colors.white24,
                                  child: Icon(Icons.person, size: 35, color: Colors.white),
                                ),
                          ],
                        ),
                      if (isExpanded || !isDesktop) ...[
                        const SizedBox(height: 16),
                        Text(
                          isLoggedIn ? (userData?['name'] ?? '') : localizations.guest,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        if (isLoggedIn)
                          Text(
                            '@${userData?['username'] ?? ''}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                      ],
                      if (isDesktop && !isExpanded)
                        const Icon(Icons.menu, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildMenuItem(context, Icons.person, localizations.profileMenuItem, onProfileTap),
          _buildMenuItem(context, Icons.list_alt, localizations.trickListMenuItem, onTrickListTap),
          _buildMenuItem(context, Icons.trending_up, localizations.progressTrackerMenuItem, onProgressTap),
          _buildMenuItem(context, Icons.emoji_events, localizations.leaderboardMenuItem, onLeaderboardTap),
          _buildMenuItem(context, Icons.track_changes, localizations.sessionGoalsMenuItem, onSessionGoalsTap),
          _buildMenuItem(context, Icons.settings, localizations.settingsMenuItem, onSettingsTap),
          const Divider(height: 1),
          if (isExpanded || !isDesktop)
            ExpansionTile(
              leading: const Icon(Icons.language, color: Color(0xFF004D40)),
              title: Text(localizations.language),
              children: <Widget>[
                _buildLanguageOption(context, '🇩🇪', localizations.german, 'de'),
                _buildLanguageOption(context, '🇬🇧', localizations.english, 'en'),
                _buildLanguageOption(context, '🇪🇸', localizations.spanish, 'es'),
                _buildLanguageOption(context, '🇮🇹', localizations.italian, 'it'),
                _buildLanguageOption(context, '🇫🇷', localizations.french, 'fr'),
              ],
            )
          else
            ListTile(
              leading: const Padding(
                padding: EdgeInsets.only(left: 12),
                child: Icon(Icons.language, color: Color(0xFF004D40)),
              ),
              onTap: onToggleMenu,
            ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Padding(
        padding: isExpanded ? EdgeInsets.zero : const EdgeInsets.only(left: 12),
        child: Icon(icon, color: const Color(0xFF004D40)),
      ),
      title: (isExpanded || !isDesktop) ? Text(title) : null,
      onTap: () => _onTileTap(context, onTap),
    );
  }

  Widget _buildLanguageOption(BuildContext context, String flag, String name, String locale) {
    return ListTile(
      title: Row(
        children: [
          Text(flag),
          const SizedBox(width: 8),
          Text(name),
        ],
      ),
      onTap: () {
        onLanguageChange(locale);
        if (!isDesktop) Navigator.pop(context);
      },
    );
  }
}
