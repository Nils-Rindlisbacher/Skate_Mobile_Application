import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:skaterz/l10n/app_localizations.dart';
import 'package:skaterz/services/api_service.dart';
import 'package:skaterz/widgets/login_required_view.dart';
import 'package:skaterz/core/constants.dart';

enum TrackerView { category, stance }

class ProgressTrackerPage extends StatefulWidget {
  const ProgressTrackerPage({
    super.key,
    required this.localizations,
    required this.isLoggedIn,
    required this.onLogin,
    required this.onMenuTap,
    this.isActive = true,
  });

  final AppLocalizations localizations;
  final bool isLoggedIn;
  final VoidCallback onLogin;
  final VoidCallback onMenuTap;
  final bool isActive;

  @override
  State<ProgressTrackerPage> createState() => _ProgressTrackerPageState();
}

class _ProgressTrackerPageState extends State<ProgressTrackerPage> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  List<dynamic> _stats = [];
  List<dynamic> _completed = [];
  bool _isLoading = true;
  TrackerView _currentView = TrackerView.category;

  final Map<String, Color> stanceColors = {
    'REGULAR': const Color(0xFFF57C00), 
    'NOLLIE': const Color(0xFFEF6C00),  
    'SWITCH': const Color(0xFFFF9800),  
    'FAKIE': const Color(0xFFFFB74D),   
  };

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
  void didUpdateWidget(ProgressTrackerPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoggedIn && widget.isActive && !oldWidget.isActive) {
      _loadData(); 
    }
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

  Future<void> _loadData() async {
    final cachedStats = await _apiService.getCachedData('category_stats_me');
    final cachedCompleted = await _apiService.getCachedData('completed_tricks');

    if (mounted && (cachedStats != null || cachedCompleted != null)) {
      setState(() {
        if (cachedStats != null) _stats = cachedStats;
        if (cachedCompleted != null) _completed = cachedCompleted;
        _isLoading = false;
      });
    }

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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${widget.localizations.error}: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 800;

    if (!widget.isLoggedIn) {
      return LoginRequiredView(
        localizations: widget.localizations,
        onLogin: widget.onLogin,
        featureName: widget.localizations.progressTrackerMenuItem,
        icon: Icons.analytics_outlined,
        onMenuTap: widget.onMenuTap,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isLargeScreen = screenWidth > 900;
        final columns = isLargeScreen ? 4 : (screenWidth > 600 ? 2 : 1);

        int totalBaseTricks = 0;
        for (var cat in _stats) {
          final catTotal = cat['totalTricks'] ?? cat['total_tricks'] ?? 0;
          totalBaseTricks += (catTotal as num).toInt();
        }

        final uniqueTrickIdsDone = _completed.map((e) => e['id']).toSet();
        final int completedUniqueCount = uniqueTrickIdsDone.length;
        final int totalPossibleVariations = totalBaseTricks * 4;
        final int completedVariationsCount = _completed.length;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            title: Text(widget.localizations.progressTrackerMenuItem.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16)),
            elevation: 0,
            iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
            leading: !isDesktop ? IconButton(
              icon: const Icon(Icons.menu_rounded),
              onPressed: widget.onMenuTap,
            ) : null,
          ),
          body: _isLoading && _stats.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        _buildAnimatedHeader(
                          _currentView == TrackerView.category ? completedUniqueCount : completedVariationsCount,
                          _currentView == TrackerView.category ? totalBaseTricks : totalPossibleVariations,
                          _currentView == TrackerView.category ? widget.localizations.tricks : widget.localizations.mastery,
                          showCount: _currentView == TrackerView.category,
                        ),
                        const SizedBox(height: 30),
                        SegmentedButton<TrackerView>(
                          style: SegmentedButton.styleFrom(
                            backgroundColor: Colors.grey.withValues(alpha: 0.1),
                            selectedBackgroundColor: AppColors.primary,
                            selectedForegroundColor: Colors.white,
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          segments: [
                            ButtonSegment(value: TrackerView.category, label: Text(widget.localizations.category), icon: const Icon(Icons.category_outlined)),
                            ButtonSegment(value: TrackerView.stance, label: Text(widget.localizations.stance), icon: const Icon(Icons.directions_run)),
                          ],
                          selected: {_currentView},
                          onSelectionChanged: (val) {
                            HapticFeedback.lightImpact();
                            setState(() => _currentView = val.first);
                          },
                        ),
                        const SizedBox(height: 32),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          child: _currentView == TrackerView.category 
                            ? _buildCategoryView(columns) 
                            : _buildStanceView(totalBaseTricks),
                        ),
                      ],
                    ),
                  ),
                ),
        );
      }
    );
  }

  Widget _buildAnimatedHeader(int current, int total, String label, {bool showCount = true}) {
    if (!showCount) {
      return Text(
        label.toUpperCase(),
        key: ValueKey('header_no_count_${_currentView.name}'),
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2),
      );
    }

    final double percentage = total > 0 ? (current / total) : 0;
    return Column(
      key: ValueKey('header_${_currentView.name}'),
      children: [
        TweenAnimationBuilder(
          duration: const Duration(milliseconds: 800),
          tween: Tween<double>(begin: 0, end: current.toDouble()),
          builder: (context, double value, child) {
            return Text(
              '${value.toInt()} / $total ${label.toUpperCase()}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
            );
          },
        ),
        const SizedBox(height: 4),
        TweenAnimationBuilder(
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          tween: Tween<double>(begin: 0, end: percentage),
          builder: (context, double value, child) {
            return Text(
              '(${(value * 100).toStringAsFixed(1)}% ${widget.localizations.completed})',
              style: TextStyle(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w900, letterSpacing: 1),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCategoryView(int columns) {
    Map<String, int> counts = {};
    for (var item in _completed) {
      final catId = (item['category_id'] ?? item['categoryId'] ?? 
                    (item['category'] != null ? item['category']['id'] : null))?.toString();
      if (catId != null) counts[catId] = (counts[catId] ?? 0) + 1;
    }

    return GridView.builder(
      key: const ValueKey('categoryView'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: columns == 1 ? 2.5 : 1.1,
      ),
      itemCount: _stats.length,
      itemBuilder: (context, index) {
        final cat = _stats[index];
        final id = cat['id'];
        final count = counts[id.toString()] ?? 0;
        final total = ((cat['totalTricks'] ?? 0) as num) * 4;
        
        return _buildMasteryBarCard(
          title: cat['name'] ?? widget.localizations.category,
          count: count,
          total: total.toInt(),
          color: AppColors.primary, 
          onTap: () => _showCategoryTricks(context, id, cat['name'] ?? widget.localizations.category),
        );
      },
    );
  }

  Widget _buildMasteryBarCard({required String title, required int count, required int total, required Color color, required VoidCallback onTap}) {
    final double progress = total > 0 ? count / total : 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title.toUpperCase(), 
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: color.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$count / $total ${widget.localizations.tricks.toUpperCase()}',
              style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.w900, letterSpacing: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStanceView(int totalPerStance) {
    Map<String, int> stanceCounts = {'REGULAR': 0, 'NOLLIE': 0, 'SWITCH': 0, 'FAKIE': 0};
    for (var item in _completed) {
      final stance = item['stance'] ?? 'REGULAR';
      stanceCounts[stance] = (stanceCounts[stance] ?? 0) + 1;
    }

    // Always 4 columns for stance cards to make them small and fit on one screen
    return GridView.builder(
      key: const ValueKey('stanceView'),
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
        final count = stanceCounts[stance] ?? 0;
        final color = stanceColors[stance]!;
        return _buildSmallStanceCard(stance, count, totalPerStance, color);
      },
    );
  }

  Widget _buildSmallStanceCard(String stance, int count, int total, Color color) {
    final double progress = total > 0 ? count / total : 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showStanceTricks(context, stance);
      },
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              stance.substring(0, 3).toUpperCase(), // Shortened name
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: color, letterSpacing: 0.5),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 45,
                    height: 45,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 4,
                      backgroundColor: color.withValues(alpha: 0.1),
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
            ),
            const SizedBox(height: 8),
            Text(
              '$count/$total', 
              style: TextStyle(fontSize: 9, color: isDark ? Colors.white54 : Colors.black54, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryTricks(BuildContext context, int categoryId, String categoryName) {
    final tricks = _completed.where((item) {
      final trickCatId = (item['category_id'] ?? item['categoryId'] ?? 
                         (item['category'] != null ? item['category']['id'] : null))?.toString();
      return trickCatId == categoryId.toString();
    }).toList();
    _showTricksSheet(context, categoryName, tricks);
  }

  void _showStanceTricks(BuildContext context, String stance) {
    final tricks = _completed.where((item) => (item['stance'] ?? 'REGULAR') == stance).toList();
    _showTricksSheet(context, _formatStance(stance), tricks, filteredStance: stance);
  }

  void _showTricksSheet(BuildContext context, String title, List<dynamic> tricks, {String? filteredStance}) {
    HapticFeedback.mediumImpact();
    
    final Map<String, List<String>> groupedTricks = {};
    for (var t in tricks) {
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
            Text(title.toUpperCase(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 2)),
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
                              if (filteredStance != null && s != filteredStance) {
                                return const SizedBox.shrink();
                              }

                              final isDone = stances.contains(s);
                              final label = s == 'REGULAR' ? 'R' : (s == 'NOLLIE' ? 'N' : (s == 'SWITCH' ? 'S' : 'F'));
                              return Container(
                                margin: const EdgeInsets.only(right: 12, top: 4),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
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
}
