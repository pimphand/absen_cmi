import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:absen_cmi/models/order.dart';
import 'dart:async';
import 'package:absen_cmi/services/auth_service.dart';
import 'package:absen_cmi/config/api_config.dart';
import 'package:absen_cmi/widgets/common/custom_app_bar.dart';
import 'package:absen_cmi/widgets/order/order_list_widget.dart';
import 'package:absen_cmi/widgets/common/app_drawer.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({Key? key}) : super(key: key);

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _userData;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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

  Future<void> _handleLogout() async {
    try {
      await AuthService.logout();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging out: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: CustomAppBar(
        title: 'Dep Collector',
        scaffoldKey: _scaffoldKey,
      ),
      drawer: const AppDrawer(),
      body: _userData == null
          ? const Center(child: CircularProgressIndicator())
          : const OrderListWidget(),
    );
  }
}
