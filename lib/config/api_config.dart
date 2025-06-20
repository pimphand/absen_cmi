class ApiConfig {
  // Base URL untuk API
  static const String baseUrl = 'https://absen.mandalikaputrabersama.com/api';
  static const String assetsUrl =
      'https://absen.mandalikaputrabersama.com/storage/';

  // Token management
  static String? _token;
  static String get token => _token ?? '';
  static set token(String value) => _token = value;

  // Cikurai API
  static const String cikuraiBaseUrl =
      'https://cikurai.mandalikaputrabersama.com/api';

  static const String cikuraiStorageUrl =
      'https://pub-c73a61cdd96c4868a7ef3bceafbaeef9.r2.dev/';
  static const String cikuraiProductsEndpoint = '$baseUrl/products';
  static String cikuraiProductDetailEndpoint(String id) =>
      '$cikuraiBaseUrl/products/$id';

  // Endpoint spesifik
  static const String loginEndpoint = '$baseUrl/login';
  static const String logoutEndpoint = '$baseUrl/absen';
  static const String profileEndpoint = '$baseUrl/profile';
  static const String attendanceEndpoint = '/absen';
  static const String checkInEndpoint = '/check-in';
  static const String leavesEndpoint = '/leaves';
  static const String ordersEndpoint = '$baseUrl/orders';
  static const String brandsEndpoint = '$baseUrl/brands';

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
