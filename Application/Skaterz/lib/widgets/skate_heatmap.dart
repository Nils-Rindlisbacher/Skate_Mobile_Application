import 'package:flutter/material.dart';
import 'package:skaterz/models/skating_session.dart';
import 'package:skaterz/core/constants.dart';
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
  static const double _blockSize = 32.0;
  static const double _spacing = 4.0;

  bool _canScrollLeft = true;
  bool _canScrollRight = false;

  @override
  void initState() {
    super.initState();
    // Use a small delay to allow the scroll controller to attach and find its bounds
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
      // SingleChildScrollView(reverse: true)
      // Offset 0 is far RIGHT (current week)
      // Offset max is far LEFT (oldest week)
      _canScrollRight = offset > 10; 
      _canScrollLeft = offset < (max - 10);
    });
  }

  void _scrollLeft() {
    if (!_scrollController.hasClients) return;
    final target = (_scrollController.offset + (_blockSize + _spacing) * 4)
        .clamp(0.0, _scrollController.position.maxScrollExtent);
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _scrollRight() {
    if (!_scrollController.hasClients) return;
    final target = (_scrollController.offset - (_blockSize + _spacing) * 4)
        .clamp(0.0, _scrollController.position.maxScrollExtent);
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  String _getDayLabel(int weekday) {
    switch (weekday) {
      case 1: return widget.localizations.mon.substring(0, 1);
      case 3: return widget.localizations.wed.substring(0, 1);
      case 5: return widget.localizations.fri.substring(0, 1);
      case 7: return widget.localizations.sun.substring(0, 1);
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateUtils.dateOnly(now);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final currentWeekMonday = today.subtract(Duration(days: today.weekday - 1));
    final startDate = currentWeekMonday.subtract(Duration(days: (_totalWeeks - 1) * 7));
    
    final sessionMap = {
      for (var s in widget.sessions) 
        DateUtils.dateOnly(s.sessionDate): s
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              icon: Icon(
                Icons.chevron_left, 
                size: 28, 
                color: _canScrollLeft 
                    ? (isDark ? AppColors.secondary : AppColors.primary) 
                    : Colors.grey.withOpacity(0.3)
              ),
              onPressed: _canScrollLeft ? _scrollLeft : null,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 16),
            IconButton(
              icon: Icon(
                Icons.chevron_right, 
                size: 28, 
                color: _canScrollRight 
                    ? (isDark ? AppColors.secondary : AppColors.primary) 
                    : Colors.grey.withOpacity(0.3)
              ),
              onPressed: _canScrollRight ? _scrollRight : null,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            const double labelWidth = 20.0;

            return SizedBox(
              height: (_blockSize * 7) + (_spacing * 6) + 35, 
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 25.0),
                    child: SizedBox(
                      width: labelWidth,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(7, (index) {
                          final label = _getDayLabel(index + 1);
                          return SizedBox(
                            height: _blockSize,
                            child: Center(
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white38 : Colors.grey[400],
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (notification is ScrollUpdateNotification) {
                          _updateScrollButtons();
                        }
                        return false;
                      },
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        scrollDirection: Axis.horizontal,
                        reverse: true,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: List.generate(_totalWeeks, (weekIdx) {
                            final weekMonday = startDate.add(Duration(days: weekIdx * 7));
                            
                            bool showMonth = false;
                            String monthName = "";
                            
                            for (int i = 0; i < 7; i++) {
                              final d = weekMonday.add(Duration(days: i));
                              if (d.day == 1 || (weekIdx == 0 && i == 0)) {
                                showMonth = true;
                                monthName = "${_getMonthName(d)} '${d.year.toString().substring(2)}";
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
                                    child: showMonth 
                                      ? Text(
                                          monthName.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w900,
                                            color: isDark ? AppColors.secondary : AppColors.primary,
                                            letterSpacing: 0.5,
                                          ),
                                        )
                                      : null,
                                  ),
                                  const SizedBox(height: 5),
                                  ...List.generate(7, (dayIdx) {
                                    final date = DateUtils.dateOnly(weekMonday.add(Duration(days: dayIdx)));
                                    final session = sessionMap[date];
                                    final isFuture = date.isAfter(today);

                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: _spacing),
                                      child: SizedBox(
                                        width: _blockSize,
                                        height: _blockSize,
                                        child: _HeatmapBlock(
                                          date: date,
                                          session: session,
                                          isFuture: isFuture,
                                          index: weekIdx * 7 + dayIdx,
                                          onDelete: widget.onDeleteSession != null ? () => widget.onDeleteSession!(date) : null,
                                          localizations: widget.localizations,
                                        ),
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
              ),
            );
          },
        ),
      ],
    );
  }

  String _getMonthName(DateTime date) {
    const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return months[date.month - 1];
  }
}

class _HeatmapBlock extends StatefulWidget {
  final DateTime date;
  final SkatingSession? session;
  final bool isFuture;
  final int index;
  final VoidCallback? onDelete;
  final AppLocalizations localizations;

  const _HeatmapBlock({
    required this.date,
    this.session,
    required this.isFuture,
    required this.index,
    this.onDelete,
    required this.localizations,
  });

  @override
  State<_HeatmapBlock> createState() => _HeatmapBlockState();
}

class _HeatmapBlockState extends State<_HeatmapBlock> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showDeleteConfirmation(BuildContext context) {
    final bool isToday = DateUtils.isSameDay(widget.date, DateTime.now());
    if (widget.session == null || widget.isFuture || !isToday) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.localizations.undo),
        content: Text(widget.localizations.skatedToday),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(widget.localizations.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onDelete?.call();
            },
            child: Text(widget.localizations.undo, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isToday = DateUtils.isSameDay(widget.date, DateTime.now());
    
    Color color = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.12);
    IconData? moodIcon;
    Color? moodColor;

    if (widget.isFuture) {
      color = isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.withValues(alpha: 0.05);
    } else if (widget.session != null) {
      switch (widget.session!.mood) {
        case 'GREAT':
          moodColor = const Color(0xFFA5D6A7); 
          moodIcon = Icons.sentiment_very_satisfied_rounded;
          break;
        case 'OK':
          moodColor = const Color(0xFF90CAF9);
          moodIcon = Icons.sentiment_satisfied_rounded;
          break;
        case 'BAD':
          moodColor = const Color(0xFFFFCC80);
          moodIcon = Icons.sentiment_dissatisfied_rounded;
          break;
        case 'INJURED':
          moodColor = const Color(0xFFEF9A9A);
          monthRepresentative: moodIcon = Icons.medical_services_rounded;
          break;
      }
      color = moodColor!.withValues(alpha: 0.4);
    }

    return GestureDetector(
      onLongPress: () => _showDeleteConfirmation(context),
      onTap: isToday && widget.session != null ? () => _showDeleteConfirmation(context) : null,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
            border: isToday 
              ? Border.all(
                  color: isDark ? AppColors.secondary : AppColors.primary, 
                  width: 1.5
                ) 
              : null,
          ),
          child: widget.session != null 
            ? Icon(
                moodIcon, 
                size: 16, 
                color: isDark ? Colors.black87 : Colors.black54,
              ) 
            : Text(
                '${widget.date.day}',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white24 : Colors.black12,
                ),
              ),
        ),
      ),
    );
  }
}
