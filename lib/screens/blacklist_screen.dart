import 'package:flutter/material.dart';
import '../widgets/custom_bottom_navigation.dart';
import 'home_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';

class BlacklistScreen extends StatefulWidget {
  const BlacklistScreen({Key? key}) : super(key: key);

  @override
  State<BlacklistScreen> createState() => _BlacklistScreenState();
}

class _BlacklistScreenState extends State<BlacklistScreen> {
  int _currentIndex = 2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CS Blacklist'),
        backgroundColor: const Color(0xFF217A3B),
      ),
      body: const Center(
        child: Text('CS Blacklist Screen Content'),
      ),
    );
  }
}
