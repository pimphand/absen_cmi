import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item.dart';

class CartService {
  static const String _cartKey = 'cart_items';
  final SharedPreferences _prefs;

  CartService(this._prefs);

  List<CartItem> getCartItems() {
    final String? cartJson = _prefs.getString(_cartKey);
    if (cartJson == null) return [];

    final List<dynamic> decoded = jsonDecode(cartJson);
    return decoded.map((item) => CartItem.fromJson(item)).toList();
  }

  Future<void> addToCart(CartItem item) async {
    final List<CartItem> items = getCartItems();
    final existingIndex =
        items.indexWhere((i) => i.productId == item.productId);

    if (existingIndex != -1) {
      items[existingIndex].quantity += item.quantity;
    } else {
      items.add(item);
    }

    await _saveCart(items);
  }

  Future<void> updateQuantity(String productId, int quantity) async {
    final List<CartItem> items = getCartItems();
    final index = items.indexWhere((item) => item.productId == productId);

    if (index != -1) {
      if (quantity <= 0) {
        items.removeAt(index);
      } else {
        items[index].quantity = quantity;
      }
      await _saveCart(items);
    }
  }

  Future<void> removeFromCart(String productId) async {
    final List<CartItem> items = getCartItems();
    items.removeWhere((item) => item.productId == productId);
    await _saveCart(items);
  }

  Future<void> clearCart() async {
    await _prefs.remove(_cartKey);
  }

  double getTotal() {
    return getCartItems().fold(
      0,
      (total, item) => total + (item.price * item.quantity),
    );
  }

  Future<void> _saveCart(List<CartItem> items) async {
    final String encoded =
        jsonEncode(items.map((item) => item.toJson()).toList());
    await _prefs.setString(_cartKey, encoded);
  }
}
