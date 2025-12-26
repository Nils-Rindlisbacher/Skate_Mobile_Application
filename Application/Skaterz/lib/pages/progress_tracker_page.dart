import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:skaterz/l10n/app_localizations.dart';
import 'package:skaterz/services/api_service.dart';
import 'package:intl/intl.dart';
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
  Future<Map<String, dynamic>>? _dataFuture;

  final Map<int, Color> categoryColors = {
    1: Colors.blue,
    2: Colors.red,
    3: Colors.green,
    4: Colors.orange,
    5: Colors.purple,
    6: Colors.teal,
    7: Colors.amber,
  };

  @override
  void initState() {
    super.initState();
    if (widget.isLoggedIn) {
      _dataFuture = _loadAllData();
    }
  }

  @override
  void didUpdateWidget(ProgressTrackerPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoggedIn && !oldWidget.isLoggedIn) {
      setState(() {
        _dataFuture = _loadAllData();
      });
    }
  }

  Future<Map<String, dynamic>> _loadAllData() async {
    final stats = await _apiService.getCategoryStats();
    final completed = await _apiService.getCompletedTricks();
    final allTricks = await _apiService.getTricks();
    
    // Create a map for quick trick lookup by ID
    Map<String, dynamic> tricksMap = {};
    for (var t in allTricks) {
      tricksMap[t['id'].toString()] = t;
    }

    return {
      'stats': stats, 
      'completed': completed,
      'tricksMap': tricksMap,
    };
  }

  void _showCategoryTricks(BuildContext context, int categoryId, String categoryName, List<dynamic> allCompleted, Map<String, dynamic> tricksMap) {
    // Filter completed tricks by matching their category ID
    final categoryTricks = allCompleted.where((item) {
      final trickCatId = (item['category_id'] ?? item['categoryId'] ?? 
                         (item['category'] != null ? item['category']['id'] : null))?.toString();
      return trickCatId == categoryId.toString();
    }).toList();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                categoryName,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF004D40)),
              ),
              const SizedBox(height: 8),
              Text(
                '${categoryTricks.length} ${widget.localizations.tricksCompleted}',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const Divider(),
              if (categoryTricks.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Text(widget.localizations.noTricksYet),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: categoryTricks.length,
                    itemBuilder: (context, index) {
                      final item = categoryTricks[index];
                      return ListTile(
                        visualDensity: VisualDensity.compact,
                        leading: const Icon(Icons.check_circle, color: Color(0xFF004D40)),
                        title: Text(item['name'] ?? 'Trick'),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
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
          widget.localizations.progressTrackerMenuItem,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (_dataFuture == null || snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final stats = snapshot.data!['stats'] as List<dynamic>;
          final completed = snapshot.data!['completed'] as List<dynamic>;

          // Calculate counts per category
          Map<String, int> localCategoryCounts = {};
          for (var item in completed) {
            final catId = (item['category_id'] ?? item['categoryId'] ?? 
                          (item['category'] != null ? item['category']['id'] : null))?.toString();
            if (catId != null) {
              localCategoryCounts[catId] = (localCategoryCounts[catId] ?? 0) + 1;
            }
          }

          int totalTricks = 0;
          for (var cat in stats) {
            final catTotal = cat['totalTricks'] ?? cat['total_tricks'] ?? cat['totalCount'] ?? cat['total_count'] ?? 0;
            totalTricks += (catTotal as num).toInt();
          }

          final int totalCompleted = completed.length;
          final double percentage = totalTricks > 0 ? (totalCompleted / totalTricks) * 100 : 0;

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _dataFuture = _loadAllData();
              });
              await _dataFuture;
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    '$totalCompleted/$totalTricks ${widget.localizations.tricksCompleted} (${percentage.toStringAsFixed(1)}%)',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        pieTouchData: PieTouchData(
                          touchCallback: (FlTouchEvent event, pieTouchResponse) {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null ||
                                event is! FlTapUpEvent) {
                              return;
                            }
                            final index = pieTouchResponse.touchedSection!.touchedSectionIndex;
                            if (index >= 0 && index < stats.length) {
                              final cat = stats[index];
                              final catId = (cat['id'] ?? 0);
                              _showCategoryTricks(context, catId is int ? catId : int.parse(catId.toString()), cat['name'] ?? '', completed, {});
                            }
                          },
                        ),
                        sections: stats.map((cat) {
                          final catIdStr = (cat['id'] ?? '').toString();
                          final int finalCount = localCategoryCounts[catIdStr] ?? 0;
                          
                          final int catId = int.tryParse(catIdStr) ?? 0;
                          return PieChartSectionData(
                            color: categoryColors[catId] ?? Colors.grey,
                            value: finalCount > 0 ? finalCount.toDouble() : 0.01,
                            title: finalCount > 0 ? '$finalCount' : '',
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
                    itemCount: stats.length,
                    itemBuilder: (context, index) {
                      final cat = stats[index];
                      final catIdStr = (cat['id'] ?? '').toString();
                      final int finalCount = localCategoryCounts[catIdStr] ?? 0;

                      final catTotal = cat['totalTricks'] ?? cat['total_tricks'] ?? cat['totalCount'] ?? cat['total_count'] ?? 0;
                      final int totalCount = (catTotal as num).toInt();
                      final int catId = int.tryParse(catIdStr) ?? 0;

                      return Card(
                        child: ListTile(
                          onTap: () => _showCategoryTricks(context, catId, cat['name'] ?? '', completed, {}),
                          leading: CircleAvatar(
                            backgroundColor: categoryColors[catId],
                            radius: 10,
                          ),
                          title: Text(cat['name'] ?? ''),
                          trailing: Text(
                            '$finalCount/$totalCount ${widget.localizations.tricks}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
