import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../screens/cart_screen.dart';
import '../../models/cart_item.dart';
import '../../services/cart_service.dart';
import '../../config/api_config.dart';

class ProductDetailBottomSheet extends StatelessWidget {
  final String productId;
  final bool isSales;

  const ProductDetailBottomSheet({
    Key? key,
    required this.productId,
    required this.isSales,
  }) : super(key: key);

  Future<Map<String, dynamic>> fetchProductDetail(String productId) async {
    try {
      final url = ApiConfig.cikuraiProductDetailEndpoint(productId);
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
            'price': productData['price']?.toDouble() ?? 0.0,
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
                      'price': item['price']?.toDouble() ?? 0.0,
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

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: FutureBuilder<Map<String, dynamic>>(
          future: fetchProductDetail(productId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return ProductDetailError(
                error: snapshot.error.toString(),
                onClose: () => Navigator.pop(context),
              );
            }

            if (!snapshot.hasData) {
              return const Center(child: Text('Data produk tidak ditemukan'));
            }

            final Map<String, dynamic> product =
                Map<String, dynamic>.from(snapshot.data!['product']);
            final List<Map<String, dynamic>> recommended =
                List<Map<String, dynamic>>.from(snapshot.data!['recommended']);

            return ProductDetailContent(
              product: product,
              recommended: recommended,
              scrollController: scrollController,
              isSales: isSales,
            );
          },
        ),
      ),
    );
  }
}

class ProductDetailError extends StatelessWidget {
  final String error;
  final VoidCallback onClose;

  const ProductDetailError({
    Key? key,
    required this.error,
    required this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text('Error: $error'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onClose,
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
}

class ProductDetailContent extends StatelessWidget {
  final Map<String, dynamic> product;
  final List<Map<String, dynamic>> recommended;
  final ScrollController scrollController;
  final bool isSales;

  const ProductDetailContent({
    Key? key,
    required this.product,
    required this.recommended,
    required this.scrollController,
    required this.isSales,
  }) : super(key: key);

  Future<void> _addToCart(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartService = CartService(prefs);

      // Create cart item with proper data
      final cartItem = CartItem(
        productId: product['id'].toString(),
        name: product['name'].toString(),
        brand: product['brand'].toString(),
        imageUrl: '${ApiConfig.cikuraiStorageUrl}${product['image']}',
        price: product['price']?.toDouble() ?? 0.0,
        quantity: 1,
      );

      // Add to cart
      await cartService.addToCart(cartItem);

      if (context.mounted) {
        // Close bottom sheet first
        Navigator.pop(context);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                const Text('Produk berhasil ditambahkan ke keranjang'),
              ],
            ),
            backgroundColor: const Color(0xFF217A3B),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(8),
          ),
        );
      }
    } catch (e) {
      print('Error adding to cart: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Gagal menambahkan ke keranjang: $e'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(8),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ProductDetailHeader(),
          ProductDetailInfo(product: product),
          if (product['image'] != null &&
              product['image'].toString().isNotEmpty)
            ProductDetailImage(image: product['image'].toString()),
          const SizedBox(height: 16),
          if (isSales)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _addToCart(context),
                icon: const Icon(Icons.shopping_cart),
                label: const Text('Tambah ke Keranjang'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF217A3B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          if (recommended.isNotEmpty)
            RecommendedProductsList(recommended: recommended, isSales: isSales),
        ],
      ),
    );
  }
}

class ProductDetailHeader extends StatelessWidget {
  const ProductDetailHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(top: 8, bottom: 16),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class ProductDetailImage extends StatelessWidget {
  final String image;

  const ProductDetailImage({
    Key? key,
    required this.image,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.network(
        '${ApiConfig.cikuraiStorageUrl}$image',
        height: 120,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const Icon(
          Icons.broken_image,
          size: 120,
          color: Colors.grey,
        ),
      ),
    );
  }
}

class ProductDetailInfo extends StatelessWidget {
  final Map<String, dynamic> product;

  const ProductDetailInfo({
    Key? key,
    required this.product,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product['name']?.toString() ?? 'Nama tidak tersedia',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text('Brand: ${product['brand']?.toString() ?? '-'}'),
        Text('Kategori: ${product['category']?.toString() ?? '-'}'),
        Text('Kemasan: ${product['packaging']?.toString() ?? '-'}'),
        const SizedBox(height: 12),
        if (product['description'] != null &&
            product['description'].toString().isNotEmpty)
          Text(product['description'].toString()),
      ],
    );
  }
}

class RecommendedProductsList extends StatelessWidget {
  final List<Map<String, dynamic>> recommended;
  final bool isSales;

  const RecommendedProductsList({
    Key? key,
    required this.recommended,
    required this.isSales,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text(
          'Produk Rekomendasi:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: recommended.length,
            itemBuilder: (context, i) {
              final r = recommended[i];
              return RecommendedProductCard(
                product: r,
                isSales: isSales,
              );
            },
          ),
        ),
      ],
    );
  }
}

class RecommendedProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final bool isSales;

  const RecommendedProductCard({
    Key? key,
    required this.product,
    required this.isSales,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context); // Close current bottom sheet
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => ProductDetailBottomSheet(
            productId: product['id'].toString(),
            isSales: isSales,
          ),
        );
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product['name']?.toString() ?? '',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Brand: ${product['brand']?.toString() ?? '-'}',
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 6),
            if (product['image'] != null &&
                product['image'].toString().isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  '${ApiConfig.cikuraiStorageUrl}${product['image']}',
                  height: 70,
                  width: 140,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.broken_image),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
