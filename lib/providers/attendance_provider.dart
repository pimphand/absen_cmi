import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import '../models/attendance_count.dart';
import '../models/attendance_history.dart';
import '../config/api_config.dart';
import '../services/auth_service.dart';

class AttendanceProvider extends ChangeNotifier {
  AttendanceCount? _attendanceCount;
  List<AttendanceHistory> _attendanceHistory = [];
  bool _isLoading = false;
  bool _isLoadingHistory = false;
  String? _error;
  bool _isCheckingIn = false;

  AttendanceCount? get attendanceCount => _attendanceCount;
  List<AttendanceHistory> get attendanceHistory => _attendanceHistory;
  bool get isLoading => _isLoading;
  bool get isLoadingHistory => _isLoadingHistory;
  String? get error => _error;
  bool get isCheckingIn => _isCheckingIn;

  Future<void> fetchAttendanceCount() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

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
          _attendanceCount = AttendanceCount.fromJson(jsonData['absen_count']);
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
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAttendanceHistory() async {
    try {
      _isLoadingHistory = true;
      _error = null;
      notifyListeners();

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
        if (jsonData['data'] != null && jsonData['data']['data'] != null) {
          _attendanceHistory =
              (jsonData['data']['data'] as List)
                  .map((item) => AttendanceHistory.fromJson(item))
                  .toList();
        } else {
          throw Exception('Invalid response format: data not found');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please login again');
      } else {
        throw Exception(
          'Failed to load attendance history: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching attendance history: $e');
      _error = e.toString();
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  double _calculateDistance(double currentLat, double currentLng) {
    return Geolocator.distanceBetween(
      currentLat,
      currentLng,
      ApiConfig.officeLatitude,
      ApiConfig.officeLongitude,
    );
  }

  Future<Map<String, dynamic>> checkIn({
    required double latitude,
    required double longitude,
  }) async {
    try {
      _isCheckingIn = true;
      _error = null;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AuthService.TOKEN_KEY);

      if (token == null) {
        throw Exception('Token not found');
      }

      // Hitung jarak dalam meter
      final distance = _calculateDistance(latitude, longitude);

      final response = await http.post(
        Uri.parse(ApiConfig.getCheckInUrl()),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'latitude_check_in': latitude.toString(),
          'longitude_check_in': longitude.toString(),
          'jarak': distance.toString(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = json.decode(response.body);
        // Refresh attendance count and history after successful check-in
        await Future.wait([fetchAttendanceCount(), fetchAttendanceHistory()]);
        return {
          'success': true,
          'message': jsonData['message'] ?? 'Check-in successful',
          'data': jsonData['data'],
        };
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please login again');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to check in');
      }
    } catch (e) {
      print('Error during check-in: $e');
      _error = e.toString();
      return {'success': false, 'message': e.toString()};
    } finally {
      _isCheckingIn = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> checkOut({
    required double latitude,
    required double longitude,
    required String attendanceId,
  }) async {
    try {
      _isCheckingIn = true;
      _error = null;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AuthService.TOKEN_KEY);

      if (token == null) {
        throw Exception('Token not found');
      }

      // Hitung jarak dalam meter
      final distance = _calculateDistance(latitude, longitude);

      final response = await http.post(
        Uri.parse('${ApiConfig.getCheckOutUrl()}/$attendanceId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'latitude_check_out': latitude.toString(),
          'longitude_check_out': longitude.toString(),
          'jarak': distance.toString(),
          '_method': 'PUT',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = json.decode(response.body);
        // Refresh attendance count and history after successful check-out
        await Future.wait([fetchAttendanceCount(), fetchAttendanceHistory()]);
        return {
          'success': true,
          'message': jsonData['message'] ?? 'Check-out successful',
          'data': jsonData['data'],
        };
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please login again');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to check out');
      }
    } catch (e) {
      print('Error during check-out: $e');
      _error = e.toString();
      return {'success': false, 'message': e.toString()};
    } finally {
      _isCheckingIn = false;
      notifyListeners();
    }
  }
}
