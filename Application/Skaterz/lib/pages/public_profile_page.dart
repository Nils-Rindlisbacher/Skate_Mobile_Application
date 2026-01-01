import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:skaterz/l10n/app_localizations.dart';
import 'package:skaterz/services/api_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:skaterz/core/constants.dart';

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
    if (stance.isEmpty) return "";
    return stance[0].toUpperCase() + stance.substring(1).toLowerCase();
  }

  Future<Map<String, dynamic>> _loadProfileData() async {
    final stats = await _apiService.getCategoryStats(userId: widget.userId);
    final userProfile = await _apiService.getUserProfile(widget.userId);
    return {
      'stats': stats,
      'profile': userProfile,
    };
  }

  Future<void> _showTricksSheet(BuildContext context, String title, int? categoryId) async {
    HapticFeedback.mediumImpact();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FutureBuilder<List<dynamic>>(
        future: _apiService.getTricks(categoryId: categoryId, size: 1000), // Note: This might show ALL tricks, we need completed only
        // Ideally we'd have a getCompletedTricks(userId, categoryId) endpoint.
        // For now, let's just group whatever data we have.
        builder: (context, snapshot) {
          return Container(
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
                  child: snapshot.connectionState == ConnectionState.waiting
                      ? const Center(child: CircularProgressIndicator())
                      : (snapshot.data == null || snapshot.data!.isEmpty)
                          ? Center(child: Text(widget.localizations.noTricksYet))
                          : _buildGroupedTrickList(snapshot.data!),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildGroupedTrickList(List<dynamic> tricks) {
    // Group tricks by name
    final Map<String, List<String>> groupedTricks = {};
    for (var t in tricks) {
      // Filter for completed tricks only if the data contains flags
      final name = t['name'] ?? 'Trick';
      final stances = t['stances'] as Map<String, dynamic>?;
      
      if (stances != null) {
        final completedStances = stances.entries
            .where((e) => e.value['completed'] == true)
            .map((e) => e.key)
            .toList();
        
        if (completedStances.isNotEmpty) {
          groupedTricks[name] = completedStances;
        }
      }
    }

    if (groupedTricks.isEmpty) {
      return Center(child: Text(widget.localizations.noTricksYet));
    }

    final sortedNames = groupedTricks.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: sortedNames.length,
      itemBuilder: (context, index) {
        final name = sortedNames[index];
        final stances = groupedTricks[name]!;
        
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Row(
            children: ['REGULAR', 'NOLLIE', 'SWITCH', 'FAKIE'].map((s) {
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
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final stats = snapshot.data!['stats'] as List<dynamic>;
          final profile = snapshot.data!['profile'] as Map<String, dynamic>;
          final String? base64Image = profile['profile_image'] ?? profile['profileImage'];

          int totalBaseTricks = 0;
          int totalCompletedVariations = 0;

          for (var cat in stats) {
            totalBaseTricks += (cat['totalTricks'] as num).toInt();
            totalCompletedVariations += (cat['completedTricks'] as num).toInt();
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
                const SizedBox(height: 24),

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
                  _buildCategoryChart(stats),
                  const SizedBox(height: 32),
                  _buildCategoryList(stats),
                ] else ...[
                  const SizedBox(height: 60),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.query_stats_rounded, size: 80, color: Colors.grey.withValues(alpha: 0.3)),
                        const SizedBox(height: 24),
                        Text(
                          widget.localizations.stances, 
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                        const SizedBox(height: 12),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            "Stance details for public profiles are coming soon!",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryChart(List<dynamic> stats) {
    final activeStats = stats.where((cat) => (cat['completedTricks'] as num) > 0).toList();
    if (activeStats.isEmpty) return const SizedBox(height: 200, child: Center(child: Text("No data yet")));

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
                  _showTricksSheet(context, cat['name'], cat['id']); 
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

  Widget _buildCategoryList(List<dynamic> stats) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final cat = stats[index];
        return ListTile(
          onTap: () => _showTricksSheet(context, cat['name'], cat['id']),
          leading: CircleAvatar(radius: 8, backgroundColor: categoryColors[cat['id']] ?? Colors.grey),
          title: Text(cat['name']),
          trailing: Text(
            '${cat['completedTricks']}/${(cat['totalTricks'] as num) * 4}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        );
      },
    );
  }
}
