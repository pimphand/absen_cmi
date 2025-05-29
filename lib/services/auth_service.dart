import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class AuthService {
  // Keys untuk SharedPreferences
  static const String TOKEN_KEY = 'auth_token';
  static const String USER_KEY = 'user_data';
  static const String CHECKED_IN_KEY = 'checked_in_status';
  static const String CHECKED_IN_TIME_KEY = 'checked_in_time';

  // Autentikasi user dengan username dan password
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.loginEndpoint),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
        },
        body: jsonEncode(<String, String>{
          'username': username,
          'password': password,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Simpan token dan data user
        await saveToken(responseData['token']);
        await saveUserData(responseData['user']);

        print('Login successful: ${responseData['message']}');

        return {
          'success': true,
          'message': responseData['message'] ?? 'Login berhasil',
          'data': responseData,
        };
      } else {
        print('Login error: ${responseData['message']}');

        return {
          'success': false,
          'message': responseData['message'] ?? 'Login gagal',
        };
      }
    } catch (e) {
      String errorMessage;
      if (e.toString().contains('SocketException')) {
        errorMessage =
            'Tidak dapat terhubung ke server. Mohon periksa koneksi internet Anda.';
      } else if (e.toString().contains('TimeoutException')) {
        errorMessage = 'Koneksi ke server timeout. Mohon coba lagi.';
      } else {
        errorMessage = 'Terjadi kesalahan: ${e.toString()}';
      }

      print('Login error: $errorMessage');

      return {'success': false, 'message': errorMessage};
    }
  }

  // Logout - Hapus token dan user data
  static Future<bool> logout() async {
    try {
      final token = await getToken();
      if (token != null) {
        final response = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/logout'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );

        if (response.statusCode != 200) {
          print('Logout API error: ${response.body}');
          return false;
        }
      }
    } catch (e) {
      print('Error during logout API call: $e');
      return false;
    } finally {
      // Always clear local storage regardless of API call result
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(TOKEN_KEY);
      await prefs.remove(USER_KEY);
      await prefs.remove(CHECKED_IN_KEY);
      await prefs.remove(CHECKED_IN_TIME_KEY);
    }
    return true;
  }

  // Cek apakah user sudah login
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(TOKEN_KEY);
    return token != null && token.isNotEmpty;
  }

  // Dapatkan token yang tersimpan
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(TOKEN_KEY);
  }

  // Dapatkan data user yang tersimpan
  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(USER_KEY);
    if (userData != null) {
      try {
        return jsonDecode(userData);
      } catch (e) {
        print('Error parsing user data: $e');
        return null;
      }
    }
    return null;
  }

  // Opsional: Validasi token (jika API memiliki endpoint untuk ini)
  Future<bool> validateToken() async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) {
        return false;
      }

      // Ganti dengan endpoint validasi token yang sesuai
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/validate-token'),
        headers: {'Authorization': 'Bearer $token'},
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error validating token: $e');
      return false;
    }
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(TOKEN_KEY, token);
    ApiConfig.token = token; // Set token in ApiConfig
  }

  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(USER_KEY, jsonEncode(userData));
  }
}
