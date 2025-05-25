import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../screens/order_screen.dart';
import '../../screens/attendance_screen.dart';
import '../../screens/leave_request_screen.dart';
import '../../screens/history_screen.dart';
import '../../screens/settings_screen.dart';
import '../../screens/home_screen.dart';
import '../../screens/login_screen.dart';
import '../../services/auth_service.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  Map<String, dynamic>? _userData;
  static const String CHECKED_IN_KEY = 'checked_in_status';
  static const String CHECKED_IN_TIME_KEY = 'checked_in_time';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userData = await AuthService.getUserData();
    if (mounted) {
      setState(() {
        _userData = userData;
      });
    }
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

  void _handleNavigation(BuildContext context, Widget screen) async {
    final isCheckedIn = await _isCheckedIn();
    if (!isCheckedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda harus absen terlebih dahulu'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.pop(context);
    } else {
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => screen),
      );
    }
  }

  String _getRoleName() {
    if (_userData != null && _userData!['role'] != null) {
      return _userData!['role']['display_name'] ?? 'Pengguna';
    }
    return 'Pengguna';
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(_userData?['name'] ?? ''),
            accountEmail: Text(_getRoleName()),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                (_userData?['name'] ?? '')[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
            decoration: BoxDecoration(
              color: Colors.green[700],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Beranda'),
            onTap: () => _handleNavigation(context, const HomeScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Absensi'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AttendanceScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Riwayat'),
            onTap: () => _handleNavigation(context, const HistoryScreen()),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Pengaturan'),
            onTap: () => _handleNavigation(context, const SettingsScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Keluar'),
            onTap: () async {
              await AuthService.logout();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}
