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

  late Future<List<dynamic>> _dataFuture;
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
    _dataFuture = Future.wait([_productsFuture, _categoriesFuture]);

    // Start with 1 tab ("All") – will be updated later when categories load
    _tabController = TabController(length: 1, vsync: this, initialIndex: 0);

    _tabController.addListener(() {
      if (mounted) {
        setState(() {
          _selectedCategoryIndex = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _updateTabs(List<Category> categories) {
    final newLength = categories.length + 1; // +1 for "All" tab

    if (_tabController.length != newLength) {
      final oldIndex = _selectedCategoryIndex;
      _tabController.dispose();
      _tabController = TabController(
        length: newLength,
        vsync: this,
        initialIndex: oldIndex >= newLength ? 0 : oldIndex,
      );
      _tabController.addListener(() {
        if (mounted) {
          setState(() {
            _selectedCategoryIndex = _tabController.index;
          });
        }
      });
    }

    // Update categories in next frame to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _categories = categories;
          if (_selectedCategoryIndex > categories.length) {
            _selectedCategoryIndex = 0;
            _tabController.index = 0;
          }
        });
      }
    });
  }

  List<Product> _getProductsForTab() {
    if (_selectedCategoryIndex == 0) {
      return _allProducts;
    }
    final categoryId = _categories[_selectedCategoryIndex - 1].id;
    return _allProducts.where((p) => p.categoryId == categoryId).toList();
  }

  List<Category> _deriveCategoriesFromProducts(List<Product> products) {
    final ids = products.map((p) => p.categoryId).toSet();
    final derived = ids
        .map((id) => Category(id: id, name: 'Category $id'))
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    return derived;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.shopping_cart, color: Color(0xFFF97316)),
            const SizedBox(width: 8),
            Text(
              'BuyMe',
              style: TextStyle(color: Theme.of(context).primaryColor),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48.0),
          child: FutureBuilder<List<dynamic>>(
            future: _dataFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting ||
                  snapshot.hasError) {
                return const SizedBox.shrink();
              }

              final products = (snapshot.data?[0] as List<dynamic>?)
                      ?.cast<Product>() ??
                  <Product>[];
              final categories = (snapshot.data?[1] as List<dynamic>?)
                      ?.cast<Category>() ??
                  <Category>[];

              final effectiveCategories = categories.isNotEmpty
                  ? categories
                  : _deriveCategoriesFromProducts(products);

              // Update tabs only when category count changes
              if (effectiveCategories.length != _categories.length) {
                _updateTabs(effectiveCategories);
              }

              // Use current _categories for display (updated via _updateTabs)
              final displayCategories =
                  _categories.isNotEmpty ? _categories : effectiveCategories;

              // Hide TabBar until controller length matches
              if (_tabController.length != displayCategories.length + 1) {
                return const SizedBox.shrink();
              }

              return TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: [
                  const Tab(text: 'All'),
                  ...displayCategories.map((cat) => Tab(text: cat.name)),
                ],
              );
            },
          ),
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final productsList = (snapshot.data?[0] as List<dynamic>?)
                  ?.cast<Product>() ??
              <Product>[];
          final categoriesList = (snapshot.data?[1] as List<dynamic>?)
                  ?.cast<Category>() ??
              <Category>[];

          _allProducts = productsList;

          // Ensure categories are set (fallback to derived if empty)
          final effectiveCategories = categoriesList.isNotEmpty
              ? categoriesList
              : _deriveCategoriesFromProducts(productsList);

          // Update tabs if needed (in case body loads before appBar)
          if (effectiveCategories.length != _categories.length) {
            _updateTabs(effectiveCategories);
          }

          final products = _getProductsForTab();

          return GridView.builder(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.52,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ProductDetailScreen(product: product),
                    ),
                  );
                },
                child: Card(
                  elevation: 4,
                  shadowColor: Colors.black12,
                  clipBehavior: Clip.antiAlias,
                  margin: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRect(
                        child: SizedBox(
                          height: 150,
                          width: double.infinity,
                          child: Stack(
                            fit: StackFit.expand,
                            clipBehavior: Clip.hardEdge,
                            children: [
                              Image.network(
                                product.image,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                errorBuilder: (c, o, s) => Container(
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: Icon(
                                      Icons.image_not_supported,
                                      size: 40,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    color: Colors.grey[200],
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress
                                                    .expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                    .cumulativeBytesLoaded /
                                                loadingProgress
                                                    .expectedTotalBytes!
                                            : null,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              Positioned(
                                top: 6,
                                right: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 2),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF97316),
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(10)),
                                  ),
                                  child: const Text(
                                    'New',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  product.name,
                                  style: const TextStyle(
                                      fontSize: 12, fontWeight: FontWeight.bold),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: List.generate(
                                  5,
                                  (index) => const Icon(
                                    Icons.star,
                                    size: 9,
                                    color: Color(0xFFF97316),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '\$${product.price}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              SizedBox(
                                width: double.infinity,
                                height: 28,
                                child: OutlinedButton(
                                  onPressed: () {
                                    Provider.of<CartService>(context,
                                            listen: false)
                                        .addToCart(product);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              '${product.name} added to cart')),
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                        color: Theme.of(context).primaryColor,
                                        width: 1),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(18)),
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: Text(
                                    'Add to Cart',
                                    style: TextStyle(
                                      color: Theme.of(context).primaryColor,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
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
    );
  }
}