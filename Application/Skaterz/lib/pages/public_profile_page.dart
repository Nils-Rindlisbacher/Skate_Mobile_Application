import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:skaterz/l10n/app_localizations.dart';
import 'package:skaterz/models/skating_session.dart';
import 'package:skaterz/services/api_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:skaterz/core/constants.dart';
import 'package:skaterz/widgets/skate_heatmap.dart';
import 'package:skaterz/widgets/side_menu.dart';
import 'package:skaterz/widgets/custom_app_bar.dart';

enum TrackerView { category, stance }

class PublicProfilePage extends StatefulWidget {
  const PublicProfilePage({
    super.key,
    required this.localizations,
    required this.userId,
    required this.username,
    required this.isLoggedIn,
    this.currentUserData,
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
  });

  final AppLocalizations localizations;
  final int userId;
  final String username;
  final bool isLoggedIn;
  final Map<String, dynamic>? currentUserData;
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

  @override
  State<PublicProfilePage> createState() => _PublicProfilePageState();
}

class _PublicProfilePageState extends State<PublicProfilePage> {
  final ApiService _apiService = ApiService();
  TrackerView _currentView = TrackerView.category;
  
  String _relationshipStatus = 'NONE'; // NONE, REQUEST_SENT, REQUEST_RECEIVED, FRIENDS
  int _friendCount = 0;
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _profileData;
  bool _isMenuExpanded = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final Map<int, Color> categoryColors = {
    1: Colors.blue, 2: Colors.red, 3: Colors.green, 
    4: Colors.orange, 5: Colors.purple, 6: Colors.teal, 7: Colors.amber,
  };

  final Map<String, Color> stanceColors = {
    'REGULAR': const Color(0xFFF57C00), 
    'NOLLIE': const Color(0xFFEF6C00),  
    'SWITCH': const Color(0xFFFF9800),  
    'FAKIE': const Color(0xFFFFB74D),   
  };

