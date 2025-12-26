import 'dart:async';
import 'package:flutter/material.dart';
import 'package:skaterz/l10n/app_localizations.dart';
import 'package:skaterz/models/session_goal.dart';
import 'package:skaterz/services/api_service.dart';
import 'package:skaterz/widgets/login_required_view.dart';

class SessionGoalsPage extends StatefulWidget {
  const SessionGoalsPage({
    super.key,
    required this.localizations,
    required this.isLoggedIn,
    required this.onLogin,
  });

  final AppLocalizations localizations;
  final bool isLoggedIn;
  final VoidCallback onLogin;

  @override
  State<SessionGoalsPage> createState() => _SessionGoalsPageState();
}

class _SessionGoalsPageState extends State<SessionGoalsPage> {
  final ApiService _apiService = ApiService();
  List<SessionGoal> _goals = [];
  bool _isLoading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.isLoggedIn) {
      _loadGoals();
    }
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadGoals() async {
    setState(() => _isLoading = true);
    try {
      final goalsData = await _apiService.getSessionGoals();
      if (mounted) {
        setState(() {
          _goals = goalsData.map((json) => SessionGoal.fromJson(json)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        for (var goal in _goals) {
          if (goal.remainingTime != null && 
              goal.remainingTime! > Duration.zero && 
              !goal.isCompleted && 
              !goal.isPaused) {
            goal.remainingTime = goal.remainingTime! - const Duration(seconds: 1);
            if (goal.remainingTime == Duration.zero) {
              goal.isCompleted = true;
              _updateGoalOnServer(goal);
            }
          }
        }
      });
    });
  }

  Future<void> _updateGoalOnServer(SessionGoal goal) async {
    if (goal.id == null) return;
    try {
      await _apiService.updateSessionGoal(goal.id!, goal.toJson());
    } catch (e) {
      debugPrint("Failed to sync goal: $e");
    }
  }

  Future<void> _deleteGoal(SessionGoal goal) async {
    if (goal.id == null) return;
    try {
      await _apiService.deleteSessionGoal(goal.id!);
      setState(() => _goals.remove(goal));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e')),
        );
      }
    }
  }

  void _addNewGoal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _AddGoalSheet(
        localizations: widget.localizations,
        onGoalAdded: (newGoal) async {
          Navigator.pop(sheetContext);
          setState(() => _isLoading = true);
          try {
            final savedGoalData = await _apiService.addSessionGoal(newGoal.toJson());
            if (mounted) {
              setState(() {
                _goals.insert(0, SessionGoal.fromJson(savedGoalData));
                _isLoading = false;
              });
            }
          } catch (e) {
            if (mounted) {
              setState(() => _isLoading = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to save goal: $e')),
              );
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoggedIn) {
      return LoginRequiredView(
        localizations: widget.localizations,
        onLogin: widget.onLogin,
        featureName: widget.localizations.sessionGoalsTitle,
        icon: Icons.track_changes,
      );
    }

    final openGoals = _goals.where((g) => !g.isCompleted).toList();
    final completedGoals = _goals.where((g) => g.isCompleted).toList();

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
        title: Text(
          widget.localizations.sessionGoalsTitle,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 4,
            margin: const EdgeInsets.only(bottom: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            clipBehavior: Clip.antiAlias,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF002211), Color(0xFF004D40), Color(0xFF00FF88)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: const CircleAvatar(
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.add, color: Colors.white),
                ),
                title: Text(
                  widget.localizations.addGoal,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
                subtitle: Text(
                  widget.localizations.goalHint,
                  style: TextStyle(color: Colors.white.withOpacity(0.8)),
                ),
                onTap: _addNewGoal,
              ),
            ),
          ),

          if (_goals.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Center(
                child: Text(
                  widget.localizations.noGoals,
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
            )
          else ...[
            if (openGoals.isNotEmpty) ...[
              _SectionHeader(title: widget.localizations.openGoals),
              ...openGoals.map((goal) => _GoalTile(
                    localizations: widget.localizations,
                    goal: goal,
                    onDelete: () => _deleteGoal(goal),
                    onToggleComplete: () {
                      setState(() => goal.isCompleted = !goal.isCompleted);
                      _updateGoalOnServer(goal);
                    },
                    onTogglePause: () => setState(() => goal.isPaused = !goal.isPaused),
                    onIncrement: () {
                      setState(() {
                        goal.currentCount++;
                        if (goal.targetCount != null && goal.currentCount >= goal.targetCount!) {
                          goal.isCompleted = true;
                        }
                      });
                      _updateGoalOnServer(goal);
                    },
                  )),
            ],
            if (completedGoals.isNotEmpty) ...[
              const SizedBox(height: 16),
              _SectionHeader(title: widget.localizations.completedGoals),
              ...completedGoals.map((goal) => _GoalTile(
                    localizations: widget.localizations,
                    goal: goal,
                    onDelete: () => _deleteGoal(goal),
                    onToggleComplete: () {
                      setState(() => goal.isCompleted = !goal.isCompleted);
                      _updateGoalOnServer(goal);
                    },
                    onTogglePause: () {},
                    onIncrement: () {},
                  )),
            ],
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF004D40),
        ),
      ),
    );
  }
}

class _GoalTile extends StatelessWidget {
  const _GoalTile({
    required this.localizations,
    required this.goal,
    required this.onDelete,
    required this.onToggleComplete,
    required this.onTogglePause,
    required this.onIncrement,
  });

