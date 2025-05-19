class AttendanceCount {
  final int late;
  final int present;

  AttendanceCount({required this.late, required this.present});

  factory AttendanceCount.fromJson(Map<String, dynamic> json) {
    return AttendanceCount(
      late: json['late'] ?? 0,
      present: json['present'] ?? 0,
    );
  }
}
