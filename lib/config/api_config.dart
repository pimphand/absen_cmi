class ApiConfig {
  // Base URL untuk API
  static const String baseUrl = 'https://absensi.dmpt.my.id/api';

  // Endpoint spesifik
  static const String loginEndpoint = '$baseUrl/login';
  static const String logoutEndpoint = '$baseUrl/absen';
  static const String profileEndpoint = '$baseUrl/profile';
  static const String attendanceEndpoint = '/absen';
  static const String checkInEndpoint = '/check-in';
  static const String leavesEndpoint = '/leaves';
  // Tambahkan endpoint lain sesuai kebutuhan

  // Lokasi Kantor
  static const double officeLatitude =
      -7.196792630380083; // Sesuaikan dengan lokasi kantor
  static const double officeLongitude =
      107.89481461109789; // Sesuaikan dengan lokasi kantor
  // Waktu Absensi
  static const int checkOutHour = 06; // 6 PM
  static const int checkOutMinute = 30; // 30 minutes

  static String getAttendanceUrl() => '$baseUrl$attendanceEndpoint';
  static String getCheckInUrl() {
    return '$baseUrl/absen';
  }

  static String getCheckOutUrl() {
    return '$baseUrl/absen';
  }
}
