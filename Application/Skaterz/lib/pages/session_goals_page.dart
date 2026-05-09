import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:skaterz/l10n/app_localizations.dart';
import 'package:skaterz/models/session_goal.dart';
import 'package:skaterz/services/api_service.dart';
import 'package:skaterz/widgets/login_required_view.dart';
import 'package:skaterz/core/constants.dart';

class SessionGoalsPage extends StatefulWidget {
  const SessionGoalsPage({
    super.key,
    required this.localizations,
    required this.isLoggedIn,
    required this.onLogin,
    required this.onMenuTap,
    required this.isDarkMode,
    required this.onThemeToggle,
    required this.onLanguageChange,
    this.isMenuExpanded = false,
  });

  final AppLocalizations localizations;
  final bool isLoggedIn;
  final VoidCallback onLogin;
  final VoidCallback onMenuTap;
  final bool isDarkMode;
  final Function(bool) onThemeToggle;
  final Function(String) onLanguageChange;
  final bool isMenuExpanded;

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
    } else {
      _isLoading = false;
    }
    _startTimer();
  }

  @override
  void didUpdateWidget(SessionGoalsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isLoggedIn && widget.isLoggedIn) {
      if (mounted) setState(() => _isLoading = true);
      _loadGoals();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadGoals() async {
    try {
      final cachedData = await _apiService.getCachedData('session_goals');
      if (cachedData != null && cachedData is List && mounted) {
        setState(() {
          _goals = cachedData
              .map((json) => SessionGoal.fromJson(json as Map<String, dynamic>))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Cache Load Error: $e");
    }

    try {
      final goalsData = await _apiService.getSessionGoals();
      if (mounted) {
        setState(() {
          _goals = goalsData.map((json) => SessionGoal.fromJson(json as Map<String, dynamic>)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
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
      if (mounted) setState(() => _goals.remove(goal));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.localizations.deleteFailed}: $e')),
        );
      }
    }
  }

  void _addNewGoal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => _AddGoalSheet(
        localizations: widget.localizations,
        onGoalAdded: (newGoal) async {
          Navigator.pop(sheetContext);
          if (mounted) setState(() => _isLoading = true);
          try {
            final savedGoalData = await _apiService.addSessionGoal(newGoal.toJson());
            if (mounted && savedGoalData != null) {
              setState(() {
                _goals.insert(0, SessionGoal.fromJson(savedGoalData));
                _isLoading = false;
              });
            }
          } catch (e) {
            if (mounted) {
              setState(() => _isLoading = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${widget.localizations.saveFailed}: $e'), backgroundColor: Colors.red),
              );
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (!widget.isLoggedIn) {
      return LoginRequiredView(
        localizations: widget.localizations,
        onLogin: widget.onLogin,
        featureName: widget.localizations.sessionGoalsTitle,
        icon: Icons.track_changes,
        onMenuTap: widget.onMenuTap,
        isDarkMode: widget.isDarkMode,
        isMenuExpanded: widget.isMenuExpanded,
        onThemeToggle: widget.onThemeToggle,
        onLanguageChange: widget.onLanguageChange,
      );
    }

    final openGoals = _goals.where((g) => !g.isCompleted).toList();
    final completedGoals = _goals.where((g) => g.isCompleted).toList();

    return Scaffold(
      body: _isLoading && _goals.isEmpty 
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadGoals,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    elevation: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    clipBehavior: Clip.antiAlias,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: AppColors.getDynamicGradient(context),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: colorScheme.onPrimary.withOpacity(0.2),
                          child: Icon(Icons.add, color: colorScheme.onPrimary),
                        ),
                        title: Text(
                          widget.localizations.addGoal,
                          style: TextStyle(
                            fontWeight: FontWeight.bold, 
                            fontSize: 18,
                            color: colorScheme.onPrimary,
                          ),
                        ),
                        subtitle: Text(
                          widget.localizations.goalHint,
                          style: TextStyle(color: colorScheme.onPrimary.withOpacity(0.8)),
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
                          style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5), fontSize: 16),
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
                              if (mounted) {
                                setState(() {
                                  goal.isCompleted = !goal.isCompleted;
                                  if (!goal.isCompleted) {
                                    goal.currentCount = 0;
                                    if (goal.timerDuration != null) {
                                      goal.remainingTime = goal.timerDuration;
                                      goal.isPaused = true;
                                    }
                                  }
                                });
                              }
                              _updateGoalOnServer(goal);
                            },
                            onTogglePause: () {
                              if (mounted) setState(() => goal.isPaused = !goal.isPaused);
                            },
                            onIncrement: () {
                              if (mounted) {
                                setState(() {
                                  goal.currentCount++;
                                  if (goal.targetCount != null && goal.currentCount >= goal.targetCount!) {
                                    goal.isCompleted = true;
                                  }
                                });
                              }
                              _updateGoalOnServer(goal);
                            },
                            onDecrement: () {
                              if (mounted && goal.currentCount > 0) {
                                setState(() {
                                  goal.currentCount--;
                                });
                                _updateGoalOnServer(goal);
                              }
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
                              if (mounted) {
                                setState(() {
                                  goal.isCompleted = !goal.isCompleted;
                                  if (!goal.isCompleted) {
                                    goal.currentCount = 0;
                                    if (goal.timerDuration != null) {
                                      goal.remainingTime = goal.timerDuration;
                                      goal.isPaused = true;
                                    }
                                  }
                                });
                              }
                              _updateGoalOnServer(goal);
                            },
                            onTogglePause: () {},
                            onIncrement: () {},
                            onDecrement: () {},
                          )),
                    ],
                  ],
                ],
              ),
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
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
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
    required this.onDecrement,
  });

  final AppLocalizations localizations;
  final SessionGoal goal;
  final VoidCallback onDelete;
  final VoidCallback onToggleComplete;
  final VoidCallback onTogglePause;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  String _formatStance(String stance) {
    switch (stance.toUpperCase()) {
      case 'REGULAR': return localizations.regular;
      case 'NOLLIE': return localizations.nollie;
      case 'SWITCH': return localizations.switchStance;
      case 'FAKIE': return localizations.fakie;
      default: return stance;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bool isTimerDisabled = goal.remainingTime != null && goal.isPaused;
    final bool isAddDisabled = goal.isCompleted || isTimerDisabled;
    
    final bool canManuallyComplete = goal.targetCount == null || 
                                     goal.currentCount >= goal.targetCount!;

    final accentColor = colorScheme.primary;

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
                  color: accentColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          decoration: goal.isCompleted ? TextDecoration.lineThrough : null,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      if (goal.type == GoalType.trick && goal.stance != null)
                        Text(
                          _formatStance(goal.stance!),
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurface.withOpacity(0.6),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: onDelete,
                ),
              ],
            ),
            
            if (goal.targetCount != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    "${goal.currentCount} / ${goal.targetCount}",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: colorScheme.onSurface),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.remove_circle_outline, color: isAddDisabled ? colorScheme.onSurface.withOpacity(0.2) : accentColor),
                    onPressed: isAddDisabled ? null : onDecrement,
                  ),
                  IconButton(
                    icon: Icon(
                      goal.isCompleted ? Icons.check_circle : Icons.add_circle, 
                      color: goal.isCompleted ? Colors.green : (isAddDisabled ? colorScheme.onSurface.withOpacity(0.2) : accentColor),
                    ),
                    onPressed: isAddDisabled ? null : onIncrement,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: (goal.targetCount != null && goal.targetCount! > 0) ? goal.currentCount / goal.targetCount! : 0,
                backgroundColor: colorScheme.onSurface.withOpacity(0.1),
                color: accentColor,
              ),
            ],

            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (goal.remainingTime != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.onSurface.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.timer, size: 16, color: colorScheme.onSurface.withOpacity(0.5)),
                        const SizedBox(width: 4),
                        Text(
                          _formatDuration(goal.remainingTime!),
                          style: TextStyle(
                            fontSize: 14,
                            color: goal.remainingTime == Duration.zero ? Colors.red : colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!goal.isCompleted && goal.remainingTime! > Duration.zero)
                    IconButton(
                      icon: Icon(goal.isPaused ? Icons.play_arrow : Icons.pause),
                      color: accentColor,
                      onPressed: onTogglePause,
                    ),
                ],

                if (canManuallyComplete || goal.isCompleted)
                  TextButton.icon(
                    onPressed: onToggleComplete,
                    icon: Icon(goal.isCompleted ? Icons.undo : Icons.check),
                    label: Text(goal.isCompleted ? localizations.undo : localizations.complete),
                    style: TextButton.styleFrom(
                      foregroundColor: goal.isCompleted ? colorScheme.onSurface.withOpacity(0.5) : accentColor,
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
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _countController = TextEditingController();
  final TextEditingController _minutesController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final FocusNode _titleFocusNode = FocusNode();
  String _selectedStance = 'REGULAR';
  List<Map<String, dynamic>> _tricks = [];
  bool _isLoadingTricks = false;

  @override
  void initState() {
    super.initState();
    _loadTricks();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _titleFocusNode.dispose();
    _countController.dispose();
    _minutesController.dispose();
    super.dispose();
  }

  Future<void> _loadTricks() async {
    if (!mounted) return;
    setState(() => _isLoadingTricks = true);
    
    final ApiService api = ApiService();
    
    try {
      final cached = await api.getCachedData('tricks_all');
      if (cached != null && cached is List && mounted) {
        setState(() {
          _tricks = List<Map<String, dynamic>>.from(cached);
        });
      }

      final tricks = await api.getTricks(size: 1000);
      if (!mounted) return;
      setState(() {
        _tricks = List<Map<String, dynamic>>.from(tricks);
        _isLoadingTricks = false;
      });
    } catch (e) {
      debugPrint("Load Tricks Error: $e");
      if (mounted) setState(() => _isLoadingTricks = false);
    }
  }

  List<String> _getAvailableStances(String trickName) {
    final name = trickName.toLowerCase();

    if (name == 'rock to fakie' || 
        name == 'rock n roll' || 
        name == 'blunt to fakie') {
      return ['REGULAR'];
    }
    return ['REGULAR', 'NOLLIE', 'SWITCH', 'FAKIE'];
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

  @override
  Widget build(BuildContext context) {
    final availableStances = _getAvailableStances(_titleController.text);
    if (!availableStances.contains(_selectedStance)) {
      _selectedStance = 'REGULAR';
    }
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
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
                onSelectionChanged: (val) {
                  setState(() {
                    _type = val.first;
                    _titleController.clear();
                  });
                },
              ),
              const SizedBox(height: 16),
              
              if (_type == GoalType.trick) ...[
                Autocomplete<Map<String, dynamic>>(
                  textEditingController: _titleController,
                  focusNode: _titleFocusNode,
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return const Iterable<Map<String, dynamic>>.empty();
                    }
                    final query = textEditingValue.text.toLowerCase();
                    
                    final filtered = _tricks.where((trick) {
                      final name = trick['name']?.toString().toLowerCase() ?? "";
                      return name.contains(query);
                    }).toList();

                    filtered.sort((a, b) {
                      final aName = a['name']?.toString().toLowerCase() ?? "";
                      final bName = b['name']?.toString().toLowerCase() ?? "";
                      
                      final aStarts = aName.startsWith(query);
                      final bStarts = bName.startsWith(query);

                      if (aStarts && !bStarts) return -1;
                      if (!aStarts && bStarts) return 1;
                      
                      if (aStarts && bStarts) {
                         return aName.length.compareTo(bName.length);
                      }

                      return aName.compareTo(bName);
                    });

                    return filtered;
                  },
                  onSelected: (option) {
                    setState(() {}); 
                  },
                  displayStringForOption: (option) => option['name']?.toString() ?? "",
                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        labelText: '${widget.localizations.selectTrick} *',
                        prefixIcon: const Icon(Icons.skateboarding),
                        suffixIcon: _isLoadingTricks ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                        ) : null,
                      ),
                      onChanged: (value) => setState(() {}),
                      onFieldSubmitted: (value) => onFieldSubmitted(),
                      validator: (value) => (value == null || value.isEmpty) ? widget.localizations.enterCredentials : null,
                    );
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedStance,
                  decoration: InputDecoration(
                    labelText: '${widget.localizations.stances} *',
                    prefixIcon: const Icon(Icons.directions_run),
                  ),
                  items: availableStances.map((stance) {
                    return DropdownMenuItem(
                      value: stance,
                      child: Text(_formatStance(stance)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedStance = val);
                  },
                ),
              ] else
                TextFormField(
                  controller: _titleController,
                  focusNode: _titleFocusNode,
                  decoration: InputDecoration(
                    labelText: '${widget.localizations.goalHint} *',
                    prefixIcon: const Icon(Icons.edit),
                  ),
                  validator: (value) => (value == null || value.isEmpty) ? widget.localizations.enterCredentials : null,
                ),
              
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _countController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: widget.localizations.targetCount,
                        prefixIcon: const Icon(Icons.repeat),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _minutesController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: widget.localizations.timerMinutes,
                        prefixIcon: const Icon(Icons.timer),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  if (!_formKey.currentState!.validate()) return;

                  final String title = _titleController.text.trim();
                  final targetCount = int.tryParse(_countController.text);
                  final minutes = int.tryParse(_minutesController.text);
                  final duration = minutes != null ? Duration(minutes: minutes) : null;

                  final newGoal = SessionGoal(
                    title: title,
                    type: _type,
                    trickId: _type == GoalType.trick ? (_tricks.firstWhere((t) => (t['name']?.toString() ?? "") == title, orElse: () => {})['id']) : null,
                    stance: _type == GoalType.trick ? _selectedStance : null,
                    targetCount: targetCount,
                    timerDuration: duration,
                    remainingTime: duration,
                  );
                  widget.onGoalAdded(newGoal);
                },
                child: Text(widget.localizations.saveAndContinue),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
