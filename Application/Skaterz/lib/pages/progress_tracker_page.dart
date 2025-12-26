import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:skaterz/l10n/app_localizations.dart';
import 'package:skaterz/services/api_service.dart';
import 'package:skaterz/widgets/login_required_view.dart';

class ProgressTrackerPage extends StatefulWidget {
  const ProgressTrackerPage({
    super.key,
    required this.localizations,
    required this.isLoggedIn,
    required this.onLogin,
  });

  final AppLocalizations localizations;
  final bool isLoggedIn;
  final VoidCallback onLogin;

  @override
  State<ProgressTrackerPage> createState() => _ProgressTrackerPageState();
}

class _ProgressTrackerPageState extends State<ProgressTrackerPage> {
  final ApiService _apiService = ApiService();
  List<dynamic> _stats = [];
  List<dynamic> _completed = [];
  bool _isLoading = true;

  final Map<int, Color> categoryColors = {
    1: Colors.blue, 2: Colors.red, 3: Colors.green, 
    4: Colors.orange, 5: Colors.purple, 6: Colors.teal, 7: Colors.amber,
  };

  @override
  void initState() {
    super.initState();
    if (widget.isLoggedIn) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    // 1. Load from Cache
    final cachedStats = await _apiService.getCachedData('category_stats_me');
    final cachedCompleted = await _apiService.getCachedData('completed_tricks');

    if (mounted && (cachedStats != null || cachedCompleted != null)) {
      setState(() {
        if (cachedStats != null) _stats = cachedStats;
        if (cachedCompleted != null) _completed = cachedCompleted;
        _isLoading = false;
      });
    }

    // 2. Load from API in parallel
    try {
      final results = await Future.wait([
        _apiService.getCategoryStats(),
        _apiService.getCompletedTricks(),
      ]);

      if (mounted) {
        setState(() {
          _stats = results[0];
          _completed = results[1];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && _stats.isEmpty) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showCategoryTricks(BuildContext context, int categoryId, String categoryName) {
    final categoryTricks = _completed.where((item) {
      final trickCatId = (item['category_id'] ?? item['categoryId'] ?? 
                         (item['category'] != null ? item['category']['id'] : null))?.toString();
      return trickCatId == categoryId.toString();
    }).toList();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(categoryName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF004D40))),
            const Divider(),
            if (categoryTricks.isEmpty)
              Padding(padding: const EdgeInsets.all(20), child: Text(widget.localizations.noTricksYet))
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: categoryTricks.length,
                  itemBuilder: (context, index) => ListTile(
                    visualDensity: VisualDensity.compact,
                    leading: const Icon(Icons.check_circle, color: Color(0xFF004D40)),
                    title: Text(categoryTricks[index]['name'] ?? 'Trick'),
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
    if (!widget.isLoggedIn) {
      return LoginRequiredView(
        localizations: widget.localizations,
        onLogin: widget.onLogin,
        featureName: widget.localizations.progressTrackerMenuItem,
        icon: Icons.analytics_outlined,
      );
    }

    Map<String, int> localCategoryCounts = {};
    for (var item in _completed) {
      final catId = (item['category_id'] ?? item['categoryId'] ?? 
                    (item['category'] != null ? item['category']['id'] : null))?.toString();
      if (catId != null) localCategoryCounts[catId] = (localCategoryCounts[catId] ?? 0) + 1;
    }

    int totalTricks = 0;
    for (var cat in _stats) {
      final catTotal = cat['totalTricks'] ?? cat['total_tricks'] ?? cat['totalCount'] ?? cat['total_count'] ?? 0;
      totalTricks += (catTotal as num).toInt();
    }

    final int totalCompleted = _completed.length;
    final double percentage = totalTricks > 0 ? (totalCompleted / totalTricks) * 100 : 0;
    final pieStats = _stats.where((cat) => (localCategoryCounts[cat['id'].toString()] ?? 0) > 0).toList();

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF002211), Color(0xFF004D40), Color(0xFF00FF88)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
        title: Text(widget.localizations.progressTrackerMenuItem, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading && _stats.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text('$totalCompleted/$totalTricks ${widget.localizations.tricksCompleted} (${percentage.toStringAsFixed(1)}%)',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    if (pieStats.isNotEmpty)
                      SizedBox(
                        height: 200,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                            sections: pieStats.map((cat) {
                              final id = cat['id'];
                              final count = localCategoryCounts[id.toString()] ?? 0;
                              return PieChartSectionData(
                                color: categoryColors[id] ?? Colors.grey,
                                value: count.toDouble(),
                                title: '$count',
                                radius: 40,
                                titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    const SizedBox(height: 32),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _stats.length,
                      itemBuilder: (context, index) {
                        final cat = _stats[index];
                        final id = cat['id'];
                        final count = localCategoryCounts[id.toString()] ?? 0;
                        final total = (cat['totalTricks'] ?? cat['total_tricks'] ?? 0) as num;

                        return Card(
                          child: ListTile(
                            onTap: () => _showCategoryTricks(context, id, cat['name'] ?? ''),
                            leading: CircleAvatar(backgroundColor: categoryColors[id], radius: 10),
                            title: Text(cat['name'] ?? ''),
                            trailing: Text('$count/${total.toInt()} ${widget.localizations.tricks}',
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
