import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/customer.dart';
import '../config/api_config.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'dart:async';

class BlacklistScreen extends StatefulWidget {
  const BlacklistScreen({Key? key}) : super(key: key);

  @override
  State<BlacklistScreen> createState() => _BlacklistScreenState();
}

class _BlacklistScreenState extends State<BlacklistScreen> {
  List<Customer> _customers = [];
  bool _isLoading = true;
  String? _error;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fetchBlacklistedCustomers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchBlacklistedCustomers({String? searchQuery}) async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final url =
          '${ApiConfig.baseUrl}/customers?is_blacklist=1${searchQuery != null ? '&search=$searchQuery' : ''}';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${ApiConfig.token}',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null) {
          final List<dynamic> customersJson = data['data'];
          setState(() {
            _customers =
                customersJson.map((json) => Customer.fromJson(json)).toList();
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = 'No data found in response';
            _isLoading = false;
          });
        }
      } else if (response.statusCode == 401) {
        await AuthService.logout();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => LoginScreen()),
            (route) => false,
          );
        }
      } else {
        setState(() {
          _error =
              'Failed to load blacklisted customers. Status code: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _fetchBlacklistedCustomers(searchQuery: query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CS Blacklist'),
        backgroundColor: const Color(0xFF217A3B),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari Nama Toko / Nama Owner',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _error!,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _fetchBlacklistedCustomers(
                                searchQuery: _searchController.text,
                              ),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _customers.isEmpty
                        ? const Center(
                            child: Text('No blacklisted customers found'),
                          )
                        : ListView.builder(
                            itemCount: _customers.length,
                            itemBuilder: (context, index) {
                              final customer = _customers[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundImage: NetworkImage(
                                      customer.ownerPhoto.startsWith('http')
                                          ? customer.ownerPhoto
                                          : '${ApiConfig.cikuraiStorageUrl}${customer.ownerPhoto}',
                                    ),
                                    onBackgroundImageError:
                                        (exception, stackTrace) {
                                      print('Error loading image: $exception');
                                    },
                                  ),
                                  title: Text(customer.name),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Store: ${customer.storeName}'),
                                      Text('Phone: ${customer.phone}'),
                                      Text('Address: ${customer.address}'),
                                    ],
                                  ),
                                  isThreeLine: true,
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
