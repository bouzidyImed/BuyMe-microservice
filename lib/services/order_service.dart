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

  // Admin: get all orders
  Future<List<OrderItem>> getAllOrders() async {
    final response = await _apiService.get('/orders/all');
    final List<dynamic> data = response as List<dynamic>;
    return data.map((json) => OrderItem.fromJson(json)).toList();
  }

  Future<OrderItem> approveOrder(int id, {bool force = false}) async {
    final q = force ? '?force=true' : '';
    final response = await _apiService.put('/orders/$id/approve$q', {});
    return OrderItem.fromJson(Map<String, dynamic>.from(response as Map));
  }

  Future<OrderItem> markAsDelivered(int id) async {
    final response = await _apiService.put('/orders/$id/delivered', {});
    return OrderItem.fromJson(Map<String, dynamic>.from(response as Map));
  }

  Future<OrderItem> declineOrder(int id) async {
    final response = await _apiService.put('/orders/$id/decline', {});
    return OrderItem.fromJson(Map<String, dynamic>.from(response as Map));
  }

  Future<void> deleteOrder(int id) async {
    await _apiService.delete('/orders/$id/admin');
  }
}
