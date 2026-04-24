import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:skaterz/l10n/app_localizations.dart';
import 'package:skaterz/pages/login_page.dart';
import 'package:skaterz/pages/profile_page.dart';
import 'package:skaterz/pages/progress_tracker_page.dart';
import 'package:skaterz/pages/leaderboard_page.dart';
import 'package:skaterz/pages/settings_page.dart';
import 'package:skaterz/pages/trick_category_page.dart';
import 'package:skaterz/pages/session_goals_page.dart';
import 'package:skaterz/pages/equipment_page.dart';
import 'package:skaterz/pages/friends_page.dart';
import 'package:skaterz/widgets/custom_app_bar.dart';
import 'package:skaterz/widgets/side_menu.dart';
import 'package:skaterz/services/api_service.dart';
import 'package:skaterz/core/app_theme.dart';
import 'package:skaterz/core/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    SystemChannels.skia.invokeMethod<void>('setContextMenusEnabled', false).catchError((_) {});
  }

  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

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
  ThemeMode _themeMode = ThemeMode.dark; 
  Map<String, dynamic>? _userData;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    await Future.wait([
      _loadThemeMode(),
      _loadLocale(),
      _checkLoginStatus(),
      _apiService.warmUp(),
    ]);
    _apiService.onUnauthorized = _handleLogout;
  }

  Future<void> _loadThemeMode() async {
    final mode = await _apiService.getCachedData('theme_mode');
    if (mode != null && mounted) {
      setState(() {
        _themeMode = mode == 'light' ? ThemeMode.light : ThemeMode.dark;
      });
    }
  }

  Future<void> _loadLocale() async {
    final locale = await _apiService.getCachedData('app_locale');
    if (locale != null && mounted) {
      setState(() {
        _locale = locale.toString();
      });
    }
  }

  void _toggleTheme(bool isDark) {
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
    _apiService.saveThemeMode(isDark ? 'dark' : 'light');
  }

  Future<void> _checkLoginStatus() async {
    final token = await _apiService.getToken();
    if (token != null) {
      if (mounted) setState(() => _isLoggedIn = true);
      final cachedUser = await _apiService.getCachedData('user_me');
      if (cachedUser != null && mounted) {
        setState(() => _userData = cachedUser);
      }
      _fetchUserData();
    }
  }

  Future<void> _fetchUserData() async {
    try {
      final user = await _apiService.getCurrentUser();
      if (mounted) setState(() => _userData = user);
    } catch (e) {
      debugPrint("Error fetching user data: $e");
    }
  }

  void _changeLanguage(String newLocale) {
    setState(() => _locale = newLocale);
    _apiService.saveThemeMode(newLocale);
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
      themeMode: _themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: MainShell(
        localizations: localizations,
        onLanguageChange: _changeLanguage,
        isLoggedIn: _isLoggedIn,
        userData: _userData,
        onLogin: _handleLogin,
        onLogout: _handleLogout,
        onRefreshUser: _fetchUserData,
        isDarkMode: _themeMode == ThemeMode.dark,
        onThemeToggle: _toggleTheme,
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    required this.localizations,
    required this.onLanguageChange,
    required this.isLoggedIn,
    required this.userData,
    required this.onLogin,
    required this.onLogout,
    required this.onRefreshUser,
    required this.isDarkMode,
    required this.onThemeToggle,
  });

  final AppLocalizations localizations;
  final Function(String) onLanguageChange;
  final bool isLoggedIn;
  final Map<String, dynamic>? userData;
  final VoidCallback onLogin;
  final VoidCallback onLogout;
  final VoidCallback onRefreshUser;
  final bool isDarkMode;
  final Function(bool) onThemeToggle;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final List<int> _navigationHistory = [0];
  bool _isMenuExpanded = false;

  void _onItemTapped(int index) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
    if (_selectedIndex != index) {
      setState(() {
        _navigationHistory.add(index);
      });
    }
  }

  int get _selectedIndex => _navigationHistory.last;

  bool _onWillPop() {
    if (_navigationHistory.length > 1) {
      setState(() {
        _navigationHistory.removeLast();
      });
      return false;
    }
    return true;
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  String _getTitleForIndex(int index) {
    switch (index) {
      case 0: return widget.localizations.homePageTitle;
      case 1: return widget.localizations.profileMenuItem;
      case 2: return widget.localizations.trickListMenuItem;
      case 3: return widget.localizations.progressTrackerMenuItem;
      case 4: return widget.localizations.leaderboardMenuItem;
      case 5: return widget.localizations.friends;
      case 6: return widget.localizations.sessionGoalsMenuItem;
      case 7: return widget.localizations.equipmentMenuItem;
      case 8: return widget.localizations.settingsMenuItem;
      default: return widget.localizations.homePageTitle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _navigationHistory.length <= 1,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _onWillPop();
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 800;

          final sideMenu = SideMenu(
            localizations: widget.localizations,
            isLoggedIn: widget.isLoggedIn,
            userData: widget.userData,
            isExpanded: _isMenuExpanded,
            isDesktop: isDesktop,
            onToggleMenu: () => setState(() => _isMenuExpanded = !_isMenuExpanded),
            onLanguageChange: widget.onLanguageChange,
            onProfileTap: () => _onItemTapped(1),
            onTrickListTap: () => _onItemTapped(2),
            onProgressTap: () => _onItemTapped(3),
            onLeaderboardTap: () => _onItemTapped(4),
            onFriendsTap: () => _onItemTapped(5),
            onSessionGoalsTap: () => _onItemTapped(6),
            onEquipmentTap: () => _onItemTapped(7),
            onSettingsTap: () => _onItemTapped(8),
            isDarkMode: widget.isDarkMode,
            onThemeToggle: widget.onThemeToggle,
          );

          return Scaffold(
            key: _scaffoldKey,
            // AppBar always on top
            appBar: CustomAppBar(
              title: _getTitleForIndex(_selectedIndex),
              isDarkMode: widget.isDarkMode,
              onMenuTap: isDesktop 
                  ? () => setState(() => _isMenuExpanded = !_isMenuExpanded) 
                  : _openDrawer,
              showMenuButton: true,
            ),
            drawer: isDesktop ? null : sideMenu,
            body: Row(
              children: [
                if (isDesktop) 
                  SizedBox(
                    width: _isMenuExpanded ? 250 : 80, 
                    child: sideMenu // SideMenu now naturally starts below AppBar
                  ),
                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: [
                      _HomeView(
                        localizations: widget.localizations,
                        isDarkMode: widget.isDarkMode,
                      ),
                      widget.isLoggedIn
                          ? ProfilePage(
                              localizations: widget.localizations,
                              onLogout: widget.onLogout,
                              onUserDataChanged: widget.onRefreshUser,
                              isLoggedIn: widget.isLoggedIn,
                              isActive: _selectedIndex == 1,
                              onMenuTap: () {  },
                            )
                          : LogInPage(
                              localizations: widget.localizations,
                              onLogin: widget.onLogin,
                              onMenuTap: () {  },
                            ),
                      TrickCategoryPage(
                        localizations: widget.localizations,
                        isLoggedIn: widget.isLoggedIn,
                        onMenuTap: () {  },
                      ),
                      ProgressTrackerPage(
                        localizations: widget.localizations,
                        isLoggedIn: widget.isLoggedIn,
                        onLogin: widget.onLogin,
                        isActive: _selectedIndex == 3,
                        onMenuTap: () {  },
                      ),
                      LeaderboardPage(
                        localizations: widget.localizations,
                        isLoggedIn: widget.isLoggedIn,
                        onLogin: widget.onLogin,
                        onNavigateToSettings: () => _onItemTapped(8),
                        userData: widget.userData,
                        isActive: _selectedIndex == 4,
                      ),
                      FriendsPage(
                        localizations: widget.localizations,
                        isLoggedIn: widget.isLoggedIn,
                        onLogin: widget.onLogin,
                      ),
                      SessionGoalsPage(
                        localizations: widget.localizations,
                        isLoggedIn: widget.isLoggedIn,
                        onLogin: widget.onLogin,
                      ),
                      EquipmentPage(
                        localizations: widget.localizations,
                        isLoggedIn: widget.isLoggedIn,
                        onLogin: widget.onLogin,
                      ),
                      SettingsPage(
                        localizations: widget.localizations,
                        isLoggedIn: widget.isLoggedIn,
                        onLogin: widget.onLogin,
                        onLogout: widget.onLogout,
                        isDarkMode: widget.isDarkMode,
                        onThemeToggle: widget.onThemeToggle,
                        userData: widget.userData,
                        onPrivacyChanged: widget.onRefreshUser,
                        onLanguageChange: widget.onLanguageChange,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView({
    required this.localizations,
    required this.isDarkMode,
  });

  final AppLocalizations localizations;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    final Color textColor = isDarkMode ? AppColors.primary : AppColors.primaryOld;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.skateboarding, size: 100, color: textColor),
          const SizedBox(height: 20),
          Text(
            localizations.welcomeMessage,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
