import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../config/api_config.dart';
import '../widgets/product/product_detail_bottom_sheet.dart';
import 'package:logging/logging.dart';
import '../services/auth_service.dart';
import 'dart:async';

final _logger = Logger('ProductScreen');

class ProductScreen extends StatefulWidget {
  const ProductScreen({Key? key}) : super(key: key);

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> brands = [];
  String? selectedBrand;
  String searchQuery = '';
  bool isLoading = true;
  bool isLoadingMore = false;
  bool isLoadingBrands = true;
  int currentPage = 1;
  int totalPages = 1;
  final int itemsPerPage = 20;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Map<String, dynamic>? _userData;
  bool _isSales = false;
  Timer? _debounce;
  late HttpClient _httpClient;

  @override
  void initState() {
    super.initState();
    _setupHttpClient();
    _loadUserData();
    fetchBrands();
    fetchProducts();
    _scrollController.addListener(_onScroll);
  }

  void _setupHttpClient() {
    _httpClient = HttpClient()
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    _httpClient.close();
    super.dispose();
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

  Future<http.Response> _makeRequest(String url) async {
    final request = await _httpClient.getUrl(Uri.parse(url));
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    return http.Response(responseBody, response.statusCode);
  }

  Future<void> fetchBrands() async {
    try {
      setState(() => isLoadingBrands = true);
      final response =
          await _makeRequest('https://absensi.dmpt.my.id/api/brands');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          brands = List<Map<String, dynamic>>.from(data['data']);
          isLoadingBrands = false;
        });
      } else {
        throw Exception('Failed to load brands');
      }
    } catch (e) {
      _logger.severe('Error fetching brands: $e');
      setState(() => isLoadingBrands = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading brands: ${e.toString()}')),
        );
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (!isLoadingMore && currentPage < totalPages) {
        loadMoreProducts();
      }
    }
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        searchQuery = value;
        currentPage = 1;
        products = [];
      });
      fetchProducts();
    });
  }

  Future<void> fetchProducts() async {
    try {
      setState(() => isLoading = true);

      final queryParams = <String, String>{
        'page': currentPage.toString(),
        'limit': itemsPerPage.toString(),
      };

      if (searchQuery.isNotEmpty) {
        queryParams['name'] = searchQuery;
      }

      if (selectedBrand != null) {
        queryParams['brand'] = selectedBrand!;
      }

      final queryString = queryParams.entries
          .map((e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final url = '${ApiConfig.cikuraiProductsEndpoint}?$queryString';
      _logger.info('Fetching products from URL: $url');

      final response = await _makeRequest(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> productsData = data['data'] ?? [];
        final meta = data['meta'];

        _logger.info('Loaded ${productsData.length} products');

        setState(() {
          if (currentPage == 1) {
            products = productsData.cast<Map<String, dynamic>>();
          } else {
            products.addAll(productsData.cast<Map<String, dynamic>>());
          }
          currentPage = meta['current_page'] ?? 1;
          totalPages = meta['last_page'] ?? 1;
          _logger.info('Total pages: $totalPages, Current page: $currentPage');
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load products');
      }
    } catch (e) {
      _logger.severe('Error fetching products: $e');
      setState(() {
        isLoading = false;
        totalPages = 1;
        currentPage = 1;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> loadMoreProducts() async {
    if (isLoadingMore) return;

    setState(() {
      isLoadingMore = true;
    });

    try {
      final nextPage = currentPage + 1;
      final queryParams = <String, String>{
        'page': nextPage.toString(),
        'limit': itemsPerPage.toString(),
      };

      if (searchQuery.isNotEmpty) {
        queryParams['name'] = searchQuery;
      }

      if (selectedBrand != null) {
        queryParams['brand'] = selectedBrand!;
      }

      final queryString = queryParams.entries
          .map((e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final url = '${ApiConfig.cikuraiProductsEndpoint}?$queryString';
      _logger.info('Loading more products from URL: $url');

      final response = await _makeRequest(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> newProducts = data['data'] ?? [];
        final meta = data['meta'];

        _logger.info(
            'Loaded ${newProducts.length} more products. Current page: $nextPage');

        setState(() {
          products.addAll(newProducts.cast<Map<String, dynamic>>());
          currentPage = meta['current_page'] ?? nextPage;
          totalPages = meta['last_page'] ?? 1;
          isLoadingMore = false;
        });
      } else {
        throw Exception('Failed to load more products');
      }
    } catch (e) {
      _logger.severe('Error loading more products: $e');
      setState(() {
        isLoadingMore = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error loading more products: ${e.toString()}')),
        );
      }
    }
  }

  List<Map<String, dynamic>> get filteredProducts {
    return products.where((product) {
      final name = product['name']?.toString().toLowerCase() ?? '';
      final brand = product['brand']?.toString() ?? '';
      final matchesSearch = name.contains(searchQuery.toLowerCase());
      final matchesBrand = selectedBrand == null || brand == selectedBrand;
      return matchesSearch && matchesBrand;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.white,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Products',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              'Daftar produk yang tersedia',
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
            onPressed: () {
              setState(() {
                selectedBrand = null;
                searchQuery = '';
                _searchController.clear();
                currentPage = 1;
              });
              fetchProducts();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  onChanged: _onSearchChanged,
                ),
                const SizedBox(height: 16),
                // Brand Carousel
                _buildBrandCarousel(),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredProducts.isEmpty
                    ? const Center(child: Text('No products found'))
                    : GridView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount:
                            filteredProducts.length + (isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == filteredProducts.length) {
                            return Container(
                              height: 100,
                              alignment: Alignment.center,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const CircularProgressIndicator(),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Loading more products...',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          final product = filteredProducts[index];
                          return GestureDetector(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) => ProductDetailBottomSheet(
                                  productId: product['id'].toString(),
                                  isSales: _isSales,
                                ),
                              );
                            },
                            child: Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(12),
                                    ),
                                    child: Image.network(
                                      '${product['image']}',
                                      height: 120,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                        if (loadingProgress == null)
                                          return child;
                                        return Center(
                                          child: CircularProgressIndicator(
                                            value: loadingProgress
                                                        .expectedTotalBytes !=
                                                    null
                                                ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    loadingProgress
                                                        .expectedTotalBytes!
                                                : null,
                                          ),
                                        );
                                      },
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        _logger.severe(
                                            'Error loading product image: $error');
                                        return Container(
                                          height: 120,
                                          color: Colors.grey[200],
                                          child: const Icon(Icons.broken_image),
                                        );
                                      },
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product['name'] ?? '',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          product['brand'] ?? '',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Packaging: ${product['packaging'] ?? ''}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandCarousel() {
    return SizedBox(
      height: 80,
      child: isLoadingBrands
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: brands.length + 1, // +1 for "All Brands"
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedBrand = null;
                          currentPage = 1;
                          products = [];
                        });
                        fetchProducts();
                      },
                      child: Container(
                        width: 80,
                        decoration: BoxDecoration(
                          color: selectedBrand == null
                              ? const Color(0xFF217A3B)
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.category,
                              color: selectedBrand == null
                                  ? Colors.white
                                  : Colors.grey[600],
                              size: 24,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'All',
                              style: TextStyle(
                                color: selectedBrand == null
                                    ? Colors.white
                                    : Colors.grey[600],
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                final brand = brands[index - 1];
                final isSelected = selectedBrand == brand['name'].toString();

                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedBrand = brand['name'].toString();
                        currentPage = 1;
                        products = [];
                      });
                      fetchProducts();
                    },
                    child: Container(
                      width: 80,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF217A3B)
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (brand['logo'] != null)
                            Image.network(
                              '${ApiConfig.cikuraiStorageUrl}${brand['logo']}',
                              height: 40,
                              width: 40,
                              fit: BoxFit.contain,
                              headers: const {
                                'Accept': '*/*',
                              },
                              errorBuilder: (context, error, stackTrace) {
                                _logger
                                    .severe('Error loading brand logo: $error');
                                return Icon(
                                  Icons.business,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey[600],
                                  size: 24,
                                );
                              },
                            )
                          else
                            Icon(
                              Icons.business,
                              color:
                                  isSelected ? Colors.white : Colors.grey[600],
                              size: 24,
                            ),
                          const SizedBox(height: 4),
                          Text(
                            brand['name'].toString(),
                            style: TextStyle(
                              color:
                                  isSelected ? Colors.white : Colors.grey[600],
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
