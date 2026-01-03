import 'package:flutter/material.dart';
import '../models/category.dart';
import '../services/category_service.dart';

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  final CategoryService _service = CategoryService();
  late Future<List<Category>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getAll();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _service.getAll();
    });
  }

  Future<void> _showEditDialog([Category? cat]) async {
    final nameCtrl = TextEditingController(text: cat?.name ?? '');
    final descCtrl = TextEditingController(text: cat?.description ?? '');
    final isNew = cat == null;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isNew ? 'Create Category' : 'Edit Category'),
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
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final desc = descCtrl.text.trim();
              if (name.isEmpty || desc.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Please fill all required fields')),
                );
                return;
              }
              try {
                if (isNew) {
                  await _service.create({'name': name, 'description': desc});
                } else {
                  await _service.update(cat!.id, {'name': name, 'description': desc});
                }
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Category saved')),
                  );
                  // Auto-refresh after a short delay
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (mounted) _refresh();
                  });
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(Category cat) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Delete "${cat.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      try {
        await _service.delete(cat.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Category deleted')),
          );
          // Auto-refresh after a short delay
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) _refresh();
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Delete failed: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Categories'), actions: [
        IconButton(onPressed: () => _showEditDialog(), icon: const Icon(Icons.add)),
      ]),
      body: FutureBuilder<List<Category>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          final data = snapshot.data ?? [];
          if (data.isEmpty) return const Center(child: Text('No categories'));
          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              final cat = data[index];
              return ListTile(
                title: Text(cat.name),
                subtitle: Text('Id: ${cat.id}${cat.description.isNotEmpty ? '\n${cat.description}' : ''}'),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(icon: const Icon(Icons.edit), onPressed: () => _showEditDialog(cat)),
                  IconButton(icon: const Icon(Icons.delete), onPressed: () => _delete(cat)),
                ]),
              );
            },
          );
        },
      ),
    );
  }
}
