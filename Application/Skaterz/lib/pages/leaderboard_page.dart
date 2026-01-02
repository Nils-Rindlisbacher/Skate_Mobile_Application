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
    required this.onMenuTap,
    this.userData,
    this.isActive = true,
  });

  final AppLocalizations localizations;
  final bool isLoggedIn;
  final VoidCallback onLogin;
  final VoidCallback onNavigateToSettings;
  final VoidCallback onMenuTap;
  final Map<String, dynamic>? userData;
  final bool isActive;

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  final ApiService _apiService = ApiService();
  List<dynamic> _leaderboard = [];
  List<dynamic> _categories = [];
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
      setState(() => _isLoading = true);
      _loadData();
    } else if (widget.isLoggedIn && widget.isActive && !oldWidget.isActive) {
      _loadData(); // Refresh data when page becomes active
    }
  }

  bool get _isUserPublic => widget.userData?['isPublic'] ?? widget.userData?['is_public'] ?? true;

  Future<void> _loadData() async {
    final cacheKey = 'leaderboard_${_selectedCategoryId ?? 'all'}_$_selectedStance';
    
    final cachedLeaderboard = await _apiService.getCachedData(cacheKey);
    final cachedCategories = await _apiService.getCachedData('categories');
    
    if (mounted && (cachedLeaderboard != null || cachedCategories != null)) {
      setState(() {
        if (cachedLeaderboard != null) _leaderboard = cachedLeaderboard;
        if (cachedCategories != null) _categories = cachedCategories;
        _isLoading = false;
      });
    }

    try {
      final results = await Future.wait([
        _apiService.getLeaderboard(categoryId: _selectedCategoryId, stance: _selectedStance),
        _apiService.getCategories(),
      ]);

      if (mounted) {
        setState(() {
          _leaderboard = results[0];
          _categories = results[1];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && _leaderboard.isEmpty) {
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
    final bool isDesktop = MediaQuery.of(context).size.width > 800;

    if (!widget.isLoggedIn) {
      return LoginRequiredView(
        localizations: widget.localizations,
        onLogin: widget.onLogin,
        featureName: widget.localizations.leaderboardMenuItem,
        icon: Icons.emoji_events_outlined,
        onMenuTap: widget.onMenuTap,
      );
    }

    if (!_isUserPublic) {
      return Scaffold(
        appBar: AppBar(
          flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppColors.primaryGradient)),
          title: Text(widget.localizations.leaderboardMenuItem, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          leading: !isDesktop ? IconButton(
            icon: const Icon(Icons.menu),
            onPressed: widget.onMenuTap,
          ) : null,
        ),
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
      final int count = entry['completedCount'] ?? 0;
      return count > 0;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppColors.primaryGradient)),
        title: Text(
          widget.localizations.leaderboardMenuItem,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: !isDesktop ? IconButton(
          icon: const Icon(Icons.menu),
          onPressed: widget.onMenuTap,
        ) : null,
      ),
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
                      _isLoading = true;
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
                        _isLoading = true;
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
              onRefresh: _loadData,
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
                            final String? base64Image = entry['profile_image'];
                            
                            final dynamic rawId = entry['id'];
                            final int? userId = rawId != null 
                                ? (rawId is int ? rawId : int.tryParse(rawId.toString()))
                                : null;

                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(15),
                                onTap: userId == null ? null : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PublicProfilePage(
                                        localizations: widget.localizations,
                                        userId: userId,
                                        username: entry['username'] ?? 'User',
                                      ),
                                    ),
                                  );
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
                                      CircleAvatar(
                                        backgroundColor: Colors.grey.withOpacity(0.2),
                                        backgroundImage: (base64Image != null && base64Image.isNotEmpty)
                                            ? MemoryImage(const Base64Decoder().convert(base64Image))
                                            : null,
                                        child: (base64Image == null || base64Image.isEmpty) 
                                            ? Icon(Icons.person, color: isDark ? Colors.white70 : Colors.grey) 
                                            : null,
                                      ),
                                    ],
                                  ),
                                  title: Text(
                                    name,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text('@${entry['username'] ?? ''}'),
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
