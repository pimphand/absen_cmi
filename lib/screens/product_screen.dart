import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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
  List<String> brands = [];
  String? selectedBrand;
  String searchQuery = '';
  bool isLoading = true;
  bool isLoadingMore = false;
  int currentPage = 1;
  int totalPages = 1;
  final int itemsPerPage = 20;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Map<String, dynamic>? _userData;
  bool _isSales = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    fetchProducts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
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

      final queryString = queryParams.entries
          .map((e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final url = '${ApiConfig.cikuraiProductsEndpoint}?$queryString';
      _logger.info('Fetching products from URL: $url');

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> productsData = data['data'] ?? [];
        final meta = data['meta'];

        _logger.info('Loaded ${productsData.length} products');

        // Extract unique brands
        final Set<String> uniqueBrands = productsData
            .map((product) => product['brand']?.toString() ?? '')
            .where((brand) => brand.isNotEmpty)
            .toSet();

        setState(() {
          if (currentPage == 1) {
            products = productsData.cast<Map<String, dynamic>>();
          } else {
            products.addAll(productsData.cast<Map<String, dynamic>>());
          }
          brands = uniqueBrands.toList()..sort();
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
        queryParams['search'] = searchQuery;
      }

      final queryString = queryParams.entries
          .map((e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final url = '${ApiConfig.cikuraiProductsEndpoint}?$queryString';
      _logger.info('Loading more products from URL: $url');

      final response = await http.get(Uri.parse(url));

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
        title: const Text('Products'),
        backgroundColor: const Color(0xFF217A3B),
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
                // Brand Filter Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      hint: const Text('Filter by Brand'),
                      value: selectedBrand,
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('All Brands'),
                        ),
                        ...brands.map((brand) => DropdownMenuItem<String>(
                              value: brand,
                              child: Text(brand),
                            )),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedBrand = value;
                        });
                      },
                    ),
                  ),
                ),
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
                                      product['image'] ?? '',
                                      height: 120,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
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
}
