import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/order.dart';
import 'api_service.dart';

class OrderService extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  Future<List<OrderItem>> getMyOrders() async {
    try {
      final response = await _apiService.get('/orders/my-orders');
      // response is already decoded JSON (List<dynamic>)
      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => OrderItem.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching orders: $e');
      rethrow;
    }
  }
}
