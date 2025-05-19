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

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isInOffice = false;

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
      appBar: const CustomAppBar(),
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
