import 'package:flutter/material.dart';
import '../services/order_service.dart';
import '../services/order_service.dart' as s;
import '../models/order.dart';

class ManageOrdersScreen extends StatefulWidget {
  const ManageOrdersScreen({super.key});

  @override
  State<ManageOrdersScreen> createState() => _ManageOrdersScreenState();
}

class _ManageOrdersScreenState extends State<ManageOrdersScreen> {
  final OrderService _service = OrderService();
  late Future<List<OrderItem>> _future;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() { _future = _service.getAllOrders(); });
  }

  Future<void> _approve(int id) async {
    try {
      await _service.approveOrder(id);
      _refresh();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order approved')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Approve failed: $e')));
    }
  }

  Future<void> _delete(int id) async {
    try {
      await _service.deleteOrder(id);
      _refresh();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order deleted')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Orders'), actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh)]),
      body: FutureBuilder<List<OrderItem>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          final list = snapshot.data ?? [];
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (ctx, i) {
              final o = list[i];
              return ListTile(
                title: Text('Order #${o.id} • Product ${o.productId}'),
                subtitle: Text('Qty: ${o.qteOrdered} • Status: ${o.status} • Payment: ${o.paymentStatus}'),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(icon: const Icon(Icons.check), onPressed: () => _approve(o.id)),
                  IconButton(icon: const Icon(Icons.delete), onPressed: () => _delete(o.id)),
                ]),
              );
            },
          );
        },
      ),
    );
  }
}
