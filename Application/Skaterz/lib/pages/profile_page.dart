import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:skaterz/l10n/app_localizations.dart';
import 'package:skaterz/models/skating_session.dart';
import 'package:skaterz/services/api_service.dart';
import 'package:skaterz/core/constants.dart';
import 'package:skaterz/widgets/skate_heatmap.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.localizations,
    required this.onLogout,
    required this.onUserDataChanged,
    required this.isLoggedIn,
    required this.onMenuTap,
    this.isActive = true,
  });

  final AppLocalizations localizations;
  final VoidCallback onLogout;
  final VoidCallback onUserDataChanged;
  final bool isLoggedIn;
  final VoidCallback onMenuTap;
  final bool isActive;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ApiService _apiService = ApiService();
  
  Map<String, dynamic>? _userData;
  List<dynamic> _wishlistTricks = [];
  List<dynamic> _recentlyCompleted = [];
  List<dynamic> _allCompleted = [];
  List<SkatingSession> _sessions = [];
  
  int _totalBaseTricks = 0;
  int _currentStreak = 0;
  bool _alreadySkatedToday = false;
  bool _isLoading = true;
  bool _isWishlistExpanded = false;

  final Map<String, Color> stanceColors = {
    'REGULAR': const Color(0xFF4FC3F7), 
    'NOLLIE': const Color(0xFFFF8A65),  
    'SWITCH': const Color(0xFF9575CD),  
    'FAKIE': const Color(0xFF4DB6AC),   
  };

  @override
  void initState() {
    super.initState();
    if (widget.isLoggedIn) {
      _loadInitialData();
    } else {
      _isLoading = false;
    }
  }

  @override
  void didUpdateWidget(ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isLoggedIn && widget.isLoggedIn) {
      _loadInitialData();
    } else if (widget.isLoggedIn && widget.isActive && !oldWidget.isActive) {
      _loadData(); // Refresh data when page becomes active
    }
  }

  Future<void> _loadInitialData() async {
    try {
      final cacheResults = await Future.wait([
        _apiService.getCachedData('user_me'),
        _apiService.getCachedData('wishlist_tricks'),
        _apiService.getCachedData('completed_tricks'),
        _apiService.getCachedData('skating_sessions'),
        _apiService.getCachedData('cache_total_tricks_count'),
      ]);

      if (mounted) {
        setState(() {
          if (cacheResults[0] != null) _userData = cacheResults[0] as Map<String, dynamic>;
          _wishlistTricks = (cacheResults[1] as List?) ?? [];
          if (cacheResults[2] != null) {
            _allCompleted = cacheResults[2] as List;
            _recentlyCompleted = _processCompletedTricks(_allCompleted);
          }
          if (cacheResults[3] != null) {
            _sessions = (cacheResults[3] as List).map((s) => SkatingSession.fromJson(s)).toList();
            _calculateSessionStats();
          }
          final cachedCount = cacheResults[4];
          if (cachedCount != null) {
            _totalBaseTricks = int.tryParse(cachedCount.toString()) ?? 0;
          }
          
          if (_userData != null || _sessions.isNotEmpty) {
            _isLoading = false;
          }
        });
      }
    } catch (e) {
      debugPrint("Fast Cache Load Error: $e");
    }
    _loadData();
  }

  void _calculateSessionStats() {
    if (_sessions.isEmpty) {
      _currentStreak = 0;
      _alreadySkatedToday = false;
      return;
    }

    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    
    _alreadySkatedToday = _sessions.any((s) => 
      s.sessionDate.year == now.year && 
      s.sessionDate.month == now.month && 
      s.sessionDate.day == now.day
    );

    final sortedSessions = _sessions.map((s) => s.sessionDate).toList()
      ..sort((a, b) => b.compareTo(a));
    
    DateTime lastSessionDate = DateTime(sortedSessions[0].year, sortedSessions[0].month, sortedSessions[0].day);
    int daysSinceLastSession = todayDate.difference(lastSessionDate).inDays;
    
    if (daysSinceLastSession > 1) {
      _currentStreak = 0;
    } else {
      int streak = 0;
      DateTime checkDate = daysSinceLastSession == 0 ? todayDate : lastSessionDate;
      final sessionDays = sortedSessions.map((d) => DateTime(d.year, d.month, d.day)).toSet();

      while (sessionDays.contains(checkDate)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      }
      _currentStreak = streak;
    }
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    try {
      final List<Future<dynamic>> requests = [
        _apiService.getCurrentUser(),
        _apiService.getCompletedTricks(),
        _apiService.getSkatingSessions(),
        _apiService.getTrickCount(),
        _apiService.getWishlistTricks(),
      ];
      
      final results = await Future.wait(requests);

      if (mounted) {
        setState(() {
          _userData = results[0] as Map<String, dynamic>?;
          _allCompleted = (results[1] as List?) ?? [];
          _recentlyCompleted = _processCompletedTricks(_allCompleted);
          
          final sessionsData = results[2] as List?;
          if (sessionsData != null) {
            _sessions = sessionsData.map((s) => SkatingSession.fromJson(s)).toList();
            _calculateSessionStats();
          }
          
          _totalBaseTricks = results[3] as int? ?? 0;
          _wishlistTricks = (results[4] as List?) ?? [];
          
          _isLoading = false;
        });
        
        const storage = FlutterSecureStorage();
        await storage.write(key: 'cache_total_tricks_count', value: _totalBaseTricks.toString());
      }
    } catch (e) {
      debugPrint("API Load Error: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleDeleteSession(DateTime date) async {
    setState(() => _alreadySkatedToday = false);
    try {
      final dateString = date.toIso8601String().split('T')[0];
      await _apiService.deleteSkatingSession(dateString);
      await _loadData();
    } catch (e) {
      if (mounted) {
        _calculateSessionStats();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  List<dynamic> _processCompletedTricks(List<dynamic> tricks) {
    List<dynamic> sorted = List.from(tricks);
    sorted.sort((a, b) {
      final dateA = a['created_at'] ?? a['createdAt'];
      final dateB = b['created_at'] ?? b['createdAt'];
      if (dateA == null || dateB == null) return 0;
      return DateTime.parse(dateB.toString()).compareTo(DateTime.parse(dateA.toString()));
    });
    return sorted.take(3).toList();
  }

  String _formatStance(String stance) {
    if (stance.isEmpty) return "";
    return stance[0].toUpperCase() + stance.substring(1).toLowerCase();
  }

  List<String> _getAvailableStances(String trickName) {
    final name = trickName.toLowerCase();
    if (name == 'ollie' || 
        name == 'nollie' || 
        name == 'rock to fakie' || 
        name == 'rock n roll' || 
        name == 'blunt to fakie') {
      return ['REGULAR'];
    }
    return ['REGULAR', 'NOLLIE', 'SWITCH', 'FAKIE'];
  }

  void _showMoodPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.localizations.sessionMood, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _moodButton('GREAT', '😃', Colors.green, widget.localizations.moodGreat),
                _moodButton('OK', '😐', Colors.blue, widget.localizations.moodOk),
                _moodButton('BAD', '😕', Colors.orange, widget.localizations.moodBad),
                _moodButton('INJURED', '🤕', Colors.red, widget.localizations.moodInjured),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _moodButton(String mood, String emoji, Color color, String localizedMood) {
    return Column(
      children: [
        IconButton(
          icon: Text(emoji, style: const TextStyle(fontSize: 40)),
          onPressed: () async {
            Navigator.pop(context);
            setState(() => _alreadySkatedToday = true);
            try {
              await _apiService.logSkatingSession(mood);
              _loadData();
            } catch (e) {
              if (mounted) {
                _calculateSessionStats();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            }
          },
        ),
        Text(localizedMood, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }

  void _showStanceTricks(String stance) {
    final tricks = _allCompleted.where((item) => (item['stance'] ?? 'REGULAR').toString().toUpperCase() == stance).toList();
    _showTricksSheet(_formatStance(stance), tricks, filteredStance: stance);
  }

  void _showTricksSheet(String title, List<dynamic> tricks, {String? filteredStance}) {
    HapticFeedback.mediumImpact();
    
    // Group tricks by name to show stances as icons
    final Map<String, List<String>> groupedTricks = {};
    for (var t in tricks) {
      final name = t['name'] ?? 'Trick';
      if (!groupedTricks.containsKey(name)) {
        groupedTricks[name] = [];
      }
      groupedTricks[name]!.add(t['stance'] ?? 'REGULAR');
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const Divider(),
            Expanded(
              child: tricks.isEmpty
                  ? Center(child: Text(widget.localizations.noTricksYet))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: groupedTricks.length,
                      itemBuilder: (context, index) {
                        final name = groupedTricks.keys.elementAt(index);
                        final stances = groupedTricks[name]!;
                        
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Row(
                            children: ['REGULAR', 'NOLLIE', 'SWITCH', 'FAKIE'].map((s) {
                              // If filteredStance is provided, we only show icons for that stance
                              if (filteredStance != null && s != filteredStance) {
                                return const SizedBox.shrink();
                              }

                              final isDone = stances.contains(s);
                              return Container(
                                margin: const EdgeInsets.only(right: 8, top: 4),
                                child: Icon(
                                  isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                                  size: 16,
                                  color: isDone ? stanceColors[s] : Colors.grey.withValues(alpha: 0.2),
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleCompleteFromWishlist(dynamic trick, String stance) async {
    final int trickId = trick['id'];
    try {
      // 1. Mark as completed
      await _apiService.toggleCompleted(trickId, false, stance);
      // 2. Remove from wishlist
      await _apiService.toggleWishlist(trickId, true, stance);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${trick['name']} (${_formatStance(stance)}) completed!'))
        );
        _loadData(forceRefresh: true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'))
        );
      }
    }
  }

  void _showWishlistCompleteModal(String trickName, List<String> wishlistedStances, List<dynamic> allTricksInWishlist) {
    final availableStances = _getAvailableStances(trickName);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              trickName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            const SizedBox(height: 12),
            Text(
              widget.localizations.stances,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: availableStances.map((stance) {
                final color = stanceColors[stance] ?? AppColors.primary;
                final bool isWishlisted = wishlistedStances.contains(stance);
                
                return Opacity(
                  opacity: isWishlisted ? 1.0 : 0.5,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (!isWishlisted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('$stance is not in wishlist'))
                        );
                        return;
                      }
                      Navigator.pop(context);
                      final trickData = allTricksInWishlist.firstWhere((t) => (t['stance'] ?? 'REGULAR').toString().toUpperCase() == stance);
                      _handleCompleteFromWishlist(trickData, stance);
                    },
                    icon: Icon(isWishlisted ? Icons.check_circle_outline : Icons.block, size: 20),
                    label: Text(_formatStance(stance)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color.withValues(alpha: 0.1),
                      foregroundColor: color,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppColors.primaryGradient)),
        title: Text(widget.localizations.profileMenuItem, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: !isDesktop ? IconButton(
          icon: const Icon(Icons.menu),
          onPressed: widget.onMenuTap,
        ) : null,
        actions: [
          if (_currentStreak > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_fire_department, color: Colors.orange, size: 20),
                      const SizedBox(width: 4),
                      Text('$_currentStreak', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: (_isLoading && _sessions.isEmpty) || _alreadySkatedToday 
          ? null 
          : FloatingActionButton.extended(
              onPressed: _showMoodPicker,
              icon: const Icon(Icons.skateboarding, color: Colors.white),
              label: Text(widget.localizations.skatedToday, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              backgroundColor: AppColors.primary,
            ),
      body: _isLoading && _userData == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _loadData(forceRefresh: true),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: _buildAvatar()),
                    const SizedBox(height: 16),
                    Center(
                      child: Column(
                        children: [
                          Text(_userData?['name'] ?? 'User', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          Text('@${_userData?['username'] ?? ''}', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                        ],
                      ),
                        ),
                    
                    const SizedBox(height: 32),

                    _buildSectionHeader(widget.localizations.activityHeatmap, Icons.calendar_today_rounded),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: SkateHeatmap(
                        sessions: _sessions,
                        onDeleteSession: _handleDeleteSession,
                        onSessionUpdated: _loadData,
                        localizations: widget.localizations,
                      ),
                    ),

                    const SizedBox(height: 32),

                    _buildSectionHeader(widget.localizations.recentlyCompleted, Icons.history_rounded),
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                      ),
                      child: _recentlyCompleted.isEmpty
                          ? Padding(padding: const EdgeInsets.all(16), child: Text(widget.localizations.noTricksYet))
                          : Column(
                              children: _recentlyCompleted.map((trick) => ListTile(
                                visualDensity: VisualDensity.compact,
                                leading: Icon(
                                  Icons.check_circle,
                                  color: stanceColors[trick['stance']] ?? AppColors.secondary,
                                ),
                                title: Text(trick['name'] ?? ''),
                                subtitle: Text(_formatStance(trick['stance'] ?? 'REGULAR')),
                              )).toList(),
                            ),
                    ),

                    const SizedBox(height: 32),

                    Builder(
                      builder: (context) {
                        // Group wishlist by trick name
                        final Map<String, List<dynamic>> groupedWishlist = {};
                        for (var t in _wishlistTricks) {
                          final name = t['name'] ?? 'Trick';
                          if (!groupedWishlist.containsKey(name)) {
                            groupedWishlist[name] = [];
                          }
                          groupedWishlist[name]!.add(t);
                        }

                        final trickNames = groupedWishlist.keys.toList();
                        final displayCount = _isWishlistExpanded ? trickNames.length : (trickNames.length > 5 ? 5 : trickNames.length);
                        final displayTrickNames = trickNames.take(displayCount).toList();
                        
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader(widget.localizations.wishlist, Icons.favorite_rounded, color: Colors.red, count: _wishlistTricks.length),
                            Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                              ),
                              child: trickNames.isEmpty
                                  ? Padding(padding: const EdgeInsets.all(16), child: Text(widget.localizations.wishlistEmpty))
                                  : Column(
                                      children: [
                                        ListView.builder(
                                          shrinkWrap: true,
                                          physics: const NeverScrollableScrollPhysics(),
                                          itemCount: displayTrickNames.length,
                                          itemBuilder: (context, index) {
                                            final name = displayTrickNames[index];
                                            final tricks = groupedWishlist[name]!;
                                            final stances = tricks.map((t) => (t['stance'] ?? 'REGULAR').toString().toUpperCase()).toList();

                                            return ListTile(
                                              leading: const Icon(Icons.skateboarding, color: AppColors.primary),
                                              title: Text(name),
                                              subtitle: Row(
                                                children: ['REGULAR', 'NOLLIE', 'SWITCH', 'FAKIE'].map((s) {
                                                  final active = stances.contains(s);
                                                  return Container(
                                                    margin: const EdgeInsets.only(right: 4),
                                                    child: Icon(
                                                      active ? Icons.favorite : Icons.favorite_border,
                                                      size: 14,
                                                      color: active ? stanceColors[s] : Colors.grey.withValues(alpha: 0.2),
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                              trailing: ElevatedButton(
                                                onPressed: () => _showWishlistCompleteModal(name, stances, tricks),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.green.withValues(alpha: 0.1),
                                                  foregroundColor: Colors.green,
                                                  elevation: 0,
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                                ),
                                                child: Text(widget.localizations.complete),
                                              ),
                                            );
                                          },
                                        ),
                                        if (trickNames.length > 5)
                                          TextButton(
                                            onPressed: () {
                                              setState(() {
                                                _isWishlistExpanded = !_isWishlistExpanded;
                                              });
                                            },
                                            child: Text(_isWishlistExpanded ? "Show Less" : "Show More"),
                                          ),
                                      ],
                                    ),
                            ),
                          ],
                        );
                      }
                    ),

                    const SizedBox(height: 32),
                    
                    _buildSectionHeader(widget.localizations.mastery, Icons.bolt_rounded),
                    _buildStanceMasteryGrid(),
                    
                    const SizedBox(height: 40),
                    
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: widget.onLogout,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red, width: 1.5),
                          padding: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(widget.localizations.logoutButton, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, {Color? color, int? count, int? total}) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: color ?? AppColors.primary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color ?? AppColors.primary, letterSpacing: 0.5)),
                if (count != null)
                  Text(
                    total != null ? '$count / $total' : '($count)', 
                    style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w600)
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStanceMasteryGrid() {
    Map<String, int> counts = {'REGULAR': 0, 'NOLLIE': 0, 'SWITCH': 0, 'FAKIE': 0};
    for (var item in _allCompleted) {
      final stance = (item['stance'] ?? 'REGULAR').toString().toUpperCase();
      counts[stance] = (counts[stance] ?? 0) + 1;
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 2.0,
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        final stance = stanceColors.keys.elementAt(index);
        final count = counts[stance] ?? 0;
        final color = stanceColors[stance]!;
        
        final int denominator = _totalBaseTricks > 0 ? _totalBaseTricks : 233;
        final double progress = count / denominator;

        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            _showStanceTricks(stance);
          },
          child: Container(
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 5,
                        backgroundColor: color.withValues(alpha: 0.15),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}%', 
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_formatStance(stance), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvatar() {
    final String? base64String = _userData?['profile_image'] ?? _userData?['profileImage'];
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.primaryGradient,
          ),
          child: CircleAvatar(
            radius: 54,
            backgroundColor: Colors.white,
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey[200],
              backgroundImage: (base64String != null && base64String.isNotEmpty)
                  ? MemoryImage(const Base64Decoder().convert(base64String)) 
                  : null,
              child: (base64String == null || base64String.isEmpty)
                  ? const Icon(Icons.person, size: 50, color: Colors.grey) 
                  : null,
            ),
          ),
        ),
        Positioned(
          bottom: 4,
          right: 4,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: CircleAvatar(
              backgroundColor: AppColors.primary,
              radius: 16,
              child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
