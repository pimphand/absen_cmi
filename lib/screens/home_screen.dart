import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../widgets/common/custom_app_bar.dart';
import '../widgets/common/app_drawer.dart';
import '../config/api_config.dart';
import '../widgets/product/product_detail_bottom_sheet.dart';
import '../widgets/cart_badge.dart';
import 'cart_screen.dart';

class Product {
  final String id;
  final String name;
  final String packaging;
  final String image;
  Product(
      {required this.id,
      required this.name,
      required this.packaging,
      required this.image});
  factory Product.fromJson(Map<String, dynamic> json) {
    print('Creating product from JSON: $json'); // Log the JSON being processed
    final id = json['id']?.toString() ?? '';
    final name = json['name']?.toString() ?? '';
    final packaging = json['packaging']?.toString() ?? '';
    final image = json['image']?.toString() ?? '';
    print(
        'Parsed values - ID: $id, Name: $name, Packaging: $packaging, Image: $image'); // Log parsed values
    return Product(
      id: id,
      name: name,
      packaging: packaging,
      image: image,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Product> products = [];
  bool isLoading = true;
  Offset _cartPosition = const Offset(280, 100);

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<Map<String, dynamic>> fetchProductDetail(String productId) async {
    try {
      final url =
          'https://cikurai.mandalikaputrabersama.com/api/products/$productId';
      print('Fetching product detail from: $url');

      final response = await http.get(Uri.parse(url));
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data.containsKey('data') && data['data'] != null) {
          final Map<String, dynamic> productData =
              Map<String, dynamic>.from(data['data']);

          // Safely convert all fields to strings with null checks
          final Map<String, dynamic> safeProductData = {
            'id': productData['id']?.toString() ?? '',
            'name': productData['name']?.toString() ?? '',
            'packaging': productData['packaging']?.toString() ?? '',
            'description': productData['description']?.toString(),
            'image': productData['image']?.toString() ?? '',
            'brand': productData['brand']?.toString() ?? '',
            'category': productData['category']?.toString() ?? '',
          };

          // Safely handle recommended products
          List<Map<String, dynamic>> safeRecommended = [];
          if (data.containsKey('recomended') && data['recomended'] != null) {
            final List<dynamic> recommendedList = data['recomended'];
            safeRecommended = recommendedList
                .map((item) {
                  if (item is Map<String, dynamic>) {
                    return {
                      'id': item['id']?.toString() ?? '',
                      'name': item['name']?.toString() ?? '',
                      'packaging': item['packaging']?.toString() ?? '',
                      'description': item['description']?.toString(),
                      'image': item['image']?.toString() ?? '',
                      'brand': item['brand']?.toString() ?? '',
                      'category': item['category']?.toString() ?? '',
                    };
                  }
                  return null;
                })
                .whereType<Map<String, dynamic>>()
                .toList();
          }

          return {
            'product': safeProductData,
            'recommended': safeRecommended,
          };
        }
        throw Exception('Data produk tidak ditemukan');
      }
      throw Exception('Gagal memuat detail produk: ${response.statusCode}');
    } catch (e) {
      print('Error in fetchProductDetail: $e');
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  Future<void> fetchProducts() async {
    final response =
        await http.get(Uri.parse(ApiConfig.cikuraiProductsEndpoint));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('API Response: ${response.body}'); // Log full response
      final List<Product> loaded = (data['data'] as List).map((e) {
        print('Processing product: $e'); // Log each product data
        return Product.fromJson(e);
      }).toList();
      print(
          'Loaded Products: ${loaded.map((p) => 'ID: ${p.id}, Name: ${p.name}').join('\n')}'); // Log each product
      setState(() {
        products = loaded.take(8).toList(); // tampilkan 8 produk saja
        isLoading = false;
      });
    } else {
      print('Error fetching products: ${response.statusCode}'); // Log error
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: null,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Top Banner
                Stack(
                  children: [
                    Container(
                      height: 180,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Padding(
                        padding:
                            const EdgeInsets.only(left: 16, top: 32, right: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 8),
                                  Text(
                                    'internet murah',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'tapi gak murahan',
                                    style: TextStyle(
                                      color: Color(0xFFFFEB3B),
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'cikurai',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'internet service provider',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Status bar icons (mock)
                    Positioned(
                      top: 8,
                      right: 16,
                      child: Row(
                        children: const [
                          Icon(Icons.signal_cellular_alt,
                              color: Colors.white, size: 18),
                          SizedBox(width: 4),
                          Icon(Icons.wifi, color: Colors.white, size: 18),
                          SizedBox(width: 4),
                          Icon(Icons.battery_full,
                              color: Colors.white, size: 18),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 8,
                      left: 16,
                      child: const Text('11.12',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
                // Profile Card
                Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  transform: Matrix4.translationValues(0, -32, 0),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF217A3B),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundImage:
                            AssetImage('assets/images/icons8-person-64.png'),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Asep Sanjaya',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const Text(
                              'Sales Marketing',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: const [
                          Text(
                            'Rp187.329.050',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            'Omset Tahun ini',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Menu Grid
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _MenuIcon(
                        icon: Icons.storefront,
                        label: 'Produk',
                        asset: 'assets/images/icons8-product-64.png',
                      ),
                      _MenuIcon(
                        icon: Icons.store,
                        label: 'Costumers',
                        asset: 'assets/images/icons8-customer-100.png',
                      ),
                      _MenuIcon(
                        icon: Icons.receipt_long,
                        label: 'Order (PO)',
                        asset: 'assets/images/icons8-order-100.png',
                      ),
                      _MenuIcon(
                        icon: Icons.bar_chart,
                        label: 'Omset',
                        asset: 'assets/images/icons8-assets-64.png',
                      ),
                    ],
                  ),
                ),
                // Section: Paling Laku Minggu ini
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'Paling Laku Minggu ini!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Lainnya',
                        style: TextStyle(
                          color: Color(0xFF217A3B),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 190,
                  margin: const EdgeInsets.only(top: 8, bottom: 16),
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          key: const PageStorageKey('product-list'),
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          itemCount: products.length,
                          itemBuilder: (context, i) {
                            final p = products[i];
                            return GestureDetector(
                              onTap: () {
                                try {
                                  print('Product tapped: ${p.name}');
                                  print('Product ID: ${p.id}');
                                  print('Product image: ${p.image}');

                                  if (p.id == null || p.id.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('ID Produk tidak valid'),
                                      ),
                                    );
                                    return;
                                  }

                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (context) =>
                                        ProductDetailBottomSheet(
                                            productId: p.id),
                                  );
                                } catch (e) {
                                  print('Error showing product detail: $e');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Terjadi kesalahan: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                              child: _ProductCard(
                                key: ValueKey(p.image),
                                image:
                                    '${ApiConfig.cikuraiStorageUrl}${p.image}',
                                title: p.name,
                                size: 'Ukuran: ${p.packaging}',
                                sold: '',
                                imageHeight: 80,
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          // Draggable Cart Icon
          Positioned(
            left: _cartPosition.dx.clamp(0.0, screenSize.width - 60),
            top: _cartPosition.dy.clamp(0.0, screenSize.height - 60),
            child: Draggable(
              feedback: Material(
                elevation: 4.0,
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF217A3B),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Icon(
                    Icons.shopping_cart,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
              childWhenDragging: Container(),
              onDragEnd: (details) {
                setState(() {
                  _cartPosition = Offset(
                    details.offset.dx.clamp(0.0, screenSize.width - 60),
                    details.offset.dy.clamp(0.0, screenSize.height - 60),
                  );
                });
              },
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF217A3B),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(30),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CartScreen(),
                        ),
                      );
                    },
                    child: Center(
                      child: CartBadge(
                        child: const Icon(Icons.shopping_cart,
                            color: Colors.white, size: 30),
                        badgeColor: Colors.red,
                        textColor: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF217A3B),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Historis',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.block),
            label: 'CS Blacklist',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Akun',
          ),
        ],
      ),
    );
  }
}

class _MenuIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final String asset;
  const _MenuIcon(
      {required this.icon, required this.label, required this.asset});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Image.asset(asset, width: 36, height: 36),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF217A3B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  final String image;
  final String title;
  final String size;
  final String sold;
  final double imageHeight;
  final Key? key;
  const _ProductCard({
    this.key,
    required this.image,
    required this.title,
    required this.size,
    required this.sold,
    this.imageHeight = 90,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: Image.network(
              image,
              height: imageHeight,
              width: 160,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.broken_image),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  size,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sold,
                  style: const TextStyle(
                    color: Color(0xFF217A3B),
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
