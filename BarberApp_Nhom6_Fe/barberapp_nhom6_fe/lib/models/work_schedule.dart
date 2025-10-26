class WorkSchedule {
  final int id;
  final int stylistId;
  final String weekday; // Mon, Tue, Wed...
  final String startTime;
  final String endTime;
  final String? stylistName;

  WorkSchedule({
    required this.id,
    required this.stylistId,
    required this.weekday,
    required this.startTime,
    required this.endTime,
    this.stylistName,
  });

  factory WorkSchedule.fromJson(Map<String, dynamic> json) {
    return WorkSchedule(
      id: json['id'] as int,
      stylistId: json['stylist_id'] as int,
      weekday: json['weekday'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      stylistName: json['stylist']?['name'],
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