  bool get _isMe => widget.userId == widget.currentUserData?['id'] || widget.username == widget.currentUserData?['username'];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData({bool silent = false}) async {
    if (!mounted) return;
    if (!silent) setState(() => _isLoading = true);
    
    try {
      final data = await _loadProfileData();
      if (mounted) {
        setState(() {
          _profileData = data;
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<Map<String, dynamic>> _loadProfileData() async {
    final List<Future<dynamic>> requests = [
      _apiService.getCategoryStats(userId: widget.userId),
      _apiService.getUserProfile(widget.userId),
      _apiService.getCompletedTricks(userId: widget.userId),
      _apiService.getSkatingSessions(userId: widget.userId),
      _isMe ? Future.value('NONE') : _apiService.getRelationshipStatus(widget.userId),
    ];
    
    final results = await Future.wait(requests);
    
    final profile = results[1] as Map<String, dynamic>?;
    if (profile != null) {
      _friendCount = (profile['friendCount'] ?? profile['friend_count'] ?? 0) as int;
    }

    _relationshipStatus = results[4] as String;

    return {
      'stats': results[0],
      'profile': results[1],
      'completedTricks': results[2],
      'sessions': results[3],
    };
  }

  void _handleFriendAction() async {
    if (_isMe) return;
    try {
      if (_relationshipStatus == 'NONE') {
        await _apiService.sendFriendRequest(widget.userId);
        setState(() => _relationshipStatus = 'REQUEST_SENT');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.localizations.requestSent)));
      } else if (_relationshipStatus == 'REQUEST_RECEIVED') {
        final pending = await _apiService.getPendingRequests();
        final request = pending.firstWhere((r) => r['sender']['id'] == widget.userId);
        await _apiService.acceptFriendRequest(request['id']);
        _fetchData(silent: true);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.localizations.friendshipAccepted)));
      } else if (_relationshipStatus == 'FRIENDS') {
        _showUnfriendDialog();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _showUnfriendDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.localizations.unfriend),
        content: Text(widget.localizations.unfriendConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(widget.localizations.cancel)),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _apiService.removeFriend(widget.userId);
              _fetchData(silent: true);
            },
            child: Text(widget.localizations.unfriend, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 800;

        final sideMenu = SideMenu(
          localizations: widget.localizations,
          isLoggedIn: widget.isLoggedIn,
          userData: widget.currentUserData,
          isExpanded: _isMenuExpanded,
          isDesktop: isDesktop,
          onToggleMenu: () => setState(() => _isMenuExpanded = !_isMenuExpanded),
          onLanguageChange: widget.onLanguageChange,
          onProfileTap: widget.onProfileTap,
          onTrickListTap: widget.onTrickListTap,
          onProgressTap: widget.onProgressTap,
          onLeaderboardTap: widget.onLeaderboardTap,
          onFriendsTap: widget.onFriendsTap,
          onSessionGoalsTap: widget.onSessionGoalsTap,
          onEquipmentTap: widget.onEquipmentTap,
          onSettingsTap: widget.onSettingsTap,
          isDarkMode: widget.isDarkMode,
          onThemeToggle: widget.onThemeToggle,
        );

        return Scaffold(
          key: _scaffoldKey,
          appBar: CustomAppBar(
            title: widget.username,
            isDarkMode: widget.isDarkMode,
            onMenuTap: isDesktop 
                ? () => setState(() => _isMenuExpanded = !_isMenuExpanded) 
                : () => _scaffoldKey.currentState?.openDrawer(),
            showMenuButton: true,
            isExpanded: _isMenuExpanded,
            isDesktop: isDesktop,
            actions: [
              // Menü-Icon nur anzeigen, wenn es nicht das eigene Profil ist
              if (!_isMe)
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onPressed: _showOptions,
                ),
            ],
          ),
          drawer: isDesktop ? null : sideMenu,
          body: Row(
            children: [
              if (isDesktop) 
                SizedBox(
                  width: _isMenuExpanded ? 320 : 100, 
                  child: sideMenu
                ),
              Expanded(
                child: _isLoading 
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? Center(child: Text('${widget.localizations.error}: $_error'))
                        : RefreshIndicator(
                            onRefresh: () => _fetchData(silent: true),
                            child: _buildContent(context, colorScheme),
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, ColorScheme colorScheme) {
    if (_profileData == null) return const SizedBox.shrink();

    final rawStats = _profileData!['stats'] as List<dynamic>;
    final profile = _profileData!['profile'] as Map<String, dynamic>;
    final completedTricks = _profileData!['completedTricks'] as List<dynamic>;
    final sessionsData = _profileData!['sessions'] as List<dynamic>;
    final List<SkatingSession> sessions = sessionsData.map((s) => SkatingSession.fromJson(s)).toList();
    final String? base64Image = profile['profile_image'] ?? profile['profileImage'];
    final bool hasCustomImage = base64Image != null && base64Image.isNotEmpty;

    // Build category map for quick lookup
    Map<String, int> categoryCounts = {};
    for (var item in completedTricks) {
      final dynamic trick = item['trick'] ?? item;
      final dynamic category = trick['category'] ?? trick['category_id'] ?? trick['categoryId'];
      String? catId;
      if (category is Map) {
        catId = (category['id'] ?? category['category_id'] ?? category['categoryId'])?.toString();
      } else {
        catId = category?.toString();
      }
      if (catId != null) {
        categoryCounts[catId] = (categoryCounts[catId] ?? 0) + 1;
      }
    }

    final List<Map<String, dynamic>> stats = rawStats.map((s) {
      final map = Map<String, dynamic>.from(s as Map);
      final id = map['id']?.toString();
      map['manualCompletedCount'] = categoryCounts[id] ?? 0;
      return map;
    }).toList();

    int totalBaseTricks = 0;
    for (var cat in stats) {
      final dynamic total = cat['totalTricks'] ?? cat['total_tricks'] ?? 0;
      totalBaseTricks += (total as num).toInt();
    }

    // Process recently completed (last 3)
    List<dynamic> recentlyCompleted = List.from(completedTricks);
    recentlyCompleted.sort((a, b) {
      final dateA = a['created_at'] ?? a['createdAt'];
      final dateB = b['created_at'] ?? b['createdAt'];
      if (dateA == null || dateB == null) return 0;
      return DateTime.parse(dateB.toString()).compareTo(DateTime.parse(dateA.toString()));
    });
    recentlyCompleted = recentlyCompleted.take(3).toList();

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: colorScheme.onSurface.withOpacity(0.05),
            backgroundImage: hasCustomImage
                ? MemoryImage(const Base64Decoder().convert(base64Image))
                : const AssetImage('assets/Default_Profile_Pic.png') as ImageProvider,
          ),
          const SizedBox(height: 16),
          Text(
            profile['name'] ?? widget.username,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
          ),
          Text(
            '@${widget.username}', 
            style: TextStyle(fontSize: 16, color: colorScheme.onSurface.withOpacity(0.6)),
          ),
          const SizedBox(height: 8),
          Text(
            '$_friendCount ${widget.localizations.friends.toUpperCase()}',
            style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary, fontSize: 12, letterSpacing: 1),
          ),
          const SizedBox(height: 24),
          
          if (!_isMe) _buildRelationshipButton(colorScheme),

          const SizedBox(height: 32),

          _buildSectionHeader(widget.localizations.activityHeatmap, colorScheme),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.primary.withOpacity(0.1)),
            ),
            child: SkateHeatmap(
              sessions: sessions,
              localizations: widget.localizations,
            ),
          ),

