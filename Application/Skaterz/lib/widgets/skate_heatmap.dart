import 'package:flutter/material.dart';
import 'package:skaterz/models/skating_session.dart';
import 'package:skaterz/core/constants.dart';
import 'package:skaterz/l10n/app_localizations.dart';

class SkateHeatmap extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Start from Monday of the current week
    final startDate = now.subtract(Duration(days: now.weekday - 1));
    
    final sessionMap = {
      for (var s in sessions) 
        DateUtils.dateOnly(s.sessionDate): s
    };

    final days = List.generate(7, (index) => DateUtils.dateOnly(startDate.add(Duration(days: index))));

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 4.0;
        final squareSize = (constraints.maxWidth - (6 * spacing)) / 7;
        
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (index) {
                final date = days[index];
                final isToday = DateUtils.isSameDay(date, now);
                return SizedBox(
                  width: squareSize,
                  child: Text(
                    _getDayLetter(date.weekday),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                      color: isToday 
                        ? (isDark ? AppColors.secondary : AppColors.primary)
                        : Colors.grey[500],
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (index) {
                final date = days[index];
                final session = sessionMap[date];
                final isFuture = date.isAfter(DateUtils.dateOnly(now));
                
                return SizedBox(
                  width: squareSize,
                  height: squareSize * 0.9,
                  child: _HeatmapBlock(
                    date: date,
                    session: session,
                    isFuture: isFuture,
                    index: index,
                    onDelete: onDeleteSession != null ? () => onDeleteSession!(date) : null,
                    localizations: localizations,
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }

  String _getDayLetter(int weekday) {
    switch (weekday) {
      case 1: return localizations.mon;
      case 2: return localizations.tue;
      case 3: return localizations.wed;
      case 4: return localizations.thu;
      case 5: return localizations.fri;
      case 6: return localizations.sat;
      case 7: return localizations.sun;
      default: return '';
    }
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
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        widget.index * 0.08,
        (widget.index * 0.08 + 0.5).clamp(0, 1.0),
        curve: Curves.elasticOut,
      ),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        widget.index * 0.08,
        (widget.index * 0.08 + 0.4).clamp(0, 1.0),
        curve: Curves.easeIn,
      ),
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
    
    Color color = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.1);
    IconData? moodIcon;
    Color? moodColor;

    if (widget.isFuture) {
      color = isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.withValues(alpha: 0.03);
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
          moodIcon = Icons.medical_services_rounded;
          break;
      }
      color = moodColor!.withValues(alpha: 0.3);
    }

    return Stack(
      children: [
        GestureDetector(
          onLongPress: () => _showDeleteConfirmation(context),
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                  border: isToday 
                    ? Border.all(
                        color: isDark ? AppColors.secondary : AppColors.primary, 
                        width: 2.0
                      ) 
                    : Border.all(color: Colors.transparent),
                  boxShadow: (widget.session != null && !widget.isFuture) ? [
                    BoxShadow(
                      color: moodColor!.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ] : null,
                ),
                child: moodIcon != null 
                  ? Icon(
                      moodIcon, 
                      size: 24, 
                      color: isDark ? Colors.black87 : Colors.black54,
                    ) 
                  : null,
              ),
            ),
          ),
        ),
        if (isToday && widget.session != null)
          Positioned(
            top: -2,
            right: -2,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showDeleteConfirmation(context),
                borderRadius: BorderRadius.circular(10),
                child: const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Icon(
                    Icons.delete_forever_rounded, 
                    size: 18, 
                    color: Colors.redAccent
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
