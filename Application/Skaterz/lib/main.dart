import 'package:flutter/material.dart';
import 'package:skaterz/l10n/app_localizations.dart';
import 'package:skaterz/pages/login_page.dart';
import 'package:skaterz/pages/profile_page.dart';
import 'package:skaterz/pages/progress_tracker_page.dart';
import 'package:skaterz/pages/leaderboard_page.dart';
import 'package:skaterz/pages/settings_page.dart';
import 'package:skaterz/pages/trick_category_page.dart';
import 'package:skaterz/widgets/side_menu.dart';
import 'package:skaterz/services/api_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _locale = 'de';
  bool _isLoggedIn = false;
  Map<String, dynamic>? _userData;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _apiService.onUnauthorized = () {
      _handleLogout();
    };
  }

  Future<void> _checkLoginStatus() async {
    final token = await _apiService.getToken();
    if (token != null) {
      setState(() => _isLoggedIn = true);
      _fetchUserData();
    }
  }

  Future<void> _fetchUserData() async {
    try {
      final user = await _apiService.getCurrentUser();
      setState(() {
        _userData = user;
      });
    } catch (e) {
      debugPrint("Error fetching user data: $e");
    }
  }

  void _changeLanguage(String newLocale) {
    setState(() => _locale = newLocale);
  }

  void _handleLogin() {
    setState(() => _isLoggedIn = true);
    _fetchUserData();
  }

  void _handleLogout() async {
    await _apiService.logout();
    setState(() {
      _isLoggedIn = false;
      _userData = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(_locale);
    return MaterialApp(
      title: localizations.homePageTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF004D40),
          primary: const Color(0xFF004D40),
          secondary: Colors.greenAccent,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: MyHomePage(
        localizations: localizations,
        onLanguageChange: _changeLanguage,
        isLoggedIn: _isLoggedIn,
        userData: _userData,
        onLogin: _handleLogin,
        onLogout: _handleLogout,
        onRefreshUser: _fetchUserData,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
    required this.localizations,
    required this.onLanguageChange,
    required this.isLoggedIn,
    required this.userData,
    required this.onLogin,
    required this.onLogout,
    required this.onRefreshUser,
  });

  final AppLocalizations localizations;
  final Function(String) onLanguageChange;
  final bool isLoggedIn;
  final Map<String, dynamic>? userData;
  final VoidCallback onLogin;
  final VoidCallback onLogout;
  final VoidCallback onRefreshUser;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;
  bool _isMenuExpanded = false;

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  void _toggleMenu() {
    setState(() => _isMenuExpanded = !_isMenuExpanded);
  }

  Widget _getSelectedPage() {
    switch (_selectedIndex) {
      case 0:
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
              widget.localizations.homePageTitle,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.skateboarding, size: 100, color: Color(0xFF00695C)),
                const SizedBox(height: 20),
                Text(
                  widget.localizations.welcomeMessage,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF004D40)),
                ),
              ],
            ),
          ),
        );
      case 1:
        return widget.isLoggedIn
            ? ProfilePage(
                localizations: widget.localizations, 
                onLogout: widget.onLogout,
                onUserDataChanged: widget.onRefreshUser,
              )
            : LogInPage(localizations: widget.localizations, onLogin: widget.onLogin);
      case 2:
        return TrickCategoryPage(localizations: widget.localizations, isLoggedIn: widget.isLoggedIn);
      case 3:
        return ProgressTrackerPage(
          localizations: widget.localizations,
          isLoggedIn: widget.isLoggedIn,
          onLogin: widget.onLogin,
        );
      case 4:
        return LeaderboardPage(
          localizations: widget.localizations,
          isLoggedIn: widget.isLoggedIn,
          onLogin: widget.onLogin,
          onNavigateToProfile: () => _onItemTapped(1),
        );
      case 5:
        return SettingsPage(
          localizations: widget.localizations,
          isLoggedIn: widget.isLoggedIn,
          onLogin: widget.onLogin,
          onLogout: widget.onLogout,
        );
      default:
        return Center(child: Text(widget.localizations.welcomeMessage));
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 800;
        
        final menu = SideMenu(
          localizations: widget.localizations,
          isLoggedIn: widget.isLoggedIn,
          userData: widget.userData,
          isExpanded: _isMenuExpanded,
          isDesktop: isDesktop,
          onToggleMenu: _toggleMenu,
          onLanguageChange: widget.onLanguageChange,
          onProfileTap: () => _onItemTapped(1),
          onTrickListTap: () => _onItemTapped(2),
          onProgressTap: () => _onItemTapped(3),
          onLeaderboardTap: () => _onItemTapped(4),
          onSettingsTap: () => _onItemTapped(5),
        );

        return Scaffold(
          appBar: !isDesktop ? AppBar(
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
              widget.localizations.homePageTitle,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            iconTheme: const IconThemeData(color: Colors.white),
          ) : null,
          drawer: isDesktop ? null : menu,
          body: Row(
            children: [
              if (isDesktop) SizedBox(width: _isMenuExpanded ? 250 : 80, child: menu),
              Expanded(child: _getSelectedPage()),
            ],
          ),
        );
      },
    );
  }
}
