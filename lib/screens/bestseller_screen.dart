import 'package:flutter/material.dart';
import '../services/product_service.dart';
import '../models/product.dart';
import 'product_detail_screen.dart';

class BestsellerScreen extends StatefulWidget {
  const BestsellerScreen({super.key});

  @override
  State<BestsellerScreen> createState() => _BestsellerScreenState();
}

class _BestsellerScreenState extends State<BestsellerScreen> {
  final ProductService _productService = ProductService();
  late Future<List<Product>> _future;

  @override
  void initState() {
    super.initState();
    _future = _productService.getAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bestsellers')),
      body: FutureBuilder<List<Product>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          final list = snapshot.data ?? [];
          // Naive bestseller: show first 10 products
          final best = list.take(10).toList();
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.65, crossAxisSpacing: 12, mainAxisSpacing: 12),
            itemCount: best.length,
            itemBuilder: (context, index) {
              final p = best[index];
              return GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p))),
                child: Card(
                  child: Column(
                    children: [
                      Expanded(child: Image.network(p.image, fit: BoxFit.cover, width: double.infinity, errorBuilder: (c,o,s)=>const Icon(Icons.image_not_supported))),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 6),
                          Text('\$${p.price}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ]),
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
