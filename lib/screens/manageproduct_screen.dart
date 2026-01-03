import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import '../services/product_service.dart';
import '../services/category_service.dart';
import '../models/product.dart';
import '../models/category.dart';

class ManageProductScreen extends StatefulWidget {
  const ManageProductScreen({super.key});

  @override
  State<ManageProductScreen> createState() => _ManageProductScreenState();
}

class _ManageProductScreenState extends State<ManageProductScreen> {
  final ProductService _service = ProductService();
  final CategoryService _categoryService = CategoryService();
  late Future<List<Product>> _future;
  late Future<List<Category>> _categoriesFuture;
  List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
    _refresh();
    _loadCategories();
  }

  void _refresh() {
    setState(() {
      _future = _service.getAll();
    });
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _categoryService.getAll();
      setState(() => _categories = categories);
    } catch (e) {
      // Handle error silently or show snackbar
    }
  }

  Future<void> _delete(int id) async {
    try {
      await _service.delete(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted')));
        // Auto-refresh after a short delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _refresh();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
    }
  }

  void _showEditDialog([Product? p]) {
    final nameCtrl = TextEditingController(text: p?.name ?? '');
    final descCtrl = TextEditingController(text: p?.description ?? '');
    final priceCtrl = TextEditingController(text: p?.price.toString() ?? '0');
    final qtyCtrl = TextEditingController(text: p?.quantity.toString() ?? '0');
    int? selectedCategoryId = p?.categoryId;
    List<PlatformFile> pickedFiles = [];
    List<Uint8List> imagePreviews = [];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, dialogSetState) => AlertDialog(
          title: Text(p == null ? 'Create Product' : 'Edit Product'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name *'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Description *'),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceCtrl,
                  decoration: const InputDecoration(labelText: 'Price *'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: qtyCtrl,
                  decoration: const InputDecoration(labelText: 'Quantity *'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                // Category Dropdown
                DropdownButtonFormField<int?>(
                  value: selectedCategoryId,
                  decoration: const InputDecoration(labelText: 'Category *'),
                  items: _categories.map((cat) {
                    return DropdownMenuItem<int?>(
                      value: cat.id,
                      child: Text(cat.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    dialogSetState(() {
                      selectedCategoryId = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                // Image picker - only for new products
                if (p == null) ...[
                  ElevatedButton.icon(
                    onPressed: () async {
                      final res = await FilePicker.platform.pickFiles(
                        type: FileType.image,
                        allowMultiple: true,
                        withData: true,
                      );
                      if (res != null && res.files.isNotEmpty) {
                        dialogSetState(() {
                          pickedFiles = res.files;
                          imagePreviews = pickedFiles
                              .where((f) => f.bytes != null)
                              .map((f) => f.bytes!)
                              .toList();
                        });
                      }
                    },
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Pick Images (Multiple)'),
                  ),
                  if (imagePreviews.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: imagePreviews.length,
                        itemBuilder: (ctx, idx) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Stack(
                              children: [
                                Image.memory(
                                  imagePreviews[idx],
                                  height: 120,
                                  width: 120,
                                  fit: BoxFit.cover,
                                ),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: IconButton(
                                    icon: const Icon(Icons.close, color: Colors.red),
                                    onPressed: () {
                                      dialogSetState(() {
                                        pickedFiles.removeAt(idx);
                                        imagePreviews.removeAt(idx);
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final desc = descCtrl.text.trim();
                final price = double.tryParse(priceCtrl.text);
                final qty = int.tryParse(qtyCtrl.text);
                
                if (name.isEmpty || desc.isEmpty || price == null || price <= 0 || qty == null || qty <= 0 || selectedCategoryId == null) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Please fill all required fields with valid values')),
                  );
                  return;
                }

                if (p == null && pickedFiles.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Please select at least one image')),
                  );
                  return;
                }

                Navigator.pop(ctx);
                
                try {
                  if (p == null) {
                    // Create new product with multiple images
                    final payload = {
                      'name': name,
                      'description': desc,
                      'price': price.toString(),
                      'quantity': qty.toString(),
                      'categoryId': selectedCategoryId.toString(),
                    };
                    
                    // Create MultipartFile instances with 'images' field name
                    final imageFiles = pickedFiles
                        .where((f) => f.bytes != null)
                        .map((f) {
                          final mimeType = lookupMimeType(f.name) ?? 'image/jpeg';
                          return http.MultipartFile.fromBytes(
                            'images', // This field name is required by backend
                            f.bytes!,
                            filename: f.name,
                            contentType: MediaType.parse(mimeType),
                          );
                        })
                        .toList();
                    
                    await _service.createWithImages(payload.cast<String, String>(), imageFiles);
                  } else {
                    // Update existing product
                    final payload = {
                      'name': name,
                      'description': desc,
                      'price': price,
                      'quantity': qty,
                      'categoryId': selectedCategoryId,
                    };
                    await _service.update(p.id, payload);
                  }
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Saved')),
                    );
                    // Auto-refresh after a short delay
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (mounted) _refresh();
                    });
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Save failed: $e')),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showEditDialog(),
          ),
        ],
      ),
      body: FutureBuilder<List<Product>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final list = snapshot.data ?? [];
          if (list.isEmpty) {
            return const Center(child: Text('No products found'));
          }
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (ctx, i) {
              final p = list[i];
              final categoryName = _categories.firstWhere(
                (c) => c.id == p.categoryId,
                orElse: () => Category(id: 0, name: 'Unknown'),
              ).name;
              
              return ListTile(
                leading: Image.network(
                  p.image,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (c, o, s) => const Icon(Icons.image_not_supported),
                ),
                title: Text(p.name),
                subtitle: Text('\$${p.price} • Qty: ${p.quantity} • Cat: $categoryName'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showEditDialog(p),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _delete(p.id),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
