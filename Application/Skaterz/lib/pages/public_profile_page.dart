
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:skaterz/l10n/app_localizations.dart';
import 'package:skaterz/models/skating_session.dart';
import 'package:skaterz/services/api_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:skaterz/core/constants.dart';
import 'package:skaterz/widgets/skate_heatmap.dart';

enum TrackerView { category, stance }

class PublicProfilePage extends StatefulWidget {
  const PublicProfilePage({
    super.key,
    required this.localizations,
    required this.userId,
    required this.username,
  });

  final AppLocalizations localizations;
  final int userId;
  final String username;

  @override
  State<PublicProfilePage> createState() => _PublicProfilePageState();
}

class _PublicProfilePageState extends State<PublicProfilePage> {
  final ApiService _apiService = ApiService();
  TrackerView _currentView = TrackerView.category;
  int? _touchedIndex;
  
  bool _isFriend = false;
  int _friendCount = 0;
  bool _isInitialized = false;

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

  String _formatStance(String stance) {
    switch (stance.toUpperCase()) {
      case 'REGULAR': return widget.localizations.regular;
      case 'NOLLIE': return widget.localizations.nollie;
      case 'SWITCH': return widget.localizations.switchStance;
      case 'FAKIE': return widget.localizations.fakie;
      default: return stance;
    }
  }

  Future<Map<String, dynamic>> _loadProfileData() async {
    final List<Future<dynamic>> requests = [
      _apiService.getCategoryStats(userId: widget.userId),
      _apiService.getUserProfile(widget.userId),
      _apiService.getCompletedTricks(userId: widget.userId),
      _apiService.getSkatingSessions(userId: widget.userId),
      _apiService.getCurrentUser(), 
      // Fetching equipment for public profile
      _apiService.getEquipment(), // In production, this would need a userId parameter
    ];
    
    final results = await Future.wait(requests);
    
    if (!_isInitialized) {
      final currentUser = results[4] as Map<String, dynamic>?;
      if (currentUser != null) {
        final friends = (currentUser['friendIds'] ?? currentUser['friend_ids'] ?? []) as List;
        _isFriend = friends.contains(widget.userId);
      }
      
      final profile = results[1] as Map<String, dynamic>?;
      if (profile != null) {
        _friendCount = (profile['friendCount'] ?? profile['friend_count'] ?? 0) as int;
      }
      _isInitialized = true;
    }

    return {
      'stats': results[0],
      'profile': results[1],
      'completedTricks': results[2],
      'sessions': results[3],
      'equipment': results[5],
    };
  }

