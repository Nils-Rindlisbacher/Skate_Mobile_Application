import 'package:flutter/material.dart';
import 'package:skaterz/models/skating_session.dart';
import 'package:skaterz/l10n/app_localizations.dart';

class SkateHeatmap extends StatefulWidget {
  final List<SkatingSession> sessions;
  final Function(DateTime)? onDeleteSession;
  final VoidCallback? onSessionUpdated;
  final AppLocalizations localizations;

  const SkateHeatmap({
    super.key,
    required this.sessions,
    required this.localizations,
    this.onDeleteSession,
    this.onSessionUpdated,
  });

  @override
  State<SkateHeatmap> createState() => _SkateHeatmapState();
}

class _SkateHeatmapState extends State<SkateHeatmap> {
  final ScrollController _scrollController = ScrollController();
  
  final int _totalWeeks = 52; 
  static const double _blockSize = 34.0;
  static const double _spacing = 6.0;

  bool _canScrollLeft = true;
  bool _canScrollRight = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.addListener(_updateScrollButtons);
        _updateScrollButtons();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _updateScrollButtons() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    final offset = _scrollController.offset;
    setState(() {
      _canScrollRight = offset > 10; 
      _canScrollLeft = offset < (max - 10);
    });
  }

  void _scrollLeft() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      (_scrollController.offset + (_blockSize + _spacing) * 4).clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutQuint,
    );
  }

  void _scrollRight() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      (_scrollController.offset - (_blockSize + _spacing) * 4).clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutQuint,
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateUtils.dateOnly(now);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
    final currentWeekMonday = today.subtract(Duration(days: today.weekday - 1));
    final startDate = currentWeekMonday.subtract(Duration(days: (_totalWeeks - 1) * 7));
    final sessionMap = {for (var s in widget.sessions) DateUtils.dateOnly(s.sessionDate): s};

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              widget.localizations.activityHeatmap.toUpperCase(),
              style: TextStyle(
                fontSize: 12, 
                fontWeight: FontWeight.w900, 
                letterSpacing: 1.5,
                color: colorScheme.onSurface.withOpacity(0.5)
              ),
            ),
            const Spacer(),
            IconButton(
              icon: Icon(Icons.west_rounded, size: 20, color: _canScrollLeft ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.1)),
              onPressed: _canScrollLeft ? _scrollLeft : null,
            ),
            IconButton(
              icon: Icon(Icons.east_rounded, size: 20, color: _canScrollRight ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.1)),
              onPressed: _canScrollRight ? _scrollRight : null,
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: (_blockSize * 7) + (_spacing * 6) + 30, 
          child: NotificationListener<ScrollNotification>(
            onNotification: (_) { _updateScrollButtons(); return false; },
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: Row(
                children: List.generate(_totalWeeks, (weekIdx) {
                  final weekMonday = startDate.add(Duration(days: weekIdx * 7));
                  bool showMonth = false;
                  String monthName = "";
                  for (int i = 0; i < 7; i++) {
                    final d = weekMonday.add(Duration(days: i));
                    if (d.day == 1 || (weekIdx == 0 && i == 0)) {
                      showMonth = true;
                      monthName = _getMonthName(d);
                      break;
                    }
                  }

                  return Padding(
                    padding: const EdgeInsets.only(right: _spacing),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 20,
                          child: showMonth ? Text(monthName.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: colorScheme.primary.withOpacity(0.6))) : null,
                        ),
                        ...List.generate(7, (dayIdx) {
                          final date = DateUtils.dateOnly(weekMonday.add(Duration(days: dayIdx)));
                          return Padding(
                            padding: const EdgeInsets.only(bottom: _spacing),
                            child: _HeatmapBlock(
                              date: date,
                              session: sessionMap[date],
                              isToday: DateUtils.isSameDay(date, today),
                              isFuture: date.isAfter(today),
                              onDelete: widget.onDeleteSession != null ? () => widget.onDeleteSession!(date) : null,
                              localizations: widget.localizations,
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getMonthName(DateTime date) {
    switch (date.month) {
      case 1: return widget.localizations.jan; case 2: return widget.localizations.feb;
      case 3: return widget.localizations.mar; case 4: return widget.localizations.apr;
      case 5: return widget.localizations.may; case 6: return widget.localizations.jun;
      case 7: return widget.localizations.jul; case 8: return widget.localizations.aug;
      case 9: return widget.localizations.sep; case 10: return widget.localizations.oct;
      case 11: return widget.localizations.nov; case 12: return widget.localizations.dec;
      default: return "";
    }
  }
}

class _HeatmapBlock extends StatelessWidget {
  final DateTime date;
  final SkatingSession? session;
  final bool isFuture;
  final bool isToday;
  final VoidCallback? onDelete;
  final AppLocalizations localizations;

  const _HeatmapBlock({
    required this.date,
    this.session,
    required this.isFuture,
    required this.isToday,
    this.onDelete,
    required this.localizations,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
    Color color = colorScheme.onSurface.withOpacity(0.05);
    Widget? content;

    if (session != null) {
      color = colorScheme.primary;
      content = Icon(Icons.bolt_rounded, size: 14, color: colorScheme.onPrimary);
    } else if (isToday) {
      color = colorScheme.primary.withOpacity(0.2);
    }

    return GestureDetector(
      onLongPress: () {
        if (session != null && isToday) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(localizations.undo),
              content: Text(localizations.deleteSessionConfirm),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text(localizations.cancel)),
                TextButton(onPressed: () { Navigator.pop(context); onDelete?.call(); }, child: Text(localizations.undo, style: TextStyle(color: colorScheme.error))),
              ],
            ),
          );
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 34, height: 34,
        decoration: BoxDecoration(
          color: isFuture ? color.withOpacity(0.02) : color,
          borderRadius: BorderRadius.circular(10),
          border: isToday ? Border.all(color: colorScheme.primary, width: 2) : null,
          boxShadow: session != null ? [BoxShadow(color: colorScheme.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))] : null,
        ),
        child: Center(child: content),
      ),
    );
  }
}
