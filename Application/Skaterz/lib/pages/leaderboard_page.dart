import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:skaterz/l10n/app_localizations.dart';
import 'package:skaterz/services/api_service.dart';
import 'package:skaterz/widgets/login_required_view.dart';
import 'package:skaterz/pages/public_profile_page.dart';
import 'package:skaterz/core/constants.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({
    super.key,
    required this.localizations,
    required this.isLoggedIn,
    required this.onLogin,
    required this.onNavigateToSettings,
    this.userData,
    this.isActive = true,
    required this.isDarkMode,
    required this.onThemeToggle,
    required this.onLanguageChange,
    required this.onProfileTap,
    required this.onProgressTap,
    required this.onLeaderboardTap,
    required this.onTrickListTap,
    required this.onFriendsTap,
    required this.onSessionGoalsTap,
    required this.onEquipmentTap,
    required this.onSettingsTap,
    this.isMenuExpanded = false,
    this.onToggleMenu,
    required this.onMenuTap,
  });

  final AppLocalizations localizations;
  final bool isLoggedIn;
  final VoidCallback onLogin;
  final VoidCallback onNavigateToSettings;
  final Map<String, dynamic>? userData;
  final bool isActive;
  final bool isDarkMode;
  final Function(bool) onThemeToggle;
  final Function(String) onLanguageChange;
  final VoidCallback onProfileTap;
  final VoidCallback onProgressTap;
  final VoidCallback onLeaderboardTap;
  final VoidCallback onTrickListTap;
  final VoidCallback onFriendsTap;
  final VoidCallback onSessionGoalsTap;
  final VoidCallback onEquipmentTap;
  final VoidCallback onSettingsTap;
  final bool isMenuExpanded;
  final VoidCallback? onToggleMenu;
  final VoidCallback onMenuTap;

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  final ApiService _apiService = ApiService();
  List<dynamic> _leaderboard = [];
  List<dynamic> _categories = [];
  List<int> _friendIds = [];
  List<int> _blockedUserIds = [];
  bool _isLoading = true;
  int? _selectedCategoryId;
  String _selectedStance = 'ALL';

  @override
  void initState() {
    super.initState();
    if (widget.isLoggedIn) {
      _loadData();
    } else {
      _isLoading = false;
    }
  }

  @override
  void didUpdateWidget(LeaderboardPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isLoggedIn && widget.isLoggedIn) {
      _loadData();
    } else if (widget.isLoggedIn && widget.isActive && !oldWidget.isActive) {
      _loadData(silent: true); 
    }
  }

  bool get _isUserPublic => widget.userData?['isPublic'] ?? widget.userData?['is_public'] ?? true;

  Future<void> _loadData({bool silent = false}) async {
    if (!silent) {
      setState(() => _isLoading = true);
    }
    
    try {
      final results = await Future.wait([
        _apiService.getLeaderboard(categoryId: _selectedCategoryId, stance: _selectedStance),
        _apiService.getCategories(),
        _apiService.getCurrentUser(),
      ]);

      if (mounted) {
        setState(() {
          _leaderboard = results[0] as List<dynamic>;
          _categories = results[1] as List<dynamic>;
          
          final user = results[2] as Map<String, dynamic>?;
          if (user != null) {
            _friendIds = List<int>.from(user['friendIds'] ?? user['friend_ids'] ?? []);
            _blockedUserIds = List<int>.from(user['blockedIds'] ?? user['blocked_ids'] ?? []);
          }
          
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatStance(String stance) {
    switch (stance.toUpperCase()) {
      case 'ALL': return widget.localizations.allTricks;
      case 'REGULAR': return widget.localizations.regular;
      case 'NOLLIE': return widget.localizations.nollie;
      case 'SWITCH': return widget.localizations.switchStance;
      case 'FAKIE': return widget.localizations.fakie;
      default: return stance;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    if (!widget.isLoggedIn) {
      return LoginRequiredView(
        localizations: widget.localizations,
        onLogin: widget.onLogin,
        featureName: widget.localizations.leaderboardMenuItem,
        icon: Icons.emoji_events_outlined,
        onMenuTap: widget.onMenuTap,
        isDarkMode: widget.isDarkMode,
        isMenuExpanded: widget.isMenuExpanded,
        onThemeToggle: widget.onThemeToggle,
        onLanguageChange: widget.onLanguageChange,
      );
    }

    if (!_isUserPublic) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_person_outlined, size: 80, color: Colors.grey),
                const SizedBox(height: 24),
                Text(
                  widget.localizations.profileIsPrivate,
                  style: TextStyle(
                    fontSize: 20, 
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  widget.localizations.publicProfileSubtitle,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: widget.onNavigateToSettings,
                  icon: const Icon(Icons.settings),
                  label: Text(widget.localizations.settingsMenuItem),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final filteredLeaderboard = _leaderboard.where((entry) {
      final dynamic rawId = entry['id'];
      final int? userId = rawId != null 
          ? (rawId is int ? rawId : int.tryParse(rawId.toString()))
          : null;
      
      if (userId != null && _blockedUserIds.contains(userId)) return false;
      
      final int count = entry['completedCount'] ?? 0;
      return count > 0;
    }).toList();

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              children: [
                DropdownButtonFormField<int?>(
                  value: _selectedCategoryId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: widget.localizations.trickListMenuItem,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    DropdownMenuItem<int?>(
                      value: null,
                      child: Text(widget.localizations.allTricks),
                    ),
                    ..._categories.map((cat) {
                      return DropdownMenuItem<int?>(
                        value: cat['id'],
                        child: Text(cat['name'] ?? widget.localizations.category),
                      );
                    }).toList(),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedCategoryId = value;
                    });
                    _loadData();
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedStance,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: widget.localizations.stance,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: ['ALL', 'REGULAR', 'NOLLIE', 'SWITCH', 'FAKIE'].map((stance) {
                    return DropdownMenuItem<String>(
                      value: stance,
                      child: Text(_formatStance(stance)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedStance = value;
                      });
                      _loadData();
                    }
                  },
                ),
              ],
            ),
          ),
          
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _loadData(silent: true),
              child: _isLoading && _leaderboard.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : filteredLeaderboard.isEmpty
                      ? ListView(children: [Center(child: Padding(
                          padding: const EdgeInsets.only(top: 100),
                          child: Text(widget.localizations.noUsersFound),
                        ))])
                      : ListView.builder(
                          itemCount: filteredLeaderboard.length,
                          itemBuilder: (context, index) {
                            final entry = filteredLeaderboard[index];
                            final int rank = index + 1;
                            final int completedCount = entry['completedCount'] ?? 0;
                            final String name = entry['name'] ?? widget.localizations.guest;
                            final String username = entry['username'] ?? 'User';
                            final String? base64Image = entry['profile_image'] ?? entry['profileImage'];
                            final bool hasCustomImage = base64Image != null && base64Image.isNotEmpty;
                            
                            final dynamic rawId = entry['id'];
                            final int? userId = rawId != null 
                                ? (rawId is int ? rawId : int.tryParse(rawId.toString()))
                                : null;
                            
                            final bool isFriend = userId != null && _friendIds.contains(userId);

                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(15),
                                onTap: userId == null ? null : () {
                                  Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      transitionDuration: const Duration(milliseconds: 300),
                                      reverseTransitionDuration: const Duration(milliseconds: 250),
                                      pageBuilder: (context, animation, secondaryAnimation) => FadeTransition(
                                        opacity: animation,
                                        child: PublicProfilePage(
                                          localizations: widget.localizations,
                                          userId: userId,
                                          username: username,
                                          isLoggedIn: widget.isLoggedIn,
                                          currentUserData: widget.userData,
                                          isDarkMode: widget.isDarkMode,
                                          onThemeToggle: widget.onThemeToggle,
                                          onLanguageChange: widget.onLanguageChange,
                                          onProfileTap: widget.onProfileTap,
                                          onProgressTap: widget.onProgressTap,
                                          onLeaderboardTap: widget.onLeaderboardTap,
                                          onTrickListTap: widget.onTrickListTap,
                                          onFriendsTap: widget.onFriendsTap,
                                          onSessionGoalsTap: widget.onSessionGoalsTap,
                                          onEquipmentTap: widget.onEquipmentTap,
                                          onSettingsTap: widget.onSettingsTap,
                                          isMenuExpanded: widget.isMenuExpanded,
                                          onToggleMenu: widget.onToggleMenu,
                                        ),
                                      ),
                                    ),
                                  ).then((_) {
                                    // PROFI-FIX: Refresh verzögern um Animation nicht zu stören
                                    Future.delayed(const Duration(milliseconds: 300), () {
                                      if (mounted) _loadData(silent: true);
                                    });
                                  }); 
                                },
                                child: ListTile(
                                  leading: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 35,
                                        child: Text(
                                          '#$rank',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: _getRankColor(rank, isDark),
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Hero(
                                        tag: 'avatar_$userId',
                                        child: CircleAvatar(
                                          backgroundColor: Colors.grey.withOpacity(0.2),
                                          backgroundImage: hasCustomImage
                                              ? MemoryImage(const Base64Decoder().convert(base64Image))
                                              : const AssetImage('assets/Default_Profile_Pic.png') as ImageProvider,
                                        ),
                                      ),
                                    ],
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                                      if (isFriend)
                                        Container(
                                          margin: const EdgeInsets.only(left: 8),
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: Colors.blue.withOpacity(0.3)),
                                          ),
                                          child: Text(
                                            widget.localizations.friend.toUpperCase(),
                                            style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.blue),
                                          ),
                                        ),
                                    ],
                                  ),
                                  subtitle: Text('@$username'),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '$completedCount ${widget.localizations.tricks}',
                                      style: TextStyle(
                                        color: isDark ? AppColors.secondary : AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank, bool isDark) {
    if (rank == 1) return Colors.amber[700]!;
    if (rank == 2) return Colors.grey[isDark ? 400 : 600]!;
    if (rank == 3) return Colors.brown[isDark ? 300 : 600]!;
    return isDark ? Colors.white70 : Colors.black54;
  }
}
