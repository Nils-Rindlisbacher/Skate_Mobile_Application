import 'package:flutter/material.dart';
import 'package:skaterz/l10n/app_localizations.dart';
import 'package:skaterz/services/api_service.dart';
import 'package:skaterz/core/constants.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

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
  final VoidCallback onMenuTap;
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

  void _pickColor(String key, Color currentColor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Pick a Color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: currentColor,
            onColorChanged: (color) async {
              await _apiService.saveCustomColor(key, color);
              setState(() {
                switch (key) {
                  case 'primary': AppColors.primary = color; break;
                  case 'secondary': AppColors.secondary = color; break;
                  case 'primaryOld': AppColors.primaryOld = color; break;
                  case 'secondaryOld': AppColors.secondaryOld = color; break;
                  case 'sidebarTop': AppColors.sidebarTop = color; break;
                  case 'sidebarBottom': AppColors.sidebarBottom = color; break;
                }
              });
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Close')),
        ],
      ),
    );
  }

  Widget _buildColorTile(String title, Color color, VoidCallback onTap) {
    return ListTile(
      title: Text(title),
      trailing: Container(width: 30, height: 30, decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.grey.withValues(alpha: 0.2)))),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryIconColor = isDark ? AppColors.secondary : AppColors.primary;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(widget.localizations.settingsMenuItem.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16)),
        leading: IconButton(icon: const Icon(Icons.menu_rounded), onPressed: widget.onMenuTap),
      ),
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
            activeColor: AppColors.primary,
          ),

          _buildSectionHeader('App Branding'),
          _buildColorTile('Dark Mode Primary', AppColors.primary, () => _pickColor('primary', AppColors.primary)),
          _buildColorTile('Dark Mode Secondary', AppColors.secondary, () => _pickColor('secondary', AppColors.secondary)),
          _buildColorTile('Light Mode Primary', AppColors.primaryOld, () => _pickColor('primaryOld', AppColors.primaryOld)),
          _buildColorTile('Light Mode Secondary', AppColors.secondaryOld, () => _pickColor('secondaryOld', AppColors.secondaryOld)),
          _buildColorTile('Sidebar Top', AppColors.sidebarTop, () => _pickColor('sidebarTop', AppColors.sidebarTop)),
          _buildColorTile('Sidebar Bottom', AppColors.sidebarBottom, () => _pickColor('sidebarBottom', AppColors.sidebarBottom)),

          if (widget.isLoggedIn) ...[
            _buildSectionHeader(widget.localizations.profileVisibility),
            SwitchListTile(
              secondary: Icon(Icons.public_rounded, color: primaryIconColor),
              title: Text(widget.localizations.publicProfile),
              subtitle: Text(widget.localizations.publicProfileSubtitle),
              value: _isPublic,
              onChanged: _isUpdatingPrivacy ? null : _togglePrivacy,
              activeColor: AppColors.primary,
            ),
            
            _buildSectionHeader(widget.localizations.blockedUsers),
            ListTile(
              leading: Icon(Icons.block_rounded, color: primaryIconColor),
              title: Text(widget.localizations.blockedUsers),
              onTap: () => _showBlockedUsers(),
            ),

            _buildSectionHeader(widget.localizations.deleteAccount),
            ListTile(
              leading: const Icon(Icons.delete_forever_rounded, color: Colors.red),
              title: Text(widget.localizations.deleteAccount, style: const TextStyle(color: Colors.red)),
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

  void _showLanguageDialog() { /* ... unchanged ... */ }
  void _showBlockedUsers() { /* ... unchanged ... */ }
  void _showDeleteConfirmation() { /* ... unchanged ... */ }
  void _showTermsDialog() { /* ... unchanged ... */ }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(title.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.grey)),
    );
  }
}
