import 'package:flutter/material.dart';
import 'package:skaterz/l10n/app_localizations.dart';
import 'package:skaterz/services/api_service.dart';
import 'package:skaterz/pages/initial_trick_selection_page.dart';
import 'package:skaterz/core/constants.dart';
import 'package:skaterz/widgets/custom_app_bar.dart';
import 'package:skaterz/widgets/side_menu.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({
    super.key,
    required this.localizations,
    required this.onLogin,
    this.onMenuTap,
    this.isStandalone = false,
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
  final VoidCallback? onMenuTap;
  final bool isStandalone;
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

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _apiService = ApiService();
  bool _isLoading = false;
  late bool _isMenuExpanded;

  @override
  void initState() {
    super.initState();
    _isMenuExpanded = widget.isMenuExpanded;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _nav(VoidCallback? originalCallback) {
    if (originalCallback != null) {
      // Profi-Fix: Pop bis zur MainShell (Root), damit der Tab-Wechsel sichtbar wird
      Navigator.of(context).popUntil((route) => route.isFirst);
      originalCallback();
    }
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        await _apiService.register(
          _usernameController.text,
          _passwordController.text,
          _emailController.text,
          _nameController.text,
        );
        
        await _apiService.login(
          _usernameController.text,
          _passwordController.text,
        );

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => InitialTrickSelectionPage(
                localizations: widget.localizations,
                onComplete: widget.onLogin,
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          String errorMessage = widget.localizations.registrationFailed;
          if (e.toString().toLowerCase().contains('email') && e.toString().toLowerCase().contains('exists')) {
            errorMessage = widget.localizations.emailAlreadyExists;
          } else {
            errorMessage = '${widget.localizations.registrationFailed}: ${e.toString()}';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppColors.getDynamicPrimary(context);

    final content = Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: widget.localizations.name,
                    prefixIcon: Icon(Icons.person_outline, color: primaryColor),
                  ),
                  validator: (value) => (value == null || value.isEmpty) ? widget.localizations.enterName : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: widget.localizations.username,
                    prefixIcon: Icon(Icons.alternate_email, color: primaryColor),
                  ),
                  validator: (value) => (value == null || value.isEmpty) ? widget.localizations.enterUsername : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: widget.localizations.email,
                    prefixIcon: Icon(Icons.email_outlined, color: primaryColor),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => (value == null || value.isEmpty) ? widget.localizations.enterEmail : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: widget.localizations.password,
                    prefixIcon: Icon(Icons.lock_outline, color: primaryColor),
                  ),
                  obscureText: true,
                  validator: (value) => (value == null || value.length < 6) ? widget.localizations.passwordTooShort : null,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isLoading 
                    ? const SizedBox(
                        height: 20, 
                        width: 20, 
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      ) 
                    : Text(widget.localizations.registerButton.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (!widget.isStandalone) {
      return Scaffold(body: content);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 800;
        final sideMenu = SideMenu(
          localizations: widget.localizations,
          isLoggedIn: false,
          isExpanded: _isMenuExpanded,
          isDesktop: isDesktop,
          onToggleMenu: () => setState(() => _isMenuExpanded = !_isMenuExpanded),
          onLanguageChange: widget.onLanguageChange ?? (v) {},
          onProfileTap: () => _nav(widget.onProfileTap),
          onTrickListTap: () => _nav(widget.onTrickListTap),
          onProgressTap: () => _nav(widget.onProgressTap),
          onSessionGoalsTap: () => _nav(widget.onSessionGoalsTap),
          onEquipmentTap: () => _nav(widget.onEquipmentTap),
          onLeaderboardTap: () => _nav(widget.onLeaderboardTap),
          onFriendsTap: () => _nav(widget.onFriendsTap),
          onSettingsTap: () => _nav(widget.onSettingsTap),
          isDarkMode: widget.isDarkMode,
          onThemeToggle: widget.onThemeToggle ?? (v) {},
        );

        return Scaffold(
          key: _scaffoldKey,
          appBar: CustomAppBar(
            title: widget.localizations.registerPageTitle,
            isDarkMode: widget.isDarkMode,
            onMenuTap: isDesktop 
                ? () => setState(() => _isMenuExpanded = !_isMenuExpanded) 
                : () => _scaffoldKey.currentState?.openDrawer(),
            showMenuButton: true,
            isExpanded: _isMenuExpanded,
            isDesktop: isDesktop,
          ),
          drawer: isDesktop ? null : sideMenu,
          body: Row(
            children: [
              if (isDesktop)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  width: _isMenuExpanded ? 280 : 72,
                  child: sideMenu,
                ),
              Expanded(child: content),
            ],
          ),
        );
      }
    );
  }
}
