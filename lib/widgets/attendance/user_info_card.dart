import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import 'package:http/http.dart' as http;
import '../../models/attendance_count.dart';
import '../../config/api_config.dart';

class UserInfoCard extends StatefulWidget {
  final AttendanceCount? attendanceCount;
  final bool isLoading;
  final String? error;

  const UserInfoCard({
    Key? key,
    this.attendanceCount,
    this.isLoading = false,
    this.error,
  }) : super(key: key);

  @override
  State<UserInfoCard> createState() => _UserInfoCardState();
}

class _UserInfoCardState extends State<UserInfoCard> {
  User? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString(AuthService.USER_KEY);

      print('Loading user data...');
      print('User data from SharedPreferences: $userData');

      if (userData != null) {
        final decodedData = jsonDecode(userData);
        print('Decoded user data: $decodedData');

        setState(() {
          _user = User.fromJson(decodedData);
          _isLoading = false;
        });
        print('User loaded successfully: ${_user?.name}');
      } else {
        print('No user data found in SharedPreferences');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<AttendanceCount> fetchAttendanceCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AuthService.TOKEN_KEY);

      if (token == null) {
        throw Exception('Token not found');
      }

      final response = await http.get(
        Uri.parse(ApiConfig.getAttendanceUrl()),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['absen_count'] != null) {
          return AttendanceCount.fromJson(jsonData['absen_count']);
        } else {
          throw Exception('Invalid response format: absen_count not found');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please login again');
      } else {
        throw Exception(
          'Failed to load attendance count: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching attendance count: $e');
      rethrow;
    }
  }

  Widget _buildAttendanceStat(String label, int count, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_user == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: Text('User data not found')),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.grey[300],
                  child: Icon(Icons.person, size: 40, color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _user?.roleName ?? 'User',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[800],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _user?.name ?? 'Unknown User',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _user?.email ?? 'No Email',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.grid_view),
                  onPressed: () {
                    // TODO: Implement grid icon action
                  },
                ),
              ],
            ),
            const Divider(height: 32),
            if (widget.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (widget.error != null)
              Center(
                child: Text(
                  'Error: ${widget.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              )
            else if (widget.attendanceCount != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAttendanceStat(
                    'Hadir',
                    widget.attendanceCount!.present,
                    Colors.green,
                  ),
                  _buildAttendanceStat(
                    'Terlambat',
                    widget.attendanceCount!.late,
                    Colors.red,
                  ),
                ],
              )
            else
              const Center(child: Text('No data available')),
          ],
        ),
      ),
    );
  }
}