  void _handleFriendToggle() async {
    try {
      if (_isFriend) {
        await _apiService.removeFriend(widget.userId);
        setState(() {
          _isFriend = false;
          _friendCount--;
        });
      } else {
        await _apiService.addFriend(widget.userId);
        setState(() {
          _isFriend = true;
          _friendCount++;
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _showOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(_isFriend ? Icons.person_remove_outlined : Icons.person_add_outlined),
              title: Text(_isFriend ? widget.localizations.unfriend : widget.localizations.addFriend),
              onTap: () {
                Navigator.pop(context);
                _handleFriendToggle();
              },
            ),
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
                      Navigator.pop(context); // Go back from profile
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _loadProfileData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('${widget.localizations.error}: ${snapshot.error}'));
          }

          final stats = snapshot.data!['stats'] as List<dynamic>;
          final profile = snapshot.data!['profile'] as Map<String, dynamic>;
          final completedTricks = snapshot.data!['completedTricks'] as List<dynamic>;
          final sessionsData = snapshot.data!['sessions'] as List<dynamic>;
          final equipment = snapshot.data!['equipment'] as List<dynamic>;
          final List<SkatingSession> sessions = sessionsData.map((s) => SkatingSession.fromJson(s)).toList();
          final String? base64Image = profile['profile_image'] ?? profile['profileImage'];
          final bool hasCustomImage = base64Image != null && base64Image.isNotEmpty;

          final activeEquipment = equipment.where((e) => e['isActive'] == true || e['active'] == true).toList();

          int totalBaseTricks = 0;
          for (var cat in stats) {
            totalBaseTricks += (cat['totalTricks'] as num).toInt();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: hasCustomImage
                      ? MemoryImage(const Base64Decoder().convert(base64Image))
                      : const AssetImage('assets/Default_Profile_Pic.png') as ImageProvider,
                ),
                SizedBox(height: 16),
                Text(
                  profile['name'] ?? widget.username,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text('@${widget.username}', style: TextStyle(fontSize: 16, color: Colors.grey)),
                SizedBox(height: 8),
                Text(
                  '$_friendCount ${widget.localizations.friends.toUpperCase()}',
                  style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary, fontSize: 12, letterSpacing: 1),
                ),
                SizedBox(height: 24),
                
                ElevatedButton.icon(
                  onPressed: _handleFriendToggle,
                  icon: Icon(_isFriend ? Icons.check : Icons.person_add),
                  label: Text(_isFriend ? widget.localizations.friend.toUpperCase() : widget.localizations.addFriend.toUpperCase()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isFriend ? Colors.grey[200] : AppColors.primary,
                    foregroundColor: _isFriend ? Colors.black87 : Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),

                const SizedBox(height: 32),

                if (activeEquipment.isNotEmpty) ...[
                  _buildSectionHeader(widget.localizations.activeSetup),
                  _buildEquipmentSummary(activeEquipment),
                  const SizedBox(height: 32),
                ],

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
                
                if (_currentView == TrackerView.category) ...[
                  _buildCategoryChart(stats, completedTricks),
                  const SizedBox(height: 32),
                  _buildCategoryList(stats, completedTricks),
                ] else ...[
                  _buildStanceGrid(totalBaseTricks, completedTricks),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12, left: 4),
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.5, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildEquipmentSummary(List<dynamic> activeItems) {
    final deck = activeItems.cast<Map<String, dynamic>>().firstWhere((e) => e['type'] == 'DECK', orElse: () => {});
    final trucks = activeItems.cast<Map<String, dynamic>>().firstWhere((e) => e['type'] == 'TRUCKS', orElse: () => {});
    final wheels = activeItems.cast<Map<String, dynamic>>().firstWhere((e) => e['type'] == 'WHEELS', orElse: () => {});

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSmallSetupIcon(Icons.layers_rounded, deck['brand'] ?? '-', widget.localizations.typeDeck),
          _buildSmallSetupIcon(Icons.settings_input_component_rounded, trucks['brand'] ?? '-', widget.localizations.typeTrucks),
          _buildSmallSetupIcon(Icons.album_rounded, wheels['brand'] ?? '-', widget.localizations.typeWheels),
        ],
      ),
    );
  }

  Widget _buildSmallSetupIcon(IconData icon, String label, String category) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(height: 8),
        Text(category.toUpperCase(), style: const TextStyle(color: Colors.grey, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1)),
        SizedBox(width: 60, child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center)),
      ],
    );
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
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.65,
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

  Widget _buildCategoryChart(List<dynamic> stats, List<dynamic> allCompleted) {
    final activeStats = stats.where((cat) => (cat['completedTricks'] as num) > 0).toList();
    if (activeStats.isEmpty) return SizedBox(height: 200, child: Center(child: Text(widget.localizations.noData)));

    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sections: activeStats.asMap().entries.map((entry) {
            final cat = entry.value;
            return PieChartSectionData(
              color: categoryColors[cat['id']] ?? Colors.grey,
              value: (cat['completedTricks'] as num).toDouble(),
              title: '${cat['completedTricks']}',
              radius: 50,
              titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCategoryList(List<dynamic> stats, List<dynamic> allCompleted) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final cat = stats[index];
        final id = cat['id'];
        final total = (cat['totalTricks'] as num) * 4;
        final count = cat['completedTricks'] as num;
        final progress = count / total;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withOpacity(0.05)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(cat['name'].toString().toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)),
                  Text('${(progress * 100).toInt()}%', style: TextStyle(fontWeight: FontWeight.w900, color: categoryColors[id] ?? AppColors.primary)),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: progress, backgroundColor: Colors.grey.withOpacity(0.1), valueColor: AlwaysStoppedAnimation(categoryColors[id] ?? AppColors.primary), minHeight: 4),
            ],
          ),
        );
      },
    );
  }
}
