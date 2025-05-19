import 'dart:async';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // Simulasi splash screen minimal 2 detik
    await Future.delayed(Duration(seconds: 3));

    bool isLoggedIn = await _authService.isLoggedIn();

    if (!mounted) return;

    // Navigate based on login status
    if (isLoggedIn) {
      // Tanpa validasi token, langsung ke home screen
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => HomeScreen()));
    } else {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo aplikasi
            Image.asset('assets/logo_splace_screen.png', height: 250),
            SizedBox(height: 30),

            // Loading indicator
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green[700]!),
            ),
            SizedBox(height: 20),

            // Text loading
            Text(
              'Memuat Aplikasi...',
              style: TextStyle(fontSize: 16, color: const Color(0xFF757575)),
            ),
          ],
        ),
      ),
    );
  }
}
