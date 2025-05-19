class AppConstants {
  // App information
  static const String appName = 'Sistem Absensi';
  static const String appVersion = '1.0.0';

  // Shared preferences keys
  static const String prefKeyToken = 'auth_token';
  static const String prefKeyUserData = 'user_data';
  static const String prefKeyIsFirstTime = 'is_first_time';

  // App colors
  static const int primaryColorValue = 0xFF1B5E20; // dark green
  static const int secondaryColorValue = 0xFF388E3C; // medium green
  static const int accentColorValue = 0xFF4CAF50; // light green

  // Image assets
  static const String logoPath = 'assets/logo_splace_screen.png';
  static const String backgroundPath = 'assets/background.png';

  // Timeouts
  static const int connectionTimeout = 30000; // milliseconds
  static const int receiveTimeout = 30000; // milliseconds
}
