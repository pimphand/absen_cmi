import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';
import 'screens/main_screen.dart';
import 'screens/history_screen.dart';
import 'screens/blacklist_screen.dart';
import 'screens/profile_screen.dart';
import 'package:provider/provider.dart';
import 'providers/attendance_provider.dart';
import 'services/notification_service.dart';
import 'package:logging/logging.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize logging
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

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
          title: 'Cikurai Mediatama',
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
          initialRoute: '/',
          routes: {
            '/': (context) => SplashScreen(),
            '/main': (context) => const MainScreen(),
            '/history': (context) => const HistoryScreen(),
            '/blacklist': (context) => const BlacklistScreen(),
            '/profile': (context) => const ProfileScreen(),
          },
          onGenerateRoute: (settings) {
            // Handle any unknown routes
            if (settings.name == '/') {
              return MaterialPageRoute(builder: (context) => SplashScreen());
            }
            return MaterialPageRoute(
              builder: (context) => Scaffold(
                body: Center(
                  child: Text('Route ${settings.name} not found'),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
}
