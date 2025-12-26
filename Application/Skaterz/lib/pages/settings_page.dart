import 'package:flutter/material.dart';
import 'package:skaterz/l10n/app_localizations.dart';
import 'package:skaterz/services/api_service.dart';
import 'package:skaterz/widgets/login_required_view.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key, 
    required this.localizations,
    required this.isLoggedIn,
    required this.onLogin,
    this.onLogout,
  });

  final AppLocalizations localizations;
  final bool isLoggedIn;
  final VoidCallback onLogin;
  final VoidCallback? onLogout;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _confirmDeleteAccount() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.localizations.deleteAccountConfirm),
        content: Text(widget.localizations.deleteAccountWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(widget.localizations.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(widget.localizations.deleteAccount),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await _apiService.deleteAccount();
        if (mounted) {
          widget.onLogout?.call();
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoggedIn) {
      return LoginRequiredView(
        localizations: widget.localizations,
        onLogin: widget.onLogin,
        featureName: widget.localizations.settingsMenuItem,
        icon: Icons.settings_outlined,
      );
    }

    return Scaffold(
      appBar: AppBar(
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
          widget.localizations.settingsMenuItem,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            children: [
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: Text(
                  widget.localizations.deleteAccount,
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
                onTap: _confirmDeleteAccount,
              ),
              const Divider(),
            ],
          ),
    );
  }
}
