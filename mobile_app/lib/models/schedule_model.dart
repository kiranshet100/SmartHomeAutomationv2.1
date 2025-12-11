class Schedule {
  final String id;
  final String name;
  final String time;
  final List<String> days;
  final String sceneId;
  final bool enabled;

  Schedule({
    required this.id,
    required this.name,
    required this.time,
    required this.days,
    required this.sceneId,
    required this.enabled,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['id'],
      name: json['name'],
      time: json['time'],
      days: List<String>.from(json['days']),
      sceneId: json['sceneId'],
      enabled: json['enabled'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'time': time,
      'days': days,
      'sceneId': sceneId,
      'enabled': enabled,
    };
  }
}
