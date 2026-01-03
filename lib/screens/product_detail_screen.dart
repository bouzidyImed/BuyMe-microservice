import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../services/cart_service.dart';
import '../services/review_service.dart';
import '../services/auth_service.dart';
import '../services/product_service.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  final ReviewService _reviewService = ReviewService();
  final ProductService _productService = ProductService();
  List<Map<String, dynamic>> _reviews = [];
  int _selectedRating = 0;
  bool _isAuthenticated = false;
  bool _loadingReviews = false;
  bool _submittingReview = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
    _loadReviews();
  }

  void _checkAuthStatus() {
    final authService = Provider.of<AuthService>(context, listen: false);
    setState(() {
      _isAuthenticated = authService.isAuthenticated;
    });
  }

  void _loadReviews() {
    setState(() {
      _loadingReviews = true;
    });
    _reviewService.getByProduct(widget.product.id).then((reviews) {
      if (mounted) {
        setState(() {
          _reviews = reviews;
          _loadingReviews = false;
        });
      }
    }).catchError((error) {
      if (mounted) {
        setState(() {
          _loadingReviews = false;
        });
      }
    });
  }

  void _setRating(int rating) {
    setState(() {
      _selectedRating = rating;
    });
  }

  Future<void> _submitReview() async {
    if (!_isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to submit a rating.')),
      );
      return;
    }

    if (_selectedRating < 1 || _selectedRating > 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating between 1 and 5 stars.')),
      );
      return;
    }

    setState(() {
      _submittingReview = true;
    });

    try {
      await _reviewService.addReview(widget.product.id, {'rating': _selectedRating});
      if (mounted) {
        setState(() {
          _selectedRating = 0;
        });
        _loadReviews();
        // Refresh product to get updated rating
        _productService.getById(widget.product.id).then((product) {
          if (mounted && product != null) {
            // Product updated, but we can't update widget.product directly
            // The rating will be reflected in reviews
          }
        });
        _showSuccessDialog();
      }
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to submit review: ${err.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _submittingReview = false;
        });
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thank you'),
        content: const Text('Your rating has been submitted successfully.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.product.name)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              widget.product.image,
              width: double.infinity,
              height: 300,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 300,
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                );
              },
              errorBuilder: (c, o, s) => Container(
                height: 300,
                color: Colors.grey[200],
                child: const Center(child: Icon(Icons.image_not_supported, size: 100)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.name,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${widget.product.price}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.product.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () {
                                if (_quantity > 1) setState(() => _quantity--);
                              },
                            ),
                            Text(
                              '$_quantity',
                              style: const TextStyle(fontSize: 18),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                final max = widget.product.quantity ?? double.infinity;
                                if (_quantity < max) {
                                  setState(() => _quantity++);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Cannot add more: requested quantity exceeds available stock.'),
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            final available = widget.product.quantity ?? double.infinity;
                            if (_quantity > available) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Cannot add to cart: requested quantity exceeds available stock.'),
                                ),
                              );
                              return;
                            }
                            Provider.of<CartService>(context, listen: false)
                                .addToCart(widget.product, qty: _quantity);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${widget.product.name} added to cart')),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Add to Cart'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Rating Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Rate this product',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        if (_isAuthenticated) ...[
                          Row(
                            children: List.generate(5, (index) {
                              final rating = index + 1;
                              return GestureDetector(
                                onTap: () => _setRating(rating),
                                child: Icon(
                                  Icons.star,
                                  size: 30,
                                  color: _selectedRating >= rating
                                      ? Theme.of(context).primaryColor
                                      : Colors.grey,
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _submittingReview ? null : _submitReview,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                            ),
                            child: _submittingReview
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('Submit Rating'),
                          ),
                        ] else
                          const Text(
                            'Log in to rate this product.',
                            style: TextStyle(color: Colors.grey),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Reviews Section
                  const Text(
                    'Reviews',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _loadingReviews
                      ? const Center(child: CircularProgressIndicator())
                      : _reviews.isEmpty
                          ? const Text('No reviews yet.')
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _reviews.length,
                              itemBuilder: (context, index) {
                                final review = _reviews[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const CircleAvatar(
                                          child: Icon(Icons.person),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    review['user']?['firstName'] != null
                                                        ? '${review['user']['firstName']} ${review['user']['lastName'] ?? ''}'
                                                        : 'Anonymous',
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  ...List.generate(5, (i) {
                                                    return Icon(
                                                      Icons.star,
                                                      size: 16,
                                                      color: (review['rating'] as int? ?? 0) > i
                                                          ? Colors.amber
                                                          : Colors.grey,
                                                    );
                                                  }),
                                                ],
                                              ),
                                              if (review['comment'] != null &&
                                                  (review['comment'] as String).isNotEmpty)
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 4),
                                                  child: Text(review['comment'] as String),
                                                ),
                                              if (review['createdAt'] != null)
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 4),
                                                  child: Text(
                                                    review['createdAt'] as String,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
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
