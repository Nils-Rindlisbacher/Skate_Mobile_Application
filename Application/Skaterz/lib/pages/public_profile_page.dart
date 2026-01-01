import 'dart:convert';
import 'package:flutter/material.dart';
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
    'REGULAR': Colors.blueAccent,
    'NOLLIE': Colors.deepOrangeAccent,
    'SWITCH': Colors.purpleAccent,
    'FAKIE': Colors.tealAccent,
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

  void _showTricksSheet(BuildContext context, String title, List<dynamic> tricks) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
            const Divider(),
            if (tricks.isEmpty)
              const Padding(padding: EdgeInsets.all(20), child: Text("No tricks recorded"))
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: tricks.length,
                  itemBuilder: (context, index) => ListTile(
                    visualDensity: VisualDensity.compact,
                    leading: const Icon(Icons.check_circle, color: AppColors.primary),
                    title: Text(tricks[index]['name'] ?? 'Trick'),
                    subtitle: tricks[index]['stance'] != null ? Text(_formatStance(tricks[index]['stance'])) : null,
                  ),
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
                    ButtonSegment(value: TrackerView.stance, label: Text(widget.localizations.stances), icon: const Icon(Icons.directions_run)),
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
                  const Center(child: Text("Stance details for public profiles coming soon (Requires updated API endpoint)")),
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
                  _showTricksSheet(context, cat['name'], []); 
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
