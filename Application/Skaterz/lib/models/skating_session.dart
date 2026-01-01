class SkatingSession {
  final int? id;
  final DateTime sessionDate;
  final String mood; // GREAT, OK, BAD, INJURED

  SkatingSession({
    this.id,
    required this.sessionDate,
    required this.mood,
  });

  factory SkatingSession.fromJson(Map<String, dynamic> json) {
    return SkatingSession(
      id: json['id'],
      sessionDate: DateTime.parse(json['sessionDate']),
      mood: json['mood'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sessionDate': sessionDate.toIso8601String().split('T')[0],
      'mood': mood,
    };
  }
}