          if (recentlyCompleted.isNotEmpty) ...[
            const SizedBox(height: 32),
            _buildSectionHeader(widget.localizations.recentlyCompleted, colorScheme),
            _buildRecentlyCompleted(recentlyCompleted, colorScheme),
          ],

          const SizedBox(height: 32),

          SegmentedButton<TrackerView>(
            segments: [
              ButtonSegment(value: TrackerView.category, label: Text(widget.localizations.category), icon: const Icon(Icons.category_outlined)),
              ButtonSegment(value: TrackerView.stance, label: Text(widget.localizations.stance), icon: const Icon(Icons.directions_run_rounded)),
            ],
            selected: {_currentView},
            onSelectionChanged: (val) => setState(() => _currentView = val.first),
          ),

          const SizedBox(height: 32),
          
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _currentView == TrackerView.category
              ? Column(
                  key: const ValueKey('category_view'),
                  children: [
                    _buildCategoryChart(stats),
                    const SizedBox(height: 32),
                    _buildCategoryList(stats, colorScheme, completedTricks),
                  ],
                )
              : _buildStanceGrid(totalBaseTricks, completedTricks),
          ),
        ],
      ),
    );
  }

  Widget _buildRelationshipButton(ColorScheme colorScheme) {
    String label = "";
    IconData icon = Icons.person_add;
    Color bgColor = AppColors.primary;
    Color textColor = Colors.white;
    bool enabled = true;

    switch (_relationshipStatus) {
      case 'FRIENDS':
        label = widget.localizations.friend.toUpperCase();
        icon = Icons.check;
        bgColor = colorScheme.onSurface.withOpacity(0.05);
        textColor = colorScheme.onSurface;
        break;
      case 'REQUEST_SENT':
        label = widget.localizations.requestSent.toUpperCase();
        icon = Icons.hourglass_empty;
        bgColor = colorScheme.onSurface.withOpacity(0.05);
        textColor = colorScheme.onSurface.withOpacity(0.5);
        enabled = false;
        break;
      case 'REQUEST_RECEIVED':
        label = widget.localizations.acceptRequest.toUpperCase();
        icon = Icons.check_circle_outline;
        bgColor = Colors.green;
        break;
      default:
        label = widget.localizations.addFriend.toUpperCase();
        icon = Icons.person_add;
    }

    return ElevatedButton.icon(
      onPressed: enabled ? _handleFriendAction : null,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: textColor,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  void _showOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_isMe)
              ListTile(
                leading: Icon(_relationshipStatus == 'FRIENDS' ? Icons.person_remove_outlined : Icons.person_add_outlined),
                title: Text(_relationshipStatus == 'FRIENDS' ? widget.localizations.unfriend : widget.localizations.addFriend),
                onTap: () {
                  Navigator.pop(context);
                  _handleFriendAction();
                },
              ),
            // Man kann sich selbst nicht melden
            if (!_isMe)
              ListTile(
                leading: const Icon(Icons.report_problem_outlined, color: Colors.orange),
                title: Text(widget.localizations.reportUser),
                onTap: () {
                  Navigator.pop(context);
                  _confirmAction(
                    widget.localizations.reportUser,
                    widget.localizations.reportConfirm,
                    () async {
                      await _apiService.reportUser(widget.userId, "Inappropriate content");
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.localizations.userReported)));
                    }
                  );
                },
              ),
            if (!_isMe)
              ListTile(
                leading: const Icon(Icons.block, color: Colors.red),
                title: Text(widget.localizations.blockUser, style: const TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmAction(
                    widget.localizations.blockUser,
                    widget.localizations.blockConfirm,
                    () async {
                      await _apiService.blockUser(widget.userId);
                      if (mounted) {
                        Navigator.pop(context); 
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.localizations.userBlocked)));
                      }
                    }
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _confirmAction(String title, String message, Future<void> Function() action) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(widget.localizations.cancel)),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await action();
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, ColorScheme colorScheme) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12, left: 4),
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            color: colorScheme.onSurface.withOpacity(0.5), 
            letterSpacing: 1.5, 
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildRecentlyCompleted(List<dynamic> tricks, ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.onSurface.withOpacity(0.05)),
      ),
      child: Column(
        children: tricks.map((trick) {
          final String stance = trick['stance'] ?? 'REGULAR';
          final String name = trick['name'] ?? trick['trick']?['name'] ?? widget.localizations.tricks;
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.check_circle_rounded, color: stanceColors[stance.toUpperCase()] ?? AppColors.primary, size: 20),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(_formatStance(stance)),
          );
        }).toList(),
      ),
    );
  }

  String _formatStance(String stance) {
    switch (stance.toUpperCase()) {
      case 'REGULAR': return widget.localizations.regular;
      case 'NOLLIE': return widget.localizations.nollie;
      case 'SWITCH': return widget.localizations.switchStance;
      case 'FAKIE': return widget.localizations.fakie;
      default: return stance;
    }
  }

  Widget _buildStanceGrid(int totalPerStance, List<dynamic> completedTricks) {
    Map<String, int> stanceCounts = {'REGULAR': 0, 'NOLLIE': 0, 'SWITCH': 0, 'FAKIE': 0};
    for (var item in completedTricks) {
      final stance = (item['stance'] ?? 'REGULAR').toString().toUpperCase();
      stanceCounts[stance] = (stanceCounts[stance] ?? 0) + 1;
    }
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 0.65,
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        final stance = stanceColors.keys.elementAt(index);
        final color = stanceColors[stance]!;
        final count = stanceCounts[stance] ?? 0;
        final double progress = totalPerStance > 0 ? count / totalPerStance : 0;
        return Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.1)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(stance.substring(0, 3).toUpperCase(), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: color, letterSpacing: 0.5)),
              const SizedBox(height: 12),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 45, height: 45,
                      child: CircularProgressIndicator(
                        value: progress, strokeWidth: 4,
                        backgroundColor: color.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Text('${(progress * 100).toStringAsFixed(0)}%', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text('$count/$totalPerStance', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryChart(List<dynamic> stats) {
    final activeStats = stats.where((cat) => (cat['manualCompletedCount'] as num) > 0).toList();
    if (activeStats.isEmpty) return SizedBox(height: 200, child: Center(child: Text(widget.localizations.noData)));
    return SizedBox(
      height: 200,
      child: PieChart(PieChartData(
          sections: activeStats.asMap().entries.map((entry) {
            final cat = entry.value;
            return PieChartSectionData(
              color: categoryColors[cat['id']] ?? Colors.grey,
              value: (cat['manualCompletedCount'] as num).toDouble(),
              title: '${cat['manualCompletedCount']}',
              radius: 50,
              titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            );
          }).toList(),
      )),
    );
  }

  Widget _buildCategoryList(List<dynamic> stats, ColorScheme colorScheme, List<dynamic> completedTricks) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final cat = stats[index];
        final id = cat['id'];
        final dynamic catTotal = cat['totalTricks'] ?? cat['total_tricks'] ?? 0;
        final total = (catTotal as num) * 4;
        final count = (cat['manualCompletedCount'] ?? 0) as num;
        final progress = total > 0 ? count / total : 0;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: colorScheme.onSurface.withOpacity(0.05))),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _showCategoryTricks(context, id, cat['name'] ?? '', completedTricks),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(cat['name'].toString().toUpperCase(), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1, color: colorScheme.onSurface)),
                      Text('${(progress * 100).toInt()}%', style: TextStyle(fontWeight: FontWeight.w900, color: categoryColors[id] ?? AppColors.primary)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress.toDouble(), 
                    backgroundColor: colorScheme.onSurface.withOpacity(0.05), 
                    valueColor: AlwaysStoppedAnimation(categoryColors[id] ?? AppColors.primary), 
                    minHeight: 4,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showCategoryTricks(BuildContext context, dynamic categoryId, String categoryName, List<dynamic> completed) {
    final categoryTricks = completed.where((item) {
      final dynamic trick = item['trick'] ?? item;
      final dynamic category = trick['category'] ?? trick['category_id'] ?? trick['categoryId'];
      String? catId;
      if (category is Map) {
        catId = (category['id'] ?? category['category_id'] ?? category['categoryId'])?.toString();
      } else {
        catId = category?.toString();
      }
      return catId == categoryId.toString();
    }).toList();

    final Map<String, List<String>> grouped = {};
    for (var t in categoryTricks) {
      final name = t['name'] ?? t['trick']?['name'] ?? widget.localizations.tricks;
      if (!grouped.containsKey(name)) grouped[name] = [];
      grouped[name]!.add(t['stance'] ?? 'REGULAR');
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(30))),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text(categoryName.toUpperCase(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 2, color: Theme.of(context).colorScheme.onSurface)),
            const Divider(),
            Expanded(
              child: grouped.isEmpty
                  ? Center(child: Text(widget.localizations.noTricksYet))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: grouped.length,
                      itemBuilder: (context, index) {
                        final name = grouped.keys.elementAt(index);
                        final stances = grouped[name]!;
                        return ListTile(
                          title: Text(name, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                          subtitle: Wrap(
                            spacing: 8,
                            children: ['REGULAR', 'NOLLIE', 'SWITCH', 'FAKIE'].map((s) {
                              final isDone = stances.contains(s);
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked, size: 14, color: isDone ? stanceColors[s] : Colors.grey.withOpacity(0.3)),
                                  const SizedBox(width: 4),
                                  Text(s.substring(0, 1), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDone ? stanceColors[s] : Colors.grey.withOpacity(0.3))),
                                ],
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
}
