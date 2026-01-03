import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/cart_service.dart';
import '../services/order_service.dart';
import '../services/payment_service.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _cardExpiryController = TextEditingController();
  final _cardCvvController = TextEditingController();
  
  String _paymentMethod = 'COD'; // 'CARD' or 'COD'
  bool _processing = false;

  @override
  void dispose() {
    _mobileController.dispose();
    _cardNumberController.dispose();
    _cardExpiryController.dispose();
    _cardCvvController.dispose();
    super.dispose();
  }

  Future<void> _placeOrders() async {
    if (_processing) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _processing = true);

    try {
      final cart = Provider.of<CartService>(context, listen: false);
      if (cart.items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your cart is empty.')),
        );
        return;
      }

      final orderService = Provider.of<OrderService>(context, listen: false);
      final paymentService = PaymentService();

      for (final item in cart.items) {
        // Create order
        final orderPayload = {
          'productId': item.productId,
          'qteOrdered': item.quantity,
          'mobile': _mobileController.text.trim(),
          'paymentMethod': _paymentMethod,
        };

        final order = await orderService.createOrder(orderPayload);

        // Process payment based on method (match Angular - don't fail on payment errors)
        if (_paymentMethod == 'CARD') {
          final paymentDto = {
            'orderId': order.id,
            'paymentMethod': _paymentMethod,
            'amount': item.price * item.quantity,
          };
          final cardDto = {
            'cardNumber': _cardNumberController.text.trim(),
            'cvv': _cardCvvController.text.trim(),
            'expiry': _cardExpiryController.text.trim(),
          };
          // Payment errors are caught in service and return null - don't throw
          await paymentService.createPaymentWithCard(paymentDto, cardDto);
        } else {
          // COD payment
          final codPayload = {
            'orderId': order.id,
            'paymentMethod': _paymentMethod,
            'amount': item.price * item.quantity,
          };
          // Payment errors are caught in service and return null - don't throw
          await paymentService.createPayment(codPayload);
        }
      }

      // Clear cart
      cart.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _paymentMethod == 'CARD'
                  ? 'Order placed and paid successfully — thank you!'
                  : 'Order placed successfully. Pay on delivery when you receive the items.',
            ),
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Checkout failed: ${err.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _processing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartService>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: cart.items.isEmpty
          ? const Center(child: Text('Your cart is empty'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Billing Details Section
                    const Text(
                      'Billing Details',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _mobileController,
                      decoration: const InputDecoration(
                        labelText: 'Mobile *',
                        hintText: 'e.g. +216 97749786',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Mobile number is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Order Summary Section
                    const Text(
                      'Order Summary',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Column(
                        children: [
                          ...cart.items.map((item) {
                            return ListTile(
                              title: Text('Product #${item.productId}'),
                              subtitle: Text('${item.quantity} x \$${item.price}'),
                              trailing: Text(
                                '\$${(item.price * item.quantity).toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            );
                          }),
                          const Divider(),
                          ListTile(
                            title: const Text('Subtotal', style: TextStyle(fontWeight: FontWeight.bold)),
                            trailing: Text(
                              '\$${cart.totalAmount.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          ListTile(
                            title: const Text('Shipping'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Checkbox(value: true, onChanged: null),
                                const Text('Free Shipping'),
                              ],
                            ),
                          ),
                          const Divider(),
                          ListTile(
                            title: const Text('TOTAL', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            trailing: Text(
                              '\$${cart.totalAmount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Payment Method Section
                    const Text(
                      'Payment Method',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => setState(() => _paymentMethod = 'CARD'),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: _paymentMethod == 'CARD'
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey,
                                width: _paymentMethod == 'CARD' ? 2 : 1,
                              ),
                              backgroundColor: _paymentMethod == 'CARD'
                                  ? Theme.of(context).primaryColor.withOpacity(0.1)
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.credit_card),
                                const SizedBox(width: 8),
                                const Text('Pay with Card'),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => setState(() => _paymentMethod = 'COD'),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: _paymentMethod == 'COD'
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey,
                                width: _paymentMethod == 'COD' ? 2 : 1,
                              ),
                              backgroundColor: _paymentMethod == 'COD'
                                  ? Theme.of(context).primaryColor.withOpacity(0.1)
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.local_shipping),
                                const SizedBox(width: 8),
                                const Text('Cash on Delivery'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Card Details Section (only shown when CARD is selected)
                    if (_paymentMethod == 'CARD') ...[
                      const SizedBox(height: 24),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Card Details (Test Cards Available)',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _cardNumberController,
                                decoration: const InputDecoration(
                                  labelText: 'Card Number *',
                                  hintText: 'e.g. 4111111111111111',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (_paymentMethod == 'CARD' && (value == null || value.trim().isEmpty)) {
                                    return 'Card number is required';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _cardExpiryController,
                                      decoration: const InputDecoration(
                                        labelText: 'MM/YY *',
                                        hintText: '12/26',
                                        border: OutlineInputBorder(),
                                      ),
                                      validator: (value) {
                                        if (_paymentMethod == 'CARD' && (value == null || value.trim().isEmpty)) {
                                          return 'Required';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _cardCvvController,
                                      decoration: const InputDecoration(
                                        labelText: 'CVV *',
                                        hintText: '123',
                                        border: OutlineInputBorder(),
                                      ),
                                      keyboardType: TextInputType.number,
                                      validator: (value) {
                                        if (_paymentMethod == 'CARD' && (value == null || value.trim().isEmpty)) {
                                          return 'Required';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Use test card: 4111111111111111 | CVV: 123 | Expiry: 12/26',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),
                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _processing ? null : _placeOrders,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                        ),
                        child: _processing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Complete Secure Checkout',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
