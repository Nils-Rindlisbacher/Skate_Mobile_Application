import 'package:flutter/material.dart';
import 'package:skaterz/l10n/app_localizations.dart';
import 'package:skaterz/services/api_service.dart';
import 'package:skaterz/core/constants.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.localizations,
    required this.isLoggedIn,
    required this.onLogin,
    required this.onLogout,
    required this.isDarkMode,
    required this.onThemeToggle,
    required this.onMenuTap,
    this.userData,
    this.onPrivacyChanged,
  });

  final AppLocalizations localizations;
  final bool isLoggedIn;
  final VoidCallback onLogin;
  final VoidCallback onLogout;
  final bool isDarkMode;
  final Function(bool) onThemeToggle;
  final VoidCallback onMenuTap;
  final Map<String, dynamic>? userData;
  final VoidCallback? onPrivacyChanged;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final ApiService _apiService = ApiService();
  bool _isPublic = true;
  bool _isUpdatingPrivacy = false;

  @override
  void initState() {
    super.initState();
    _isPublic = widget.userData?['isPublic'] ?? widget.userData?['is_public'] ?? true;
  }

  @override
  void didUpdateWidget(SettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userData != oldWidget.userData) {
      setState(() {
        _isPublic = widget.userData?['isPublic'] ?? widget.userData?['is_public'] ?? true;
      });
    }
  }

  bool get isDesktop => MediaQuery.of(context).size.width > 800;

  Future<void> _togglePrivacy(bool value) async {
    setState(() {
      _isUpdatingPrivacy = true;
    });
    
    try {
      await _apiService.updatePrivacy(value);
      if (mounted) {
        setState(() {
          _isPublic = value;
          _isUpdatingPrivacy = false;
        });
        
        widget.onPrivacyChanged?.call();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sichtbarkeit aktualisiert')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUpdatingPrivacy = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')),
        );
      }
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.localizations.deleteAccountConfirm),
        content: Text(widget.localizations.deleteAccountWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(widget.localizations.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _apiService.deleteAccount();
                widget.onLogout();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString())),
                );
              }
            },
            child: Text(widget.localizations.deleteAccount, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    final languages = [
      {'name': widget.localizations.german, 'flag': '🇩🇪', 'code': 'de'},
      {'name': widget.localizations.english, 'flag': '🇬🇧', 'code': 'en'},
      {'name': widget.localizations.spanish, 'flag': '🇪🇸', 'code': 'es'},
      {'name': widget.localizations.italian, 'flag': '🇮🇹', 'code': 'it'},
      {'name': widget.localizations.french, 'flag': '🇫🇷', 'code': 'fr'},
    ];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(widget.localizations.changeLanguage),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: languages.length,
              itemBuilder: (context, index) {
                final lang = languages[index];
                return ListTile(
                  title: Text(
                    lang['name']!,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  ),
                  trailing: Text(lang['flag']!, style: const TextStyle(fontSize: 24)),
                  onTap: () {
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: isDark ? AppColors.secondary : Colors.black, 
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryIconColor = isDark ? AppColors.secondary : AppColors.primary;

    return Scaffold(
      appBar: !isDesktop 
          ? AppBar(
              flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppColors.primaryGradient)),
              title: Text(widget.localizations.settingsMenuItem, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              iconTheme: const IconThemeData(color: Colors.white),
              leading: IconButton(
                icon: const Icon(Icons.menu),
                onPressed: widget.onMenuTap,
              ),
            ) 
          : null,
      body: ListView(
        children: [
          _buildSectionHeader(widget.localizations.personalization),
          ListTile(
            leading: Icon(Icons.language, color: primaryIconColor),
            title: Text(widget.localizations.language),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showLanguageDialog,
          ),
          SwitchListTile(
            secondary: Icon(Icons.dark_mode, color: primaryIconColor),
            title: Text(widget.localizations.darkMode),
            value: widget.isDarkMode,
            onChanged: widget.onThemeToggle,
            activeColor: AppColors.primary,
          ),

          if (widget.isLoggedIn) ...[
            _buildSectionHeader(widget.localizations.profileVisibility),
            SwitchListTile(
              secondary: Icon(Icons.public, color: primaryIconColor),
              title: Text(widget.localizations.publicProfile),
              subtitle: Text(
                widget.localizations.publicProfileSubtitle,
                style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
              ),
              value: _isPublic,
              onChanged: _isUpdatingPrivacy ? null : _togglePrivacy,
              activeColor: AppColors.primary,
            ),
            
            _buildSectionHeader(widget.localizations.deleteAccount),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: Text(widget.localizations.deleteAccount, style: const TextStyle(color: Colors.red)),
              onTap: _showDeleteConfirmation,
            ),
          ],
        ],
      ),
    );
  }
}
