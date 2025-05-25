import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/cart_service.dart';

class CartBadge extends StatefulWidget {
  final Widget child;
  final Color? badgeColor;
  final Color? textColor;

  const CartBadge({
    Key? key,
    required this.child,
    this.badgeColor,
    this.textColor,
  }) : super(key: key);

  @override
  State<CartBadge> createState() => _CartBadgeState();
}

class _CartBadgeState extends State<CartBadge> {
  Stream<int>? _cartCountStream;
  int _itemCount = 0;

  @override
  void initState() {
    super.initState();
    _initCartStream();
  }

  Future<void> _initCartStream() async {
    final prefs = await SharedPreferences.getInstance();
    final cartService = CartService(prefs);

    // Initial count
    _itemCount = cartService.getCartItems().length;

    // Set up stream
    _cartCountStream = Stream.periodic(const Duration(milliseconds: 500))
        .asyncMap((_) async => cartService.getCartItems().length);

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cartCountStream == null) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          widget.child,
          if (_itemCount > 0)
            Positioned(
              right: -8,
              top: -8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: widget.badgeColor ?? Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  _itemCount.toString(),
                  style: TextStyle(
                    color: widget.textColor ?? Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      );
    }

    return StreamBuilder<int>(
      stream: _cartCountStream,
      builder: (context, snapshot) {
        final itemCount = snapshot.data ?? _itemCount;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            widget.child,
            if (itemCount > 0)
              Positioned(
                right: -8,
                top: -8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: widget.badgeColor ?? Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    itemCount.toString(),
                    style: TextStyle(
                      color: widget.textColor ?? Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
