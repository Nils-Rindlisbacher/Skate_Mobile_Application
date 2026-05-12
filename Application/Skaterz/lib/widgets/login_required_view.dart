import 'package:flutter/material.dart';
import 'package:skaterz/l10n/app_localizations.dart';
import 'package:skaterz/pages/login_page.dart';
import 'package:skaterz/pages/signin_page.dart';
import 'package:skaterz/core/constants.dart';

class LoginRequiredView extends StatelessWidget {
  const LoginRequiredView({
    super.key,
    required this.localizations,
    required this.onLogin,
    required this.featureName,
    required this.icon,
    required this.onMenuTap,
    this.isDarkMode = true,
    this.isMenuExpanded = false,
    this.onThemeToggle,
    this.onLanguageChange,
    this.onProfileTap,
    this.onProgressTap,
    this.onLeaderboardTap,
    this.onTrickListTap,
    this.onFriendsTap,
    this.onSessionGoalsTap,
    this.onEquipmentTap,
    this.onSettingsTap,
  });

  final AppLocalizations localizations;
  final VoidCallback onLogin;
  final String featureName;
  final IconData icon;
  final VoidCallback onMenuTap;
  final bool isDarkMode;
  final bool isMenuExpanded;
  final Function(bool)? onThemeToggle;
  final Function(String)? onLanguageChange;
  
  final VoidCallback? onProfileTap;
  final VoidCallback? onProgressTap;
  final VoidCallback? onLeaderboardTap;
  final VoidCallback? onTrickListTap;
  final VoidCallback? onFriendsTap;
  final VoidCallback? onSessionGoalsTap;
  final VoidCallback? onEquipmentTap;
  final VoidCallback? onSettingsTap;

  // Profi-Navigations-Fix für nahtlose Übergänge
  void _pushPage(BuildContext context, Widget page) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (context, animation, secondaryAnimation) => FadeTransition(
          opacity: animation,
          child: page,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppColors.getDynamicPrimary(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 100, color: primaryColor.withOpacity(0.2)),
            const SizedBox(height: 24),
            Text(
              featureName,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              localizations.loginRequiredWarning,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16, 
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 40),
            
            SizedBox(
              width: 280,
              child: ElevatedButton(
                onPressed: () => _pushPage(context, LogInPage(
                  localizations: localizations,
                  onLogin: onLogin,
                  onMenuTap: onMenuTap,
                  isStandalone: true,
                  isDarkMode: isDarkMode,
                  isMenuExpanded: isMenuExpanded,
                  onThemeToggle: onThemeToggle,
                  onLanguageChange: onLanguageChange,
                  onProfileTap: onProfileTap,
                  onProgressTap: onProgressTap,
                  onLeaderboardTap: onLeaderboardTap,
                  onTrickListTap: onTrickListTap,
                  onFriendsTap: onFriendsTap,
                  onSessionGoalsTap: onSessionGoalsTap,
                  onEquipmentTap: onEquipmentTap,
                  onSettingsTap: onSettingsTap,
                )),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(
                  localizations.loginNow.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            SizedBox(
              width: 280,
              child: OutlinedButton(
                onPressed: () => _pushPage(context, SignInPage(
                  localizations: localizations,
                  onLogin: onLogin,
                  onMenuTap: onMenuTap,
                  isStandalone: true,
                  isDarkMode: isDarkMode,
                  isMenuExpanded: isMenuExpanded,
                  onThemeToggle: onThemeToggle,
                  onLanguageChange: onLanguageChange,
                  onProfileTap: onProfileTap,
                  onProgressTap: onProgressTap,
                  onLeaderboardTap: onLeaderboardTap,
                  onTrickListTap: onTrickListTap,
                  onFriendsTap: onFriendsTap,
                  onSessionGoalsTap: onSessionGoalsTap,
                  onEquipmentTap: onEquipmentTap,
                  onSettingsTap: onSettingsTap,
                )),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryColor,
                  side: BorderSide(color: primaryColor, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  localizations.registerButton.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
