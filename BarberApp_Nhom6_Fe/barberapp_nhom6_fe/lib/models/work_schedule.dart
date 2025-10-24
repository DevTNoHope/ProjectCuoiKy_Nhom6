class WorkSchedule {
  final int id;
  final int stylistId;
  final String weekday; // Mon, Tue, Wed...
  final String startTime;
  final String endTime;

  WorkSchedule({
    required this.id,
    required this.stylistId,
    required this.weekday,
    required this.startTime,
    required this.endTime,
  });

  factory WorkSchedule.fromJson(Map<String, dynamic> json) {
    return WorkSchedule(
      id: json['id'] as int,
      stylistId: json['stylist_id'] as int,
      weekday: json['weekday'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'stylist_id': stylistId,
    'weekday': weekday,
    'start_time': startTime,
    'end_time': endTime,
  };
}
