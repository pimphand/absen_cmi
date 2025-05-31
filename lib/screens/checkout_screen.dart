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
import 'dart:io';
import 'package:image_picker/image_picker.dart';

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
  File? _selectedImage;

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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
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
    if (_selectedCustomer == null || _cartItems.isEmpty) {
      print('Order creation failed: No customer selected or cart is empty');
      return;
    }

    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto tidak boleh kosong'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    print('Starting order creation process...');
    print(
        'Selected Customer: ${_selectedCustomer!.storeName} (ID: ${_selectedCustomer!.id})');
    print('Cart Items: ${_cartItems.length} items');
    _cartItems.forEach((item) {
      print('- ${item.name}: ${item.quantity}x @ Rp ${item.price}');
    });
    print('Total Amount: Rp ${_total}');

    setState(() {
      _isSubmitting = true;
    });

    try {
      print('Sending order request to API...');

      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/orders'),
      );

      // Add headers
      request.headers.addAll({
        'Authorization': 'Bearer ${ApiConfig.token}',
        'Accept': 'application/json',
      });

      // Add fields
      request.fields['customer_id'] = _selectedCustomer!.id;
      request.fields['items'] = jsonEncode(_cartItems
          .map((item) => {
                'product_id': item.productId,
                'quantity': item.quantity,
              })
          .toList());

      // Add image file
      request.files.add(
        await http.MultipartFile.fromPath(
          'photo',
          _selectedImage!.path,
        ),
      );

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('API Response Status: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        print('Order created successfully!');
        // Clear cart after successful order
        await _cartService.clearCart();
        print('Cart cleared successfully');

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

        print('Success notification shown');
        // Navigate to history screen
        if (!mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/history',
          (route) => false,
        );
        print('Navigated to history screen');
      } else {
        final errorData = jsonDecode(response.body);
        print('Order creation failed with status ${response.statusCode}');
        print('Error message: ${errorData['message']}');
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
      print('Exception occurred during order creation: $e');
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
        print('Order creation process completed');
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Informasi Customer',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red),
                            tooltip: 'Hapus Customer',
                            onPressed: () {
                              setState(() {
                                _selectedCustomer = null;
                                _searchController.clear();
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(Icons.check_circle,
                                          color: Colors.white),
                                      SizedBox(width: 8),
                                      Text('Customer berhasil dihapus'),
                                    ],
                                  ),
                                  backgroundColor: Color(0xFF217A3B),
                                  duration: Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(10)),
                                  ),
                                  margin: EdgeInsets.all(8),
                                ),
                              );
                            },
                          ),
                        ],
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
            const SizedBox(height: 24),
            const Text(
              'Foto Pesanan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Ambil Foto'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Pilih dari Galeri'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            if (_selectedImage == null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Foto pesanan wajib diisi',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_selectedImage != null) ...[
              const SizedBox(height: 16),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    _selectedImage!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 200,
                  ),
                ),
              ),
            ],
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
                          _isSubmitting ||
                          _selectedImage == null)
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