  final AppLocalizations localizations;
  final SessionGoal goal;
  final VoidCallback onDelete;
  final VoidCallback onToggleComplete;
  final VoidCallback onTogglePause;
  final VoidCallback onIncrement;

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    final bool isTimerDisabled = goal.remainingTime != null && goal.isPaused;
    final bool isAddDisabled = goal.isCompleted || isTimerDisabled;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  goal.type == GoalType.trick ? Icons.skateboarding : Icons.text_fields,
                  color: const Color(0xFF004D40),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    goal.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      decoration: goal.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: onDelete,
                ),
              ],
            ),
            if (goal.type == GoalType.trick && goal.targetCount != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    "${goal.currentCount} / ${goal.targetCount}",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      goal.isCompleted ? Icons.check_circle : Icons.add_circle, 
                      color: goal.isCompleted 
                        ? Colors.green 
                        : (isTimerDisabled ? Colors.grey : const Color(0xFF004D40)),
                    ),
                    onPressed: isAddDisabled ? null : onIncrement,
                  ),
                ],
              ),
              LinearProgressIndicator(
                value: goal.currentCount / goal.targetCount!,
                backgroundColor: Colors.grey[200],
                color: const Color(0xFF004D40),
              ),
            ],
            if (goal.remainingTime != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.timer, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    _formatDuration(goal.remainingTime!),
                    style: TextStyle(
                      fontSize: 14,
                      color: goal.remainingTime == Duration.zero ? Colors.red : Colors.grey[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (!goal.isCompleted && goal.remainingTime! > Duration.zero)
                    IconButton(
                      icon: Icon(goal.isPaused ? Icons.play_arrow : Icons.pause),
                      color: const Color(0xFF004D40),
                      onPressed: onTogglePause,
                    ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onToggleComplete,
                  icon: Icon(goal.isCompleted ? Icons.undo : Icons.check),
                  label: Text(goal.isCompleted ? localizations.undo : localizations.complete),
                  style: TextButton.styleFrom(
                    foregroundColor: goal.isCompleted ? Colors.grey : const Color(0xFF004D40),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddGoalSheet extends StatefulWidget {
  const _AddGoalSheet({required this.localizations, required this.onGoalAdded});

  final AppLocalizations localizations;
  final Function(SessionGoal) onGoalAdded;

  @override
  State<_AddGoalSheet> createState() => _AddGoalSheetState();
}

class _AddGoalSheetState extends State<_AddGoalSheet> {
  GoalType _type = GoalType.trick;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _countController = TextEditingController();
  final TextEditingController _minutesController = TextEditingController();
  Map<String, dynamic>? _selectedTrick;
  List<dynamic> _tricks = [];
  bool _isLoadingTricks = false;

  @override
  void initState() {
    super.initState();
    _loadTricks();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _countController.dispose();
    _minutesController.dispose();
    super.dispose();
  }

  Future<void> _loadTricks() async {
    if (!mounted) return;
    setState(() => _isLoadingTricks = true);
    try {
      final tricks = await ApiService().getTricks();
      if (!mounted) return;
      setState(() {
        _tricks = tricks;
        _isLoadingTricks = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingTricks = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.localizations.addGoal,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SegmentedButton<GoalType>(
              segments: [
                ButtonSegment(value: GoalType.trick, label: Text(widget.localizations.trickType), icon: const Icon(Icons.skateboarding)),
                ButtonSegment(value: GoalType.text, label: Text(widget.localizations.textType), icon: const Icon(Icons.text_fields)),
              ],
              selected: {_type},
              onSelectionChanged: (val) => setState(() => _type = val.first),
            ),
            const SizedBox(height: 16),
            if (_type == GoalType.text)
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: widget.localizations.goalHint,
                  border: const OutlineInputBorder(),
                ),
              )
            else
              _isLoadingTricks
                  ? const Center(child: CircularProgressIndicator())
                  : Autocomplete<Map<String, dynamic>>(
                      displayStringForOption: (option) => option['name'],
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text == '') {
                          return const Iterable<Map<String, dynamic>>.empty();
                        }
                        return _tricks.where((dynamic option) {
                          return option['name']
                              .toString()
                              .toLowerCase()
                              .contains(textEditingValue.text.toLowerCase());
                        }).cast<Map<String, dynamic>>();
                      },
                      onSelected: (Map<String, dynamic> selection) {
                        setState(() => _selectedTrick = selection);
                      },
                      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          onSubmitted: (value) => onFieldSubmitted(),
                          decoration: InputDecoration(
                            labelText: widget.localizations.selectTrick,
                            border: const OutlineInputBorder(),
                          ),
                        );
                      },
                    ),
            const SizedBox(height: 16),
            if (_type == GoalType.trick)
              TextField(
                controller: _countController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: widget.localizations.targetCount,
                  border: const OutlineInputBorder(),
                ),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _minutesController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: widget.localizations.timerMinutes,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.timer),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                final String title = _type == GoalType.text 
                    ? _titleController.text 
                    : (_selectedTrick?['name'] ?? "");
                
                if (title.isEmpty && _type == GoalType.text) return;
                if (_type == GoalType.trick && _selectedTrick == null) return;

                final int? targetCount = int.tryParse(_countController.text);
                final int? minutes = int.tryParse(_minutesController.text);

                final goal = SessionGoal(
                  title: title,
                  type: _type,
                  trickId: _selectedTrick?['id'],
                  targetCount: targetCount,
                  timerDuration: minutes != null ? Duration(minutes: minutes) : null,
                  remainingTime: minutes != null ? Duration(minutes: minutes) : null,
                  isPaused: true,
                );
                widget.onGoalAdded(goal);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF004D40),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
              child: Text(widget.localizations.addGoal),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
