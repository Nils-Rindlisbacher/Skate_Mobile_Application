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

  final Map<int, Color> categoryColors = {
    1: Colors.blue, 2: Colors.red, 3: Colors.green, 
    4: Colors.orange, 5: Colors.purple, 6: Colors.teal, 7: Colors.amber,
  };

  final Map<String, Color> stanceColors = {
    'REGULAR': const Color(0xFF4FC3F7), 
    'NOLLIE': const Color(0xFFFF8A65),  
    'SWITCH': const Color(0xFF9575CD),  
    'FAKIE': const Color(0xFF4DB6AC),   
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
    ];
    
    final results = await Future.wait(requests);
    return {
      'stats': results[0],
      'profile': results[1],
      'completedTricks': results[2],
      'sessions': results[3],
    };
  }

  Future<void> _showTricksSheet(BuildContext context, String title, int? categoryId, List<dynamic> allCompleted, {String? filteredStance}) async {
    HapticFeedback.mediumImpact();
    
    // Group tricks by name to show stances as icons
    final Map<String, List<String>> groupedTricks = {};
    
    // Filter the provided completed tricks list
    final filteredList = allCompleted.where((item) {
      if (categoryId != null) {
        final trickCatId = (item['category_id'] ?? item['categoryId'] ?? 
                           (item['category'] != null ? item['category']['id'] : null))?.toString();
        if (trickCatId != categoryId.toString()) return false;
      }
      if (filteredStance != null) {
        if ((item['stance'] ?? 'REGULAR').toString().toUpperCase() != filteredStance.toUpperCase()) return false;
      }
      return true;
    }).toList();

    for (var t in filteredList) {
      final name = t['name'] ?? widget.localizations.tricks;
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
              child: groupedTricks.isEmpty
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
                              if (filteredStance != null && s != filteredStance) return const SizedBox.shrink();
                              
                              final isDone = stances.contains(s);
                              final label = s == 'REGULAR' ? 'R' : (s == 'NOLLIE' ? 'N' : (s == 'SWITCH' ? 'S' : 'F'));
                              return Container(
                                margin: const EdgeInsets.only(right: 12, top: 4),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                                      size: 16,
                                      color: isDone ? stanceColors[s] : Colors.grey.withValues(alpha: 0.2),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      label,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isDone ? stanceColors[s] : Colors.grey.withValues(alpha: 0.4),
                                      ),
                                    ),
                                  ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppColors.primaryGradient)),
        title: Text(widget.username, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
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
          final List<SkatingSession> sessions = sessionsData.map((s) => SkatingSession.fromJson(s)).toList();
          final String? base64Image = profile['profile_image'] ?? profile['profileImage'];

          int totalBaseTricks = 0;
          int totalCompletedVariations = completedTricks.length;

          for (var cat in stats) {
            totalBaseTricks += (cat['totalTricks'] as num).toInt();
          }

          int totalPossible = totalBaseTricks * 4;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: (base64Image != null && base64Image.isNotEmpty)
                      ? MemoryImage(const Base64Decoder().convert(base64Image))
                      : null,
                  child: (base64Image == null || base64Image.isEmpty)
                      ? const Icon(Icons.person, size: 60, color: Colors.grey)
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  profile['name'] ?? widget.username,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text('@${widget.username}', style: const TextStyle(fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 32),

                // Activity Heatmap
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
                    sessions: sessions,
                    localizations: widget.localizations,
                  ),
                ),

                const SizedBox(height: 32),

                SegmentedButton<TrackerView>(
                  segments: [
                    ButtonSegment(value: TrackerView.category, label: Text(widget.localizations.category), icon: const Icon(Icons.category)),
                    ButtonSegment(value: TrackerView.stance, label: Text(widget.localizations.stance), icon: const Icon(Icons.directions_run)),
                  ],
                  selected: {_currentView},
                  onSelectionChanged: (val) => setState(() => _currentView = val.first),
                ),

                const SizedBox(height: 32),
                
                if (_currentView == TrackerView.category) ...[
                  Text(
                    '$totalCompletedVariations / $totalPossible ${widget.localizations.tricksCompleted}',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  const SizedBox(height: 24),
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
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        final stance = stanceColors.keys.elementAt(index);
        final color = stanceColors[stance]!;
        final count = stanceCounts[stance] ?? 0;
        final double progress = totalPerStance > 0 ? count / totalPerStance : 0;

        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            _showTricksSheet(context, _formatStance(stance), null, completedTricks, filteredStance: stance);
          },
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: color.withValues(alpha: 0.1), width: 1),
            ),
            color: color.withValues(alpha: 0.03),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _formatStance(stance),
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 8,
                            backgroundColor: color.withValues(alpha: 0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('$count', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                            Text('/$totalPerStance', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('${(progress * 100).toStringAsFixed(0)}%', style: TextStyle(fontWeight: FontWeight.bold, color: color.withValues(alpha: 0.8))),
                ],
              ),
            ),
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
          pieTouchData: PieTouchData(
            touchCallback: (FlTouchEvent event, pieTouchResponse) {
              setState(() {
                if (!event.isInterestedForInteractions || pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
                  _touchedIndex = -1;
                  return;
                }
                _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                if (event is FlTapUpEvent) {
                  final cat = activeStats[_touchedIndex!];
                  _showTricksSheet(context, cat['name'] ?? widget.localizations.category, cat['id'], allCompleted); 
                }
              });
            },
          ),
          sections: activeStats.asMap().entries.map((entry) {
            final idx = entry.key;
            final cat = entry.value;
            final isTouched = idx == _touchedIndex;
            return PieChartSectionData(
              color: categoryColors[cat['id']] ?? Colors.grey,
              value: (cat['completedTricks'] as num).toDouble(),
              title: '${cat['completedTricks']}',
              radius: isTouched ? 60 : 50,
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
        return ListTile(
          onTap: () => _showTricksSheet(context, cat['name'] ?? widget.localizations.category, cat['id'], allCompleted),
          leading: CircleAvatar(radius: 8, backgroundColor: categoryColors[cat['id']] ?? Colors.grey),
          title: Text(cat['name'] ?? widget.localizations.category),
          trailing: Text(
            '${cat['completedTricks']}/${(cat['totalTricks'] as num) * 4}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        );
      },
    );
  }
}
