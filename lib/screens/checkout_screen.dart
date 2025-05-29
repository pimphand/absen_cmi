import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/customer.dart';
import '../config/api_config.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/cart_service.dart';
import '../models/cart_item.dart';
import 'history_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({Key? key}) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Customer> _customers = [];
  Customer? _selectedCustomer;
  bool _isLoading = false;
  bool _isSubmitting = false;
  Timer? _debounce;
  late CartService _cartService;
  List<CartItem> _cartItems = [];
  double _total = 0;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _initCartService();
  }

  Future<void> _initCartService() async {
    final prefs = await SharedPreferences.getInstance();
    _cartService = CartService(prefs);
    _loadCartItems();
  }

  void _loadCartItems() {
    setState(() {
      _cartItems = _cartService.getCartItems();
      _total = _cartService.getTotal();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchCustomers(_searchController.text);
    });
  }

  Future<void> _searchCustomers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _customers = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/customers?search=$query'),
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
          });
        }
      }
    } catch (e) {
      print('Error searching customers: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createOrder() async {
    if (_selectedCustomer == null || _cartItems.isEmpty) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/orders'),
        headers: {
          'Authorization': 'Bearer ${ApiConfig.token}',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'customer_id': _selectedCustomer!.id,
          'items': _cartItems
              .map((item) => {
                    'product_id': item.productId,
                    'quantity': item.quantity,
                  })
              .toList(),
        }),
      );

      if (response.statusCode == 201) {
        // Clear cart after successful order
        await _cartService.clearCart();

        if (!mounted) return;

        // Show success notification
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Pesanan berhasil disimpan'),
              ],
            ),
            backgroundColor: Color(0xFF217A3B),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            margin: EdgeInsets.all(8),
          ),
        );

        // Navigate to history screen
        if (!mounted) return;

        // Pop all routes and push history screen
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/history',
          (route) => false,
        );
      } else {
        final errorData = jsonDecode(response.body);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorData['message'] ??
                'Terjadi kesalahan saat membuat pesanan'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pilih Customer',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Cari Customer',
                border: const OutlineInputBorder(),
                suffixIcon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.search),
              ),
            ),
            if (_customers.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _customers.length,
                  itemBuilder: (context, index) {
                    final customer = _customers[index];
                    return ListTile(
                      title: Text(customer.storeName),
                      subtitle: Text(customer.name),
                      onTap: () {
                        setState(() {
                          _selectedCustomer = customer;
                          _searchController.text = customer.storeName;
                          _customers = [];
                        });
                      },
                    );
                  },
                ),
              ),
            if (_selectedCustomer != null) ...[
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Informasi Customer',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow('Nama Toko', _selectedCustomer!.storeName),
                      _buildInfoRow('Nama Pemilik', _selectedCustomer!.name),
                      _buildInfoRow('Telepon', _selectedCustomer!.phone),
                      _buildInfoRow('Alamat', _selectedCustomer!.address),
                      if (_selectedCustomer!.city != null)
                        _buildInfoRow('Kota', _selectedCustomer!.city!),
                      if (_selectedCustomer!.state != null)
                        _buildInfoRow('Provinsi', _selectedCustomer!.state!),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            const Text(
              'Ringkasan Pesanan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            OrderSummaryCard(
              cartItems: _cartItems,
              total: _total,
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Pembayaran:',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Rp ${_total.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_selectedCustomer == null ||
                          _cartItems.isEmpty ||
                          _isSubmitting)
                      ? null
                      : _createOrder,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFF217A3B),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Simpan Order',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}

class OrderSummaryCard extends StatelessWidget {
  final List<CartItem> cartItems;
  final double total;

  const OrderSummaryCard({
    Key? key,
    required this.cartItems,
    required this.total,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ...cartItems
                .map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.name),
                                Text(
                                  '${item.quantity}x @ Rp ${item.price.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'Rp ${(item.price * item.quantity).toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Rp ${total.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
