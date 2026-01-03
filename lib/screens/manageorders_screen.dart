import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/order_service.dart';
import '../services/auth_service.dart';
import '../models/order.dart';

class ManageOrdersScreen extends StatefulWidget {
  const ManageOrdersScreen({super.key});

  @override
  State<ManageOrdersScreen> createState() => _ManageOrdersScreenState();
}

class _ManageOrdersScreenState extends State<ManageOrdersScreen> {
  final OrderService _service = OrderService();
  List<OrderItem> _orders = [];
  bool _ordersLoading = false;
  bool _operationInProgress = false;
  bool _approvingOrder = false;
  String _searchTerm = '';
  int _currentPage = 1;
  final int _pageSize = 10;
  
  String? _alertMessage;
  String? _alertType; // 'success', 'error', 'info'
  bool _showAlert = false;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  void _loadOrders() {
    setState(() {
      _ordersLoading = true;
    });
    _service.getAllOrders().then((orders) {
      if (mounted) {
        setState(() {
          _orders = orders;
          _ordersLoading = false;
        });
      }
    }).catchError((error) {
      if (mounted) {
        _displayAlert('Failed to load orders. Please try again.', 'error');
        setState(() {
          _ordersLoading = false;
        });
      }
    });
  }

  void _refreshAll() {
    _loadOrders();
  }

