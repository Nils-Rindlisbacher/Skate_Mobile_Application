import 'package:flutter/material.dart';
import 'package:skaterz/l10n/app_localizations.dart';
import 'package:skaterz/pages/signin_page.dart';
import 'package:skaterz/services/api_service.dart';
import 'package:skaterz/core/constants.dart';
import 'package:skaterz/widgets/custom_app_bar.dart';
import 'package:skaterz/widgets/side_menu.dart';

class LogInPage extends StatefulWidget {
  const LogInPage({
    super.key,
    required this.localizations,
    required this.onLogin,
    required this.onMenuTap,
    this.isStandalone = false,
    this.isDarkMode = true,
    this.isMenuExpanded = false,
    this.onThemeToggle,
    this.onLanguageChange,
  });

  final AppLocalizations localizations;
  final VoidCallback onLogin;
  final VoidCallback onMenuTap;
  final bool isStandalone;
  final bool isDarkMode;
  final bool isMenuExpanded;
  final Function(bool)? onThemeToggle;
  final Function(String)? onLanguageChange;

  @override
  State<LogInPage> createState() => _LogInPageState();
}

class _LogInPageState extends State<LogInPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  late bool _isMenuExpanded;

  @override
  void initState() {
    super.initState();
    _isMenuExpanded = widget.isMenuExpanded;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.localizations.enterCredentials)),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _apiService.login(
        _usernameController.text,
        _passwordController.text,
      );
      if (mounted) {
        widget.onLogin();
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.localizations.loginFailed}: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.skateboarding, size: 80, color: primaryColor),
              const SizedBox(height: 32),
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: widget.localizations.username,
                  prefixIcon: const Icon(Icons.person),
                ),
                onFieldSubmitted: (_) => _handleLogin(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: widget.localizations.password,
                  prefixIcon: const Icon(Icons.lock),
                ),
                onFieldSubmitted: (_) => _handleLogin(),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
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
                  : Text(widget.localizations.loginButton.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SignInPage(
                        localizations: widget.localizations,
                        onLogin: widget.onLogin,
                        onMenuTap: widget.onMenuTap,
                        isStandalone: widget.isStandalone,
                        isDarkMode: widget.isDarkMode,
                        isMenuExpanded: _isMenuExpanded,
                        onThemeToggle: widget.onThemeToggle,
                        onLanguageChange: widget.onLanguageChange,
                      ),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryColor,
                  side: BorderSide(color: primaryColor, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(widget.localizations.registerButton.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
              ),
            ],
          ),
        ),
      ),
    );

    if (!widget.isStandalone) return content;

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
          onProfileTap: () {},
          onTrickListTap: () {},
          onProgressTap: () {},
          onSessionGoalsTap: () {},
          onEquipmentTap: () {},
          onLeaderboardTap: () {},
          onFriendsTap: () {},
          onSettingsTap: () {},
          isDarkMode: widget.isDarkMode,
          onThemeToggle: widget.onThemeToggle ?? (v) {},
        );

        return Scaffold(
          key: _scaffoldKey,
          appBar: CustomAppBar(
            title: widget.localizations.loginPageTitle,
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
