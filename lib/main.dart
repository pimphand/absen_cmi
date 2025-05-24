import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'providers/attendance_provider.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set orientasi layar ke portrait only
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();

  runApp(
    ChangeNotifierProvider.value(
      value: notificationService,
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AttendanceProvider())
        ],
        child: MaterialApp(
          title: 'Absensi CMI',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primaryColor: Colors.green[700],
            primarySwatch: Colors.green,
            visualDensity: VisualDensity.adaptivePlatformDensity,
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: Colors.green[700]!),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
              ),
            ),
          ),
          home: SplashScreen(),
        ),
      ),
    ),
  );
}
