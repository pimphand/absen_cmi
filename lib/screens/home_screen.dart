import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';
import '../config/api_config.dart';
import '../widgets/product/product_detail_bottom_sheet.dart';
import '../widgets/cart_badge.dart';
import '../models/banner.dart' as models;
import '../services/banner_service.dart';
import 'cart_screen.dart';
import 'package:logging/logging.dart';
import '../utils/image_utils.dart';
import 'attendance_screen.dart';
import '../services/auth_service.dart';
import '../widgets/custom_bottom_navigation.dart';
import 'history_screen.dart';
import 'blacklist_screen.dart';
import 'profile_screen.dart';

final _logger = Logger('HomeScreen');

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
    final id = json['id']?.toString() ?? '';
    final name = json['name']?.toString() ?? '';
    final packaging = json['packaging']?.toString() ?? '';
    final image = json['image']?.toString() ?? '';
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
  List<models.Banner> banners = [];
  bool isLoading = true;
  bool isLoadingBanners = true;
  Offset _cartPosition = const Offset(280, 100);
  int _currentBannerIndex = 0;
  int _currentIndex = 0;
  Map<String, dynamic>? _userData;
  bool _isSales = false;

  Future<bool> checkInStatus() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/absen-check-in'),
        headers: {
          'Authorization': 'Bearer ${ApiConfig.token}',
          'Accept': 'application/json',
        },
      );

      _logger.info('Check-in status response code: ${response.statusCode}');
      _logger.info('Check-in status response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Check if checked_in is explicitly true
        if (data['checked_in'] == true) {
          _logger.info('User has checked in today');
          return true;
        }

        // If checked_in is false or not set, redirect to attendance
        _logger.info('User has not checked in today');
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AttendanceScreen()),
          );
        }
        return false;
      }

      // If unauthorized (401), redirect to attendance
      if (response.statusCode == 401) {
        _logger.warning('Unauthorized access');
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AttendanceScreen()),
          );
        }
        return false;
      }

      // For other errors, log but don't redirect
      _logger.warning('Error checking in status: ${response.statusCode}');
      return true;
    } catch (e) {
      _logger.severe('Exception in checkInStatus: $e');
      // On exception, don't redirect to prevent loops
      return true;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadToken();
    _loadUserData();
  }

  Future<void> _loadToken() async {
    final token = await AuthService.getToken();
    if (token != null) {
      ApiConfig.token = token;
    }
    _initializeData();
  }

  Future<void> _loadUserData() async {
    final userData = await AuthService.getUserData();
    if (mounted) {
      setState(() {
        _userData = userData;
        // Check if user role is sales
        _isSales =
            _userData?['role']?['name']?.toString().toLowerCase() == 'sales';
      });
    }
  }

  Future<void> _initializeData() async {
    // Check if user is logged in
    if (ApiConfig.token == null || ApiConfig.token!.isEmpty) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AttendanceScreen()),
        );
        return;
      }
    }

    // Check if user has checked in
    final hasCheckedIn = await checkInStatus();
    if (!hasCheckedIn) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AttendanceScreen()),
        );
        return;
      }
    }

    // Only fetch products and banners if user has checked in
    fetchProducts();
    fetchBanners();
  }

  Future<void> fetchBanners() async {
    try {
      final bannerService = BannerService();
      final loadedBanners = await bannerService.getBanners();
      setState(() {
        banners = loadedBanners;
        isLoadingBanners = false;
      });
    } catch (e) {
      _logger.severe('Error loading banners: $e');
      setState(() {
        isLoadingBanners = false;
      });
    }
  }

  Future<Map<String, dynamic>> fetchProductDetail(String productId) async {
    try {
      final url =
          'https://cikurai.mandalikaputrabersama.com/api/products/$productId';
      _logger.info('Fetching product detail from: $url');

      final response = await http.get(Uri.parse(url));
      _logger.info('Response status: ${response.statusCode}');
      _logger.info('Response body: ${response.body}');

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
      _logger.severe('Error in fetchProductDetail: $e');
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  Future<void> fetchProducts() async {
    final response =
        await http.get(Uri.parse(ApiConfig.cikuraiProductsEndpoint));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _logger.info('API Response: ${response.body}'); // Log full response
      final List<Product> loaded = (data['data'] as List).map((e) {
        _logger.info('Processing product: $e'); // Log each product data
        return Product.fromJson(e);
      }).toList();
      _logger.info(
          'Loaded Products: ${loaded.map((p) => 'ID: ${p.id}, Name: ${p.name}').join('\n')}'); // Log each product
      setState(() {
        products = loaded.take(8).toList(); // tampilkan 8 produk saja
        isLoading = false;
      });
    } else {
      _logger.severe(
          'Error fetching products: ${response.statusCode}'); // Log error
      setState(() {
        isLoading = false;
      });
    }
  }

  void _onNavTap(int index) {
    // Remove this method as it's now handled by MainScreen
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
                // Banner Carousel
                Stack(
                  children: [
                    Container(
                      height: 180,
                      width: double.infinity,
                      child: isLoadingBanners
                          ? const Center(child: CircularProgressIndicator())
                          : banners.isEmpty
                              ? Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFF1B5E20),
                                        Color(0xFF388E3C)
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'No banners available',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                )
                              : FlutterCarousel(
                                  items: banners.map((banner) {
                                    return Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        image: DecorationImage(
                                          image: NetworkImage(banner.url),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  options: CarouselOptions(
                                    height: 180,
                                    viewportFraction: 1.0,
                                    autoPlay: true,
                                    autoPlayInterval:
                                        const Duration(seconds: 5),
                                    autoPlayAnimationDuration:
                                        const Duration(milliseconds: 500),
                                    autoPlayCurve: Curves.easeInOut,
                                    onPageChanged: (index, reason) {
                                      setState(() {
                                        _currentBannerIndex = index;
                                      });
                                    },
                                  ),
                                ),
                    ),
                    // Banner Indicators
                    if (!isLoadingBanners && banners.isNotEmpty)
                      Positioned(
                        bottom: 10,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: banners.asMap().entries.map((entry) {
                            return Container(
                              width: 8.0,
                              height: 8.0,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 4.0),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _currentBannerIndex == entry.key
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.5),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    // Status bar icons (mock)
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
                          children: [
                            Text(
                              _userData?['name'] ?? 'Nama Pengguna',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              _userData?['role']?['display_name'] ??
                                  'Role Pengguna',
                              style: const TextStyle(
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
                                            productId: p.id, isSales: _isSales),
                                  );
                                } catch (e) {
                                  _logger.severe(
                                      'Error showing product detail: $e');
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
                                image: p.image,
                                title: p.name,
                                size: 'Ukuran: ${p.packaging}',
                                sold: '',
                                imageHeight: 80,
                                onError: (error) {
                                  print('Error loading image: $error');
                                  // Fallback to original PNG if webp fails
                                  return '${ApiConfig.cikuraiStorageUrl}${p.image}';
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          // Draggable Cart Icon - Only show for sales role
          if (_isSales)
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
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          switch (index) {
            case 0:
              // Already on home screen
              break;
            case 1:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              );
              break;
            case 2:
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const BlacklistScreen()),
              );
              break;
            case 3:
              Navigator.push(
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
  final Function(dynamic)? onError;

  const _ProductCard({
    this.key,
    required this.image,
    required this.title,
    required this.size,
    required this.sold,
    this.imageHeight = 120,
    this.onError,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
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
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: Image.network(
              image,
              height: 100,
              width: 140,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                print('Error loading image: $error');
                if (onError != null) {
                  onError!(error);
                }
                return Container(
                  height: 140,
                  width: 140,
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  size,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                  ),
                ),
                if (sold.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    sold,
                    style: const TextStyle(
                      color: Color(0xFF217A3B),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
