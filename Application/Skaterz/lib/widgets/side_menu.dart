import 'package:flutter/material.dart';
import 'package:skaterz/l10n/app_localizations.dart';

class SideMenu extends StatelessWidget {
  const SideMenu({
    super.key,
    required this.localizations,
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
    this.isLoggedIn = false,
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
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          if (isDesktop)
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(2, 0),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                physics: const BouncingScrollPhysics(),
                children: <Widget>[
                  _buildMenuItem(context, Icons.person_outline_rounded, localizations.profileMenuItem, onProfileTap),
                  _buildMenuItem(context, Icons.people_outline_rounded, localizations.friends, onFriendsTap),
                  _buildMenuItem(context, Icons.checklist_outlined, localizations.trickListMenuItem, onTrickListTap),
                  _buildMenuItem(context, Icons.bar_chart_outlined, localizations.progressTrackerMenuItem, onProgressTap),
                  _buildMenuItem(context, Icons.ads_click_rounded, localizations.sessionGoalsMenuItem, onSessionGoalsTap),
                  _buildMenuItem(context, Icons.emoji_events_outlined, localizations.leaderboardMenuItem, onLeaderboardTap),
                  _buildMenuItem(context, Icons.construction_outlined, localizations.equipmentMenuItem, onEquipmentTap),
                  _buildMenuItem(context, Icons.settings_outlined, localizations.settingsMenuItem, onSettingsTap),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Divider(height: 1, thickness: 0.5, color: colorScheme.outline.withOpacity(0.2)),
                  ),

                  _buildMenuItem(
                    context, 
                    isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded, 
                    localizations.darkMode, 
                    () => onThemeToggle(!isDarkMode)
                  ),

                  // Sprachen nach ganz unten verschoben
                  _buildLanguageExpansion(context),
                ],
              ),
            ),
            
            if (isDesktop)
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: isExpanded ? 0.2 : 0.0,
                  child: Text(
                    "© 2026 SKATERZ",
                    style: TextStyle(
                      color: colorScheme.onSurface, 
                      fontSize: 9, 
                      fontWeight: FontWeight.bold, 
                      letterSpacing: 2
                    ),
                    maxLines: 1,
                    softWrap: false,
                  ),
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.all(24.0),
                child: Opacity(
                  opacity: 0.2,
                  child: Text(
                    "© 2026 SKATERZ",
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onTileTap(context, onTap),
        child: Container(
          height: 50,
          width: double.infinity,
          padding: const EdgeInsets.only(left: 24), 
          child: Row(
            children: [
              Icon(icon, color: colorScheme.primary, size: 24),
              const SizedBox(width: 24), 
              if (isDesktop)
                Expanded(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: isExpanded ? 1.0 : 0.0,
                    curve: Curves.easeInOut,
                    child: Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      softWrap: false,
                    ),
                  ),
                )
              else
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: colorScheme.onSurface,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageExpansion(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // Im eingeklappten Zustand: Klick expandiert Sidebar UND oeffnet Dropdown
    if (isDesktop && !isExpanded) {
      return _buildMenuItem(context, Icons.language_rounded, localizations.language, onToggleMenu ?? () {});
    }

    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
        hoverColor: Colors.transparent,
      ),
      child: ExpansionTile(
        // Profi-Fix: initiallyExpanded auf true setzen, wenn wir gerade erst expandiert haben (stateless workaround)
        // Wenn isDesktop true ist, nehmen wir an, dass man es oft offen sehen will oder es gerade geoeffnet wurde.
        initiallyExpanded: isDesktop && isExpanded, 
        tilePadding: const EdgeInsets.only(left: 24, right: 16),
        leading: Icon(Icons.language_rounded, color: colorScheme.primary, size: 24),
        // Profi-Fix: Padding hinzugefuegt, um die 8px Differenz zwischen ListTile-Gap (16) und SizedBox (24) auszugleichen
        title: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Text(
            localizations.language, 
            style: TextStyle(
              fontWeight: FontWeight.w600, 
              fontSize: 14, 
              color: colorScheme.onSurface
            ),
            maxLines: 1,
            softWrap: false,
          ),
        ),
        children: <Widget>[
          _buildLanguageOption(context, '🇩🇪', localizations.german, 'de'),
          _buildLanguageOption(context, '🇬🇧', localizations.english, 'en'),
          _buildLanguageOption(context, '🇪🇸', localizations.spanish, 'es'),
          _buildLanguageOption(context, '🇮🇹', localizations.italian, 'it'),
          _buildLanguageOption(context, '🇫🇷', localizations.french, 'fr'),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(BuildContext context, String flag, String name, String locale) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 72, right: 24),
      title: Text('$flag  $name', style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface)),
      onTap: () => onLanguageChange(locale),
    );
  }
}
