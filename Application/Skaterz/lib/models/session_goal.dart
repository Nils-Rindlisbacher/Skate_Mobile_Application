enum GoalType { text, trick }

class SessionGoal {
  final int? id;
  final String title;
  final GoalType type;
  final int? trickId;
  final int? targetCount;
  int currentCount;
  final Duration? timerDuration;
  Duration? remainingTime;
  bool isCompleted;
  bool isPaused;

  SessionGoal({
    this.id,
    required this.title,
    required this.type,
    this.trickId,
    this.targetCount,
    this.currentCount = 0,
    this.timerDuration,
    this.remainingTime,
    this.isCompleted = false,
    this.isPaused = true,
  });

  factory SessionGoal.fromJson(Map<String, dynamic> json) {
    return SessionGoal(
      id: json['id'],
      title: json['title'],
      type: json['type'] == 'trick' ? GoalType.trick : GoalType.text,
      trickId: json['trickId'],
      targetCount: json['targetCount'],
      currentCount: json['currentCount'] ?? 0,
      timerDuration: json['timerDuration'] != null ? Duration(seconds: json['timerDuration']) : null,
      remainingTime: json['remainingTime'] != null ? Duration(seconds: json['remainingTime']) : null,
      isCompleted: json['completed'] ?? false,
      isPaused: true, // Default to paused when loaded
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type == GoalType.trick ? 'trick' : 'text',
      'trickId': trickId,
      'targetCount': targetCount,
      'currentCount': currentCount,
      'timerDuration': timerDuration?.inSeconds,
      'remainingTime': remainingTime?.inSeconds,
      'completed': isCompleted,
    };
  }
}
