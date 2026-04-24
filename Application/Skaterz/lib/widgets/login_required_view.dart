import 'package:flutter/material.dart';
import 'package:skaterz/l10n/app_localizations.dart';
import 'package:skaterz/pages/login_page.dart';
import 'package:skaterz/core/constants.dart';

class LoginRequiredView extends StatelessWidget {
  const LoginRequiredView({
    super.key,
    required this.localizations,
    required this.onLogin,
    required this.featureName,
    required this.icon, 
    required Null Function() onMenuTap,
  });

  final AppLocalizations localizations;
  final VoidCallback onLogin;
  final String featureName;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 120, color: Colors.grey.withOpacity(0.4)),
            const SizedBox(height: 24),
            Text(
              featureName,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              localizations.loginRequiredWarning,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16, 
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 250,
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LogInPage(
                      localizations: localizations,
                      onLogin: onLogin,
                      onMenuTap: () { },
                    ),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.getDynamicPrimary(context),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  localizations.loginNow,
                  style: const TextStyle(
                    fontSize: 16, 
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
