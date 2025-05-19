class AttendanceHistory {
  final String id;
  final String attendanceDate;
  final String checkIn;
  final String? checkOut;
  final double latitudeCheckIn;
  final double longitudeCheckIn;
  final double? latitudeCheckOut;
  final double? longitudeCheckOut;
  final String? photoCheckIn;
  final String? photoCheckOut;
  final String statusCheckIn;
  final String? statusCheckOut;

  AttendanceHistory({
    required this.id,
    required this.attendanceDate,
    required this.checkIn,
    this.checkOut,
    required this.latitudeCheckIn,
    required this.longitudeCheckIn,
    this.latitudeCheckOut,
    this.longitudeCheckOut,
    this.photoCheckIn,
    this.photoCheckOut,
    required this.statusCheckIn,
    this.statusCheckOut,
  });

  factory AttendanceHistory.fromJson(Map<String, dynamic> json) {
    return AttendanceHistory(
      id: json['id']?.toString() ?? '',
      attendanceDate: json['attendance_date']?.toString() ?? '',
      checkIn: json['check_in']?.toString() ?? '',
      checkOut: json['check_out']?.toString(),
      latitudeCheckIn:
          double.tryParse(json['latitude_check_in']?.toString() ?? '0') ?? 0.0,
      longitudeCheckIn:
          double.tryParse(json['longitude_check_in']?.toString() ?? '0') ?? 0.0,
      latitudeCheckOut:
          json['latitude_check_out'] != null
              ? double.tryParse(json['latitude_check_out'].toString()) ?? 0.0
              : null,
      longitudeCheckOut:
          json['longitude_check_out'] != null
              ? double.tryParse(json['longitude_check_out'].toString()) ?? 0.0
              : null,
      photoCheckIn: json['photo_check_in']?.toString(),
      photoCheckOut: json['photo_check_out']?.toString(),
      statusCheckIn: json['status_check_in']?.toString() ?? 'pending',
      statusCheckOut: json['status_check_out']?.toString(),
    );
  }

  DateTime get checkInDateTime {
    try {
      final date = DateTime.parse(attendanceDate);
      final timeParts = checkIn.split(':');
      if (timeParts.length != 3) {
        return DateTime.now();
      }
      return DateTime(
        date.year,
        date.month,
        date.day,
        int.tryParse(timeParts[0]) ?? 0,
        int.tryParse(timeParts[1]) ?? 0,
        int.tryParse(timeParts[2]) ?? 0,
      );
    } catch (e) {
      print('Error parsing date/time: $e');
      return DateTime.now();
    }
  }
}
