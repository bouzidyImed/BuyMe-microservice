import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import '../services/product_service.dart';
import '../models/product.dart';

class ManageProductScreen extends StatefulWidget {
  const ManageProductScreen({super.key});

  @override
  State<ManageProductScreen> createState() => _ManageProductScreenState();
}

class _ManageProductScreenState extends State<ManageProductScreen> {
  final ProductService _service = ProductService();
  late Future<List<Product>> _future;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() { _future = _service.getAll(); });
  }

  Future<void> _delete(int id) async {
    try {
      await _service.delete(id);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted')));
      _refresh();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  void _showEditDialog([Product? p]) {
    final nameCtrl = TextEditingController(text: p?.name ?? '');
    final descCtrl = TextEditingController(text: p?.description ?? '');
    final priceCtrl = TextEditingController(text: p?.price.toString() ?? '0');
    final qtyCtrl = TextEditingController(text: p?.quantity.toString() ?? '0');
    final catCtrl = TextEditingController(text: p?.categoryId.toString() ?? '0');
    PlatformFile? pickedFile;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(p == null ? 'Create Product' : 'Edit Product'),
        content: StatefulBuilder(
          builder: (dialogCtx, dialogSetState) => SingleChildScrollView(
            child: Column(children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
              TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Price'), keyboardType: TextInputType.number),
              TextField(controller: qtyCtrl, decoration: const InputDecoration(labelText: 'Quantity'), keyboardType: TextInputType.number),
              TextField(controller: catCtrl, decoration: const InputDecoration(labelText: 'CategoryId'), keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  final res = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
                  if (res != null && res.files.isNotEmpty) {
                    pickedFile = res.files.first;
                    dialogSetState(() {});
                  }
                },
                icon: const Icon(Icons.upload_file),
                label: const Text('Pick Image'),
              ),
              if (pickedFile != null && pickedFile!.bytes != null) ...[
                const SizedBox(height: 8),
                Image.memory(pickedFile!.bytes!, height: 120, fit: BoxFit.cover),
              ],
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final payload = {
                'name': nameCtrl.text,
                'description': descCtrl.text,
                'price': double.tryParse(priceCtrl.text)?.toString() ?? '0',
                'quantity': int.tryParse(qtyCtrl.text)?.toString() ?? '0',
                'categoryId': int.tryParse(catCtrl.text)?.toString() ?? '0',
              };
              Navigator.pop(ctx);
              try {
                if (p == null) {
                  if (pickedFile != null && pickedFile!.bytes != null) {
                    final mimeType = lookupMimeType(pickedFile!.name) ?? 'application/octet-stream';
                    final multipart = http.MultipartFile.fromBytes('file', pickedFile!.bytes!, filename: pickedFile!.name, contentType: MediaType.parse(mimeType));
                    await _service.createWithFile(payload.cast<String, String>(), multipart);
                  } else {
                    await _service.create(payload.cast<String, String>());
                  }
                } else {
                  await _service.update(p.id, payload);
                }
                _refresh();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
              }
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Products'), actions: [IconButton(icon: const Icon(Icons.add), onPressed: () => _showEditDialog())]),
      body: FutureBuilder<List<Product>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          final list = snapshot.data ?? [];
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (ctx, i) {
              final p = list[i];
              return ListTile(
                leading: Image.network(p.image, width: 56, height: 56, fit: BoxFit.cover, errorBuilder: (c,o,s)=>const Icon(Icons.image_not_supported)),
                title: Text(p.name),
                subtitle: Text('\$${p.price} • Qty: ${p.quantity} • Cat: ${p.categoryId}'),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(icon: const Icon(Icons.edit), onPressed: () => _showEditDialog(p)),
                  IconButton(icon: const Icon(Icons.delete), onPressed: () => _delete(p.id)),
                ]),
              );
            },
          );
        },
      ),
    );
  }
}