  void _displayAlert(String message, String type) {
    setState(() {
      _alertMessage = message;
      _alertType = type;
      _showAlert = true;
    });
    if (type != 'error') {
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _showAlert = false;
          });
        }
      });
    }
  }

  void _closeAlert() {
    setState(() {
      _showAlert = false;
    });
  }

  List<OrderItem> _filteredOrders() {
    if (_searchTerm.trim().isEmpty) {
      return _orders;
    }
    final term = _searchTerm.toLowerCase();
    return _orders.where((order) {
      return order.id.toString().contains(term) ||
          order.status.toLowerCase().contains(term) ||
          order.paymentStatus.toLowerCase().contains(term) ||
          order.productId.toString().contains(term) ||
          order.userId.toString().contains(term);
    }).toList();
  }

  int get _totalPages {
    final filtered = _filteredOrders();
    return (filtered.length / _pageSize).ceil().clamp(1, double.infinity).toInt();
  }

  List<OrderItem> get _pagedOrders {
    final filtered = _filteredOrders();
    final start = (_currentPage - 1) * _pageSize;
    return filtered.skip(start).take(_pageSize).toList();
  }

  void _changePage(int page) {
    if (page < 1 || page > _totalPages) return;
    setState(() {
      _currentPage = page;
    });
  }

  Future<void> _approveOrder(OrderItem order) async {
    if (order.status == 'APPROVED') return;

    // Only require explicit force when payment FAILED
    final needForce = order.paymentStatus == 'FAILED';
    if (needForce) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Force Approve?'),
          content: Text('Order #${order.id} payment status is "${order.paymentStatus}". Force-approve?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Force Approve')),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    setState(() {
      _approvingOrder = true;
      _operationInProgress = true;
    });

    try {
      final updatedOrder = await _service.approveOrder(order.id, force: needForce);
      if (mounted) {
        // Update the order in the list (like Angular)
        final index = _orders.indexWhere((o) => o.id == order.id);
        if (index != -1) {
          setState(() {
            _orders[index] = updatedOrder;
          });
        }
        _displayAlert('Order approved successfully!', 'success');
      }
    } catch (error) {
      if (mounted) {
        _displayAlert('Failed to approve order. Please try again.', 'error');
      }
    } finally {
      if (mounted) {
        setState(() {
          _approvingOrder = false;
          _operationInProgress = false;
        });
      }
    }
  }

  Future<void> _markDelivered(OrderItem order) async {
    if (order.paymentMethod != 'COD') {
      _displayAlert('Only COD orders can be marked as delivered.', 'error');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark as Delivered?'),
        content: Text('Mark order #${order.id} as delivered?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Mark Delivered')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() {
      _operationInProgress = true;
    });

    try {
      final updatedOrder = await _service.markAsDelivered(order.id);
      if (mounted) {
        // Update local list (like Angular)
        final idx = _orders.indexWhere((o) => o.id == order.id);
        if (idx != -1) {
          setState(() {
            _orders[idx] = updatedOrder;
            // Force local update like Angular
            _orders[idx] = OrderItem(
              id: _orders[idx].id,
              qteOrdered: _orders[idx].qteOrdered,
              orderDate: _orders[idx].orderDate,
              productId: _orders[idx].productId,
              userId: _orders[idx].userId,
              status: 'DELIVERED',
              paymentStatus: 'PAID_COD',
              paymentMethod: _orders[idx].paymentMethod,
              mobile: _orders[idx].mobile,
            );
          });
        }
        _displayAlert('Order marked as delivered!', 'success');
      }
    } catch (err) {
      if (mounted) {
        _displayAlert('Failed to mark order as delivered: ${err.toString()}', 'error');
      }
    } finally {
      if (mounted) {
        setState(() {
          _operationInProgress = false;
        });
      }
    }
  }

  Future<void> _declineOrder(OrderItem order) async {
    if (order.status == 'CANCELLED') return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Decline Order?'),
        content: Text('Decline order #${order.id}? This will cancel the order.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Decline')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() {
      _operationInProgress = true;
    });

    try {
      await _service.declineOrder(order.id);
      if (mounted) {
        // Mark locally (like Angular)
        final idx = _orders.indexWhere((o) => o.id == order.id);
        if (idx != -1) {
          setState(() {
            _orders[idx] = OrderItem(
              id: _orders[idx].id,
              qteOrdered: _orders[idx].qteOrdered,
              orderDate: _orders[idx].orderDate,
              productId: _orders[idx].productId,
              userId: _orders[idx].userId,
              status: 'CANCELLED',
              paymentStatus: _orders[idx].paymentStatus,
              paymentMethod: _orders[idx].paymentMethod,
              mobile: _orders[idx].mobile,
            );
          });
        }
        _displayAlert('Order declined (cancelled).', 'info');
      }
    } catch (error) {
      // Error handled silently like Angular
    } finally {
      if (mounted) {
        setState(() {
          _operationInProgress = false;
        });
      }
    }
  }

  Future<void> _deleteOrder(OrderItem order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Order?'),
        content: Text('Permanently delete order #${order.id}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() {
      _operationInProgress = true;
    });

    try {
      await _service.deleteOrder(order.id);
      if (mounted) {
        setState(() {
          _orders = _orders.where((o) => o.id != order.id).toList();
        });
        _displayAlert('Order deleted.', 'success');
      }
    } catch (error) {
      // Error handled silently like Angular
    } finally {
      if (mounted) {
        setState(() {
          _operationInProgress = false;
        });
      }
    }
  }

  String _getPaymentInfo(OrderItem order) {
    if (order.paymentMethod == 'CARD') {
      return 'Paid by Card';
    }
    if (order.paymentMethod == 'COD') {
      return order.paymentStatus == 'PAID_COD' || order.paymentStatus.contains('PAID')
          ? 'Delivered'
          : 'Pending Delivery';
    }
    return 'Unknown';
  }

  Color _getStatusBadgeColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;
      case 'CONFIRMED':
        return Colors.blue;
      case 'APPROVED':
        return Colors.green;
      case 'SHIPPED':
        return Colors.blue.shade700;
      case 'CANCELLED':
        return Colors.red;
      case 'DELIVERED':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getPaymentStatusBadgeColor(OrderItem order) {
    final info = _getPaymentInfo(order);
    if (info == 'Paid by Card' || info == 'Delivered') {
      return Colors.green;
    }
    if (info == 'Pending Delivery') {
      return Colors.orange;
    }
    return Colors.grey;
  }

  int get _pendingApprovalCount {
    return _orders.where((o) => o.status == 'PENDING' && o.paymentStatus == 'PAID').length;
  }

  int get _approvedCount {
    return _orders.where((o) => o.status == 'APPROVED').length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Orders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshAll,
            tooltip: 'Refresh data',
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Alert Banner
              if (_showAlert)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: _alertType == 'success'
                      ? Colors.green
                      : _alertType == 'error'
                          ? Colors.red
                          : Colors.blue,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _alertMessage ?? '',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: _closeAlert,
                      ),
                    ],
                  ),
                ),

              // Stats Cards
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Card(
                        color: Colors.blue.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Total Orders', style: TextStyle(fontSize: 12)),
                              Text(
                                '${_orders.length}',
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Card(
                        color: Colors.orange.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Pending Approval', style: TextStyle(fontSize: 12)),
                              Text(
                                '$_pendingApprovalCount',
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Card(
                        color: Colors.green.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Approved', style: TextStyle(fontSize: 12)),
                              Text(
                                '$_approvedCount',
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search orders...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchTerm = value;
                      _currentPage = 1; // Reset to first page on search
                    });
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Orders List
              Expanded(
                child: _ordersLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _pagedOrders.isEmpty
                        ? const Center(child: Text('No orders found'))
                        : ListView.builder(
                            itemCount: _pagedOrders.length,
                            itemBuilder: (context, index) {
                              final order = _pagedOrders[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: ExpansionTile(
                                  title: Text('Order #${order.id}'),
                                  subtitle: Text('Product ${order.productId} • Qty: ${order.qteOrdered}'),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              const Text('Status: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: _getStatusBadgeColor(order.status),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  order.status,
                                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              const Text('Payment: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: _getPaymentStatusBadgeColor(order),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  _getPaymentInfo(order),
                                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (order.mobile != null) ...[
                                            const SizedBox(height: 8),
                                            Text('Mobile: ${order.mobile}'),
                                          ],
                                          const SizedBox(height: 8),
                                          Text('Date: ${order.orderDate.split('T')[0]}'),
                                          const SizedBox(height: 16),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: [
                                              if (order.status != 'APPROVED')
                                                ElevatedButton.icon(
                                                  onPressed: _approvingOrder ? null : () => _approveOrder(order),
                                                  icon: const Icon(Icons.check, size: 18),
                                                  label: const Text('Approve'),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.green,
                                                    foregroundColor: Colors.white,
                                                  ),
                                                ),
                                              if (order.status != 'CANCELLED')
                                                ElevatedButton.icon(
                                                  onPressed: _operationInProgress
                                                      ? null
                                                      : () => _declineOrder(order),
                                                  icon: const Icon(Icons.close, size: 18),
                                                  label: const Text('Decline'),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.orange,
                                                    foregroundColor: Colors.white,
                                                  ),
                                                ),
                                              if (order.paymentMethod == 'COD' &&
                                                  order.paymentStatus != 'PAID_COD')
                                                ElevatedButton.icon(
                                                  onPressed: _operationInProgress
                                                      ? null
                                                      : () => _markDelivered(order),
                                                  icon: const Icon(Icons.local_shipping, size: 18),
                                                  label: const Text('Mark Delivered'),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.blue,
                                                    foregroundColor: Colors.white,
                                                  ),
                                                ),
                                              if (order.paymentMethod == 'COD' &&
                                                  order.paymentStatus == 'PAID_COD')
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                  decoration: BoxDecoration(
                                                    color: Colors.green,
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: const Text(
                                                    'Delivered',
                                                    style: TextStyle(color: Colors.white),
                                                  ),
                                                ),
                                              ElevatedButton.icon(
                                                onPressed: _operationInProgress
                                                    ? null
                                                    : () => _deleteOrder(order),
                                                icon: const Icon(Icons.delete, size: 18),
                                                label: const Text('Delete'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.red,
                                                  foregroundColor: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),

              // Pagination
              if (_totalPages > 1)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: _currentPage > 1 ? () => _changePage(_currentPage - 1) : null,
                      ),
                      ...List.generate(
                        _totalPages,
                        (index) {
                          final page = index + 1;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: TextButton(
                              onPressed: () => _changePage(page),
                              style: TextButton.styleFrom(
                                backgroundColor: _currentPage == page
                                    ? Theme.of(context).primaryColor
                                    : null,
                                foregroundColor: _currentPage == page ? Colors.white : null,
                              ),
                              child: Text('$page'),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: _currentPage < _totalPages
                            ? () => _changePage(_currentPage + 1)
                            : null,
                      ),
                    ],
                  ),
                ),
            ],
          ),

          // Operation in progress overlay
          if (_operationInProgress)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
