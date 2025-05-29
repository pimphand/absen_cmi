import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'attendance_screen.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();
  static const String CHECKED_IN_KEY = 'checked_in_status';
  static const String CHECKED_IN_TIME_KEY = 'checked_in_time';

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<bool> _isCheckedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final checkedInTime = prefs.getInt(CHECKED_IN_TIME_KEY);

    if (checkedInTime != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final difference = now - checkedInTime;
      // Check if 12 hours have passed (12 * 60 * 60 * 1000 milliseconds)
      if (difference < 12 * 60 * 60 * 1000) {
        return prefs.getBool(CHECKED_IN_KEY) ?? false;
      }
    }
    return false;
  }

  Future<void> _checkLoginStatus() async {
    try {
      // Check login status
      bool isLoggedIn = await _authService.isLoggedIn();

      if (!mounted) return;

      if (isLoggedIn) {
        // If logged in, check attendance status
        bool isCheckedIn = await _isCheckedIn();

        if (isCheckedIn) {
          // If already checked in, go to home screen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => HomeScreen()),
          );
        } else {
          // If not checked in, go to attendance screen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => AttendanceScreen()),
          );
        }
      } else {
        // If not logged in, go to login screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => LoginScreen()),
        );
      }
    } catch (e) {
      print('Error checking login status: $e');
      // If there's an error, redirect to login screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo_splace_screen.png',
              height: 250,
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
