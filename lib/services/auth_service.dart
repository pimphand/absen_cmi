import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class AuthService {
  // Keys untuk SharedPreferences
  static const String TOKEN_KEY = 'token';
  static const String USER_KEY = 'user';

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
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(TOKEN_KEY, responseData['token']);
        await prefs.setString(USER_KEY, jsonEncode(responseData['user']));

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
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(TOKEN_KEY);
    await prefs.remove(USER_KEY);

    // Opsional: Panggil API logout jika diperlukan
    // final token = await getToken();
    // if (token != null) {
    //   await http.post(
    //     Uri.parse(ApiConfig.logoutEndpoint),
    //     headers: {
    //       'Authorization': 'Bearer $token',
    //     },
    //   );
    // }
  }

  // Cek apakah user sudah login
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(TOKEN_KEY);
    return token != null && token.isNotEmpty;
  }

  // Dapatkan token yang tersimpan
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(TOKEN_KEY);
  }

  // Dapatkan data user yang tersimpan
  Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(USER_KEY);
    if (userData != null && userData.isNotEmpty) {
      return jsonDecode(userData);
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
}
