import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../services/product_service.dart';
import '../services/category_service.dart';
import '../services/cart_service.dart';
import 'product_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final ProductService _productService = ProductService();
  final CategoryService _categoryService = CategoryService();
  late Future<List<Product>> _productsFuture;
  late Future<List<Category>> _categoriesFuture;
  late TabController _tabController;
  List<Category> _categories = [];
  List<Product> _allProducts = [];
  int _selectedCategoryIndex = 0;

  @override
  void initState() {
    super.initState();
    _productsFuture = _productService.getAll();
    _categoriesFuture = _categoryService.getAll();
    _tabController = TabController(length: 1, vsync: this); // Start with 1 tab for "All"
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _updateTabs(List<Category> categories) {
    setState(() {
      _categories = categories;
      _tabController = TabController(length: categories.length + 1, vsync: this);
      _tabController.addListener(() {
        setState(() {
          _selectedCategoryIndex = _tabController.index;
        });
      });
    });
  }

  List<Product> _getProductsForTab() {
    if (_selectedCategoryIndex == 0) {
      return _allProducts;
    }
    final categoryId = _categories[_selectedCategoryIndex - 1].id;
    return _allProducts.where((p) => p.categoryId == categoryId).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.shopping_bag, color: Color(0xFFF97316)),
            const SizedBox(width: 8),
            Text('BuyMe', style: TextStyle(color: Theme.of(context).primaryColor)),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48.0),
          child: FutureBuilder<List<Category>>(
            future: _categoriesFuture,
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                _updateTabs(snapshot.data!);
                return TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabs: [
                    const Tab(text: 'All'),
                    ..._categories.map((cat) => Tab(text: cat.name)),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search Looking For?',
                suffixIcon: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Icon(Icons.search, color: Colors.white),
                ),
              ),
            ),
          ),
          // Product Grid
          Expanded(
            child: FutureBuilder<List<Product>>(
              future: _productsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No products found'));
                }

                _allProducts = snapshot.data!;
                final products = _getProductsForTab();

                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductDetailScreen(product: product),
                          ),
                        );
                      },
                      child: Card(
                        elevation: 4,
                        shadowColor: Colors.black12,
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Stack(
                                children: [
                                  Image.network(
                                    product.image,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    errorBuilder: (c, o, s) => const Center(child: Icon(Icons.image_not_supported, size: 50)),
                                  ),
                                  Positioned(
                                    top: 10,
                                    right: 10,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFF97316), // Primary
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Text('New', style: TextStyle(color: Colors.white, fontSize: 10)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: List.generate(5, (index) => const Icon(Icons.star, size: 14, color: Color(0xFFF97316))),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '\$${product.price}',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          color: Theme.of(context).primaryColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton(
                                      onPressed: () {
                                        Provider.of<CartService>(context, listen: false).addToCart(product);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('${product.name} added to cart')),
                                        );
                                      },
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(color: Theme.of(context).primaryColor),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                        padding: EdgeInsets.zero,
                                      ),
                                      child: Text('Add to Cart', style: TextStyle(color: Theme.of(context).primaryColor)),
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
