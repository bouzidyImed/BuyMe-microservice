import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import 'api_service.dart';

class CartItem {
  final int productId;
  final String name;
  final double price;
  int quantity;
  final String? image;

  CartItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    this.image,
  });

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'name': name,
        'price': price,
        'quantity': quantity,
        'image': image,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        productId: json['productId'],
        name: json['name'],
        price: (json['price'] as num).toDouble(),
        quantity: json['quantity'],
        image: json['image'],
      );
}

class CartService extends ChangeNotifier {
  List<CartItem> _items = [];
  List<CartItem> get items => _items;
  final ApiService _apiService = ApiService();

  CartService() {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString('cart_items');
    if (raw != null) {
      final List<dynamic> list = jsonDecode(raw);
      _items = list.map((i) => CartItem.fromJson(i)).toList();
      notifyListeners();
    }
  }

  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final String raw = jsonEncode(_items.map((i) => i.toJson()).toList());
    await prefs.setString('cart_items', raw);
  }

  void addToCart(Product product, {int qty = 1}) {
    final idx = _items.indexWhere((i) => i.productId == product.id);
    if (idx == -1) {
      _items.add(CartItem(
        productId: product.id,
        name: product.name,
        price: product.price,
        quantity: qty,
        image: product.image,
      ));
    } else {
      _items[idx].quantity += qty;
    }
    _saveToStorage();
    notifyListeners();
  }

  void removeFromCart(int productId) {
    _items.removeWhere((i) => i.productId == productId);
    _saveToStorage();
    notifyListeners();
  }

  void clear() {
    _items = [];
    _saveToStorage();
    notifyListeners();
  }

  double get totalAmount => _items.fold(0, (sum, item) => sum + (item.price * item.quantity));

  Future<void> placeOrder(Map<String, dynamic> orderPayload) async {
    try {
      final response = await _apiService.post('/orders/place-order', orderPayload);
      // response is already decoded JSON, if we get here without exception, order was placed successfully
    } catch (e) {
      throw Exception('Failed to place order: $e');
    }
  }

  Future<void> checkout() async {
    if (_items.isEmpty) return;

    List<String> errors = [];
    for (var item in _items) {
      try {
        final payload = {
          'orderDate': DateTime.now().toIso8601String(),
          'productId': item.productId,
          'qteOrdered': item.quantity,
        };
        await placeOrder(payload);
      } catch (e) {
        errors.add('Product ${item.name}: ${e.toString()}');
      }
    }

    if (errors.isEmpty) {
      clear();
    } else {
      throw Exception('Some items could not be ordered:\n${errors.join('\n')}');
    }
  }
}
