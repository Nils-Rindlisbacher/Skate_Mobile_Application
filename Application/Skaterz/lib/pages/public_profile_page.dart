import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:skaterz/l10n/app_localizations.dart';
import 'package:skaterz/services/api_service.dart';
import 'package:fl_chart/fl_chart.dart';

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
  late Future<Map<String, dynamic>> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfileData();
  }

  Future<Map<String, dynamic>> _loadProfileData() async {
    final stats = await _apiService.getCategoryStats(userId: widget.userId);
    final userProfile = await _apiService.getUserProfile(widget.userId);
    return {
      'stats': stats,
      'profile': userProfile,
    };
  }

  @override
  Widget build(BuildContext context) {
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
          widget.username,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _profileFuture,
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

          int totalTricks = 0;
          int totalCompleted = 0;
          for (var cat in stats) {
            totalTricks += (cat['totalTricks'] as num).toInt();
            totalCompleted += (cat['completedTricks'] as num).toInt();
          }

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
                
                Text(
                  '$totalCompleted/$totalTricks ${widget.localizations.tricksCompleted}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF004D40)),
                ),
                const SizedBox(height: 32),
                
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sections: stats.map((cat) {
                        final int count = (cat['completedTricks'] as num).toInt();
                        return PieChartSectionData(
                          color: Color.lerp(const Color(0xFF004D40), const Color(0xFF00FF88), cat['id'] / 10),
                          value: count.toDouble(),
                          title: count > 0 ? '$count' : '',
                          radius: 50,
                          titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: stats.length,
                  itemBuilder: (context, index) {
                    final cat = stats[index];
                    return ListTile(
                      leading: CircleAvatar(
                        radius: 8,
                        backgroundColor: Color.lerp(const Color(0xFF004D40), const Color(0xFF00FF88), cat['id'] / 10),
                      ),
                      title: Text(cat['name']),
                      trailing: Text(
                        '${cat['completedTricks']}/${cat['totalTricks']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
