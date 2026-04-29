import 'dart:convert';
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
    required this.onLanguageChange,
    this.userData,
    this.onPrivacyChanged,
  });

  final AppLocalizations localizations;
  final bool isLoggedIn;
  final VoidCallback onLogin;
  final VoidCallback onLogout;
  final bool isDarkMode;
  final Function(bool) onThemeToggle;
  final Function(String) onLanguageChange;
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

  Future<void> _togglePrivacy(bool value) async {
    setState(() => _isUpdatingPrivacy = true);
    try {
      await _apiService.updatePrivacy(value);
      if (mounted) {
        setState(() {
          _isPublic = value;
          _isUpdatingPrivacy = false;
        });
        widget.onPrivacyChanged?.call();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.localizations.visibilityUpdated)));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUpdatingPrivacy = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${widget.localizations.error}: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryIconColor = colorScheme.primary;

    return Scaffold(
      body: ListView(
        children: [
          _buildSectionHeader(widget.localizations.personalization),
          ListTile(
            leading: Icon(Icons.language_rounded, color: primaryIconColor),
            title: Text(widget.localizations.language),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _showLanguageDialog(),
          ),
          SwitchListTile(
            secondary: Icon(widget.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded, color: primaryIconColor),
            title: Text(widget.localizations.darkMode),
            value: widget.isDarkMode,
            onChanged: widget.onThemeToggle,
            activeColor: colorScheme.primary,
          ),

          if (widget.isLoggedIn) ...[
            _buildSectionHeader(widget.localizations.profileVisibility),
            SwitchListTile(
              secondary: Icon(Icons.public_rounded, color: primaryIconColor),
              title: Text(widget.localizations.publicProfile),
              subtitle: Text(widget.localizations.publicProfileSubtitle),
              value: _isPublic,
              onChanged: _isUpdatingPrivacy ? null : _togglePrivacy,
              activeColor: colorScheme.primary,
            ),
            
            _buildSectionHeader(widget.localizations.blockedUsers),
            ListTile(
              leading: Icon(Icons.block_rounded, color: primaryIconColor),
              title: Text(widget.localizations.blockedUsers),
              onTap: () => _showBlockedUsers(),
            ),

            _buildSectionHeader(widget.localizations.deleteAccount),
            ListTile(
              leading: Icon(Icons.delete_forever_rounded, color: colorScheme.error),
              title: Text(widget.localizations.deleteAccount, style: TextStyle(color: colorScheme.error)),
              onTap: () => _showDeleteConfirmation(),
            ),
          ],
          
          _buildSectionHeader(widget.localizations.termsOfUse),
          ListTile(
            leading: Icon(Icons.description_outlined, color: primaryIconColor),
            title: Text(widget.localizations.termsOfUse),
            onTap: () => _showTermsDialog(),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.localizations.language),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption('🇩🇪', widget.localizations.german, 'de'),
            _buildLanguageOption('🇬🇧', widget.localizations.english, 'en'),
            _buildLanguageOption('🇪🇸', widget.localizations.spanish, 'es'),
            _buildLanguageOption('🇮🇹', widget.localizations.italian, 'it'),
            _buildLanguageOption('🇫🇷', widget.localizations.french, 'fr'),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String flag, String name, String locale) {
    return ListTile(
      title: Text('$flag  $name'),
      onTap: () {
        widget.onLanguageChange(locale);
        Navigator.pop(context);
      },
    );
  }

  void _showBlockedUsers() async {
    final colorScheme = Theme.of(context).colorScheme;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(widget.localizations.blockedUsers.toUpperCase(), 
                style: TextStyle(fontWeight: FontWeight.w900, color: colorScheme.onSurface.withOpacity(0.5))),
              const SizedBox(height: 20),
              Expanded(
                child: FutureBuilder<List<dynamic>>(
                  future: _apiService.getBlockedUsers(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(child: Text(widget.localizations.noUsersFound));
                    }
                    
                    final users = snapshot.data!;
                    return ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: (user['profile_image'] != null && user['profile_image'].isNotEmpty)
                                ? MemoryImage(base64Decode(user['profile_image']))
                                : const AssetImage('assets/Default_Profile_Pic.png') as ImageProvider,
                          ),
                          title: Text(user['name'] ?? user['username']),
                          subtitle: Text('@${user['username']}'),
                          trailing: TextButton(
                            onPressed: () async {
                              await _apiService.unblockUser(user['id']);
                              setModalState(() {});
                            },
                            child: Text(widget.localizations.unblock),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation() {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.localizations.deleteAccount),
        content: Text(widget.localizations.deleteAccountWarning),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(widget.localizations.cancel)),
          TextButton(
            onPressed: () async {
              await _apiService.deleteAccount();
              widget.onLogout();
              if (mounted) Navigator.pop(context);
            },
            child: Text(widget.localizations.delete, style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.localizations.termsOfUse),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Nutzungsbedingungen für Skaterz",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              const Text(
                "1. Akzeptanz der Bedingungen\n"
                "Durch die Nutzung der Skaterz-App erklären Sie sich mit diesen Nutzungsbedingungen einverstanden.\n\n"
                "2. Beschreibung des Dienstes\n"
                "Skaterz ist eine Anwendung zum Verfolgen von Skateboard-Fortschritten, zum Setzen von Zielen und zum Austausch mit der Community.\n\n"
                "3. Benutzerpflichten\n"
                "Benutzer sind für die Sicherheit ihres Kontos und für alle Aktivitäten unter ihrem Konto verantwortlich. Es dürfen keine unangemessenen Inhalte hochgeladen werden.\n\n"
                "4. Datenschutz\n"
                "Ihre Daten werden gemäß unserer Datenschutzrichtlinie verarbeitet.\n\n"
                "5. Haftungsausschluss\n"
                "Die Nutzung der App erfolgt auf eigene Gefahr. Skateboarden ist ein Sport mit Verletzungsrisiko. Die Entwickler haften nicht für Unfälle oder Verletzungen.\n\n"
                "6. Änderungen der Bedingungen\n"
                "Wir behalten uns das Recht vor, diese Bedingungen jederzeit zu ändern.",
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Schließen"),
          )
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(title.toUpperCase(), 
        style: TextStyle(
          fontSize: 12, 
          fontWeight: FontWeight.w900, 
          letterSpacing: 1.5, 
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)
        )
      ),
    );
  }
}
