import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item.dart';
import '../services/cart_service.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late CartService _cartService;
  List<CartItem> _cartItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
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
      _isLoading = false;
    });
  }

  Future<void> _clearCart() async {
    await _cartService.clearCart();
    _loadCartItems();
  }

  Future<void> _updateQuantity(String productId, int quantity) async {
    await _cartService.updateQuantity(productId, quantity);
    _loadCartItems();
  }

  Future<void> _removeItem(String productId) async {
    await _cartService.removeFromCart(productId);
    _loadCartItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Keranjang'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _cartItems.isEmpty ? null : _clearCart,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cartItems.isEmpty
              ? const Center(child: Text('Keranjang kosong'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _cartItems.length,
                  itemBuilder: (context, index) {
                    final item = _cartItems[index];
                    return CartItemCard(
                      item: item,
                      onQuantityChanged: (quantity) =>
                          _updateQuantity(item.productId, quantity),
                      onRemove: () => _removeItem(item.productId),
                    );
                  },
                ),
      bottomNavigationBar: _cartItems.isEmpty
          ? null
          : Container(
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
                          'Total:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Rp ${_cartService.getTotal().toStringAsFixed(0)}',
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
                        onPressed: () {
                          final cartItems = _cartService.getCartItems();
                          final checkoutData = {
                            'customer_id': 'customer_id',
                            'items': cartItems
                                .map((item) => {
                                      'product_id': item.productId,
                                      'quantity': item.quantity,
                                    })
                                .toList(),
                          };
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CheckoutScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Checkout'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class CartItemCard extends StatelessWidget {
  final CartItem item;
  final Function(int) onQuantityChanged;
  final VoidCallback onRemove;

  const CartItemCard({
    Key? key,
    required this.item,
    required this.onQuantityChanged,
    required this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item.imageUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.broken_image, size: 80),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.brand,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Rp ${item.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () =>
                                onQuantityChanged(item.quantity - 1),
                          ),
                          Text('${item.quantity}'),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () =>
                                onQuantityChanged(item.quantity + 1),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: onRemove,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
