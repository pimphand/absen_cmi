import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:absen_cmi/models/order.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:absen_cmi/services/auth_service.dart';
import 'package:absen_cmi/config/api_config.dart';
import '../widgets/custom_bottom_navigation.dart';
import 'home_screen.dart';
import 'blacklist_screen.dart';
import 'profile_screen.dart';
import 'order_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _currentIndex = 1;
  List<Order> _orders = [];
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String? _selectedStatus;
  int _currentPage = 1;
  int _lastPage = 1;
  SharedPreferences? _prefs;
  String? _authToken;

  @override
  void initState() {
    super.initState();
    _initPrefsAndToken();
    _searchController.addListener(() {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 500), () {
        _currentPage = 1;
        _fetchOrders(query: _searchController.text, status: _selectedStatus);
      });
    });
  }

  Future<void> _initPrefsAndToken() async {
    _prefs = await SharedPreferences.getInstance();
    _authToken = _prefs!.getString(AuthService.TOKEN_KEY);
    _fetchOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchOrders({String? query, String? status, int? page}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (_authToken == null) {
      setState(() {
        _errorMessage = 'Authentication token not found.';
        _isLoading = false;
      });
      return;
    }

    try {
      String apiUrl = '${ApiConfig.ordersEndpoint}';
      final queryParams = <String, String>{};

      if (query != null && query.isNotEmpty) {
        queryParams['search'] = query;
      }
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      queryParams['page'] = (page ?? _currentPage).toString();

      if (queryParams.isNotEmpty) {
        final queryString = queryParams.entries
            .map((e) =>
                '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
            .join('&');
        apiUrl += '?$queryString';
      }

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final List<dynamic> orderData = jsonResponse['data'] ?? [];
        final Map<String, dynamic> meta = jsonResponse['meta'] ?? {};

        setState(() {
          _orders = orderData.map((data) => Order.fromJson(data)).toList();
          _currentPage = meta['current_page'] ?? 1;
          _lastPage = meta['last_page'] ?? 1;
        });
      } else {
        setState(() {
          _errorMessage = 'Gagal memuat pesanan: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal mengambil pesanan: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.white,
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Transaksi',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              'Riwayat transaksi pelanggan',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF217A3B),
        elevation: 2,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            color: Colors.white,
            onPressed: () => _fetchOrders(
              query: _searchController.text,
              status: _selectedStatus,
            ),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari Customer',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedStatus = 'process';
                    });
                    _fetchOrders(
                        query: _searchController.text, status: 'process');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedStatus == 'process'
                        ? Colors.orange[700]
                        : Colors.orange[600],
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Proses'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedStatus = 'success';
                    });
                    _fetchOrders(
                        query: _searchController.text, status: 'success');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedStatus == 'success'
                        ? Colors.green[700]
                        : Colors.green[600],
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Sukses'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedStatus = 'cancel';
                    });
                    _fetchOrders(
                        query: _searchController.text, status: 'cancel');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedStatus == 'cancel'
                        ? Colors.red[700]
                        : Colors.red[600],
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Batal'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(child: Text('Error: $_errorMessage'))
                    : _orders.isEmpty
                        ? const Center(
                            child: Text('Tidak ada pesanan ditemukan.'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16.0),
                            itemCount: _orders.length,
                            itemBuilder: (context, index) {
                              final order = _orders[index];
                              return OrderListItemWidget(
                                order: order,
                                onRefresh: () => _fetchOrders(
                                  query: _searchController.text,
                                  status: _selectedStatus,
                                ),
                              );
                            },
                          ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                  onPressed: _currentPage > 1
                      ? () {
                          _fetchOrders(
                              query: _searchController.text,
                              status: _selectedStatus,
                              page: _currentPage - 1);
                        }
                      : null,
                  child: const Text('Sebelumnya'),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    'Page $_currentPage dari $_lastPage',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                  onPressed: _currentPage < _lastPage
                      ? () {
                          _fetchOrders(
                              query: _searchController.text,
                              status: _selectedStatus,
                              page: _currentPage + 1);
                        }
                      : null,
                  child: const Text('Selanjutnya'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedStatus = null;
                      _searchController.clear();
                      _currentPage = 1;
                    });
                    _fetchOrders();
                  },
                  child: const Text('Hapus Filter'),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          switch (index) {
            case 0:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
              break;
            case 1:
              // Already on history screen
              break;
            case 2:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const BlacklistScreen()),
              );
              break;
            case 3:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
              break;
          }
        },
      ),
    );
  }
}

class OrderListItemWidget extends StatelessWidget {
  final Order order;
  final VoidCallback onRefresh;
  final currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  OrderListItemWidget({
    Key? key,
    required this.order,
    required this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderDetailScreen(
                order: order,
                onRefresh: onRefresh,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.customer?.storeName ?? 'Toko Tidak Diketahui',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.customer?.name ?? 'Pelanggan Tidak Diketahui',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      order.status?.toUpperCase() ?? 'TIDAK DIKETAHUI',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ID Pesanan',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '#${order.id}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Item',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '${order.quantity} item',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Harga',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        currencyFormat.format(order.totalPrice),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Dibayar',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        currencyFormat.format(order.paid),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sisa',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        currencyFormat.format(order.remaining),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OrderDetailScreen(
                            order: order,
                            onRefresh: onRefresh,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('Lihat Detail'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'process':
        return Colors.orange;
      case 'success':
        return Colors.green;
      case 'cancel':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
