import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  Future<void> _login() async {
    final String username = _usernameController.text;
    final String password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      _showSnackBar('Silakan masukkan username dan password');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _authService.login(username, password);

      setState(() {
        _isLoading = false;
      });

      if (result['success']) {
        _showSnackBar(result['message']);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      } else {
        _showSnackBar(result['message']);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      String errorMessage;
      if (e.toString().contains('SocketException')) {
        errorMessage =
            'Tidak dapat terhubung ke server. Mohon periksa koneksi internet Anda.';
      } else if (e.toString().contains('TimeoutException')) {
        errorMessage = 'Koneksi ke server timeout. Mohon coba lagi.';
      } else {
        errorMessage = 'Terjadi kesalahan: ${e.toString()}';
      }

      _showErrorDialog('Kesalahan Jaringan', errorMessage);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: Duration(seconds: 3)),
    );
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
            ],
          ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // Logo
                Image.asset('assets/logo_splace_screen.png', height: 216),
                SizedBox(height: 24.0),

                // Username TextField
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                SizedBox(height: 18.0),

                // Password TextField
                TextField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: _togglePasswordVisibility,
                    ),
                  ),
                ),
                SizedBox(height: 24.0),

                // Login Button and Fingerprint Icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          backgroundColor: Colors.green[700],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24.0),
                          ),
                        ),
                        child:
                            _isLoading
                                ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: const Color.fromARGB(
                                      255,
                                      128,
                                      67,
                                      67,
                                    ),
                                    strokeWidth: 2.0,
                                  ),
                                )
                                : Text(
                                  'LOGIN',
                                  style: TextStyle(
                                    fontSize: 18.0,
                                    color: Colors.white,
                                  ),
                                ),
                      ),
                    ),
                    SizedBox(width: 16.0),

                    // Fingerprint Icon
                    // InkWell(
                    //   onTap:
                    //       _isLoading
                    //           ? null
                    //           : () {
                    //             // TODO: Implement fingerprint authentication functionality
                    //             _showSnackBar(
                    //               'Fitur fingerprint akan segera tersedia',
                    //             );
                    //           },
                    //   child: CircleAvatar(
                    //     radius: 28.0,
                    //     backgroundColor: Colors.green[700],
                    //     child: Icon(
                    //       Icons.fingerprint,
                    //       size: 36.0,
                    //       color: Colors.white,
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
