import 'package:flutter/material.dart';
import 'package:skaterz/l10n/app_localizations.dart';
import 'package:skaterz/pages/login_page.dart';

class LoginRequiredView extends StatelessWidget {
  const LoginRequiredView({
    super.key,
    required this.localizations,
    required this.onLogin,
    required this.featureName,
    required this.icon,
  });

  final AppLocalizations localizations;
  final VoidCallback onLogin;
  final String featureName;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF002211), Color(0xFF004D40), Color(0xFF00FF88)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
        title: Text(
          featureName,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 120, color: Colors.grey[400]),
              const SizedBox(height: 24),
              Text(
                featureName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                localizations.loginRequiredWarning,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16, 
                  color: Colors.black54,
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
                      ),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF004D40),
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
      ),
    );
  }
}
