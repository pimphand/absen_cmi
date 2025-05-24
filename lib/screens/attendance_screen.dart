import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/attendance/user_info_card.dart';
import '../widgets/attendance/time_display.dart';
import '../widgets/attendance/action_buttons.dart';
import '../widgets/attendance/current_location.dart';
import '../widgets/attendance/attendance_history.dart';
import '../widgets/attendance/live_location_map.dart';
import '../widgets/common/custom_app_bar.dart';
import '../widgets/common/app_drawer.dart';
import '../providers/attendance_provider.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({Key? key}) : super(key: key);

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
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
      appBar: CustomAppBar(
        title: 'Absensi',
        scaffoldKey: _scaffoldKey,
      ),
      drawer: const AppDrawer(),
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
