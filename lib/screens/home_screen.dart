import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/home/user_info_card.dart';
import '../widgets/home/time_display.dart';
import '../widgets/home/action_buttons.dart';
import '../widgets/home/current_location.dart';
import '../widgets/home/attendance_history.dart';
import '../widgets/home/live_location_map.dart';
import '../widgets/common/custom_app_bar.dart';
import '../providers/attendance_provider.dart';
import '../screens/order_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isInOffice = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // Fetch attendance data when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AttendanceProvider>();
      provider.fetchAttendanceCount();
      provider.fetchAttendanceHistory();
    });
  }

  void _handleLocationStatus(bool isInOffice) {
    setState(() {
      _isInOffice = isInOffice;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: CustomAppBar(scaffoldKey: _scaffoldKey),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue[700],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 35, color: Colors.blue),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Welcome',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'user@example.com',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
                // Already on home screen
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart),
              title: const Text('Orders'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const OrderScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Attendance'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to attendance
              },
            ),
            ListTile(
              leading: const Icon(Icons.event_busy),
              title: const Text('Leave Requests'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to leave requests
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('History'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to history
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to settings
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pop(context);
                // Handle logout
              },
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final provider = context.read<AttendanceProvider>();
          await Future.wait([
            provider.fetchAttendanceCount(),
            provider.fetchAttendanceHistory(),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // User Info Card with attendance data
                Consumer<AttendanceProvider>(
                  builder: (context, attendanceProvider, child) {
                    return UserInfoCard(
                      attendanceCount: attendanceProvider.attendanceCount,
                      isLoading: attendanceProvider.isLoading,
                      error: attendanceProvider.error,
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Map Placeholder
                LiveLocationMap(onLocationStatusChanged: _handleLocationStatus),

                const SizedBox(height: 16),

                // Time Display
                const TimeDisplay(),

                const SizedBox(height: 16),

                // Action Buttons
                const ActionButtons(),

                const SizedBox(height: 16),

                // Current Location
                CurrentLocation(isInOffice: _isInOffice),

                const SizedBox(height: 24),

                // Attendance History
                const AttendanceHistory(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
