import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AttendanceService {
  static const String _baseUrl =
      'https://cikurai.mandalikaputrabersama.com/api';

  Future<Map<String, dynamic>> checkAttendance() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/absen-check-in'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'checked_in': data['checked_in'] ?? false,
          'message': data['message'] ?? 'Attendance check successful',
        };
      } else {
        return {
          'success': false,
          'checked_in': false,
          'message': 'Failed to check attendance status',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'checked_in': false,
        'message': 'Error checking attendance: $e',
      };
    }
  }
}
