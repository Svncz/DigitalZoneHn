import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import '../models/product.dart';
import 'image_selector_dialog.dart';

class ProductDialog extends StatefulWidget {
  final Product? product;

  const ProductDialog({super.key, this.product});

  @override
  State<ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<ProductDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _priceController;
  Uint8List? _imageBytes;
  String? _imageFileName;
  String? _currentImageUrl;
  bool _isUploading = false;

  bool _isPromo = false;
  bool _isAvailable = true;
  String _selectedCategory = 'Video';

  final List<String> _categories = [
    'Video',
    'Música',
    'Juegos',
    'VPN',
    'Software',
    'IA',
    'Seguidores',
    'Otro',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _descController = TextEditingController(
      text: widget.product?.description ?? '',
    );
    _priceController = TextEditingController(
      text: widget.product?.price.toString() ?? '',
    );
    _currentImageUrl = widget.product?.imageUrl;
    _isPromo = widget.product?.promo ?? false;
    _isAvailable = widget.product?.available ?? true;
    _selectedCategory = widget.product?.category ?? 'Video';
  }

  Future<void> _pickImage() async {
    final result = await showDialog(
      context: context,
      builder: (context) =>
          ImageSelectorDialog(initialUrl: _currentImageUrl ?? ''),
    );

    if (result != null) {
      if (result['type'] == 'url') {
        setState(() {
          _currentImageUrl = result['data'];
          _imageBytes = null;
        });
      } else if (result['type'] == 'bytes') {
        setState(() {
          _imageBytes = result['data'];
          _imageFileName = result['name'];
        });
      }
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageBytes == null) return _currentImageUrl;
    try {
      final String fileName =
          _imageFileName ?? '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String path = 'products/${fileName.split('/').last}';

      final Reference ref = FirebaseStorage.instance.ref().child(path);

      final UploadTask uploadTask = ref.putData(
        _imageBytes!,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al subir imagen: $e')));
      }
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.product == null ? 'Nuevo Servicio' : 'Editar Servicio',
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Servicio',
                ),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Categoría'),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCategory = v!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Precio',
                  prefixText: '\$',
                ),
                keyboardType: TextInputType.number,
                validator: (v) =>
                    double.tryParse(v!) == null ? 'Inválido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Descripción'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[600]!),
                    image: _imageBytes != null
                        ? DecorationImage(
                            image: MemoryImage(_imageBytes!),
                            fit: BoxFit.cover,
                          )
                        : (_currentImageUrl != null &&
                              _currentImageUrl!.isNotEmpty)
                        ? DecorationImage(
                            image: NetworkImage(_currentImageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child:
                      (_imageBytes == null &&
                          (_currentImageUrl == null ||
                              _currentImageUrl!.isEmpty))
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt,
                              size: 50,
                              color: Colors.grey,
                            ),
                            Text(
                              'Tocar para seleccionar imagen',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Disponible (Stock)'),
                value: _isAvailable,
                subtitle: Text(
                  _isAvailable
                      ? 'Visible para clientes'
                      : 'Marcado como AGOTADO',
                ),
                activeColor: Colors.green,
                onChanged: (v) => setState(() => _isAvailable = v),
              ),
              SwitchListTile(
                title: const Text('En Oferta'),
                value: _isPromo,
                onChanged: (v) => setState(() => _isPromo = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isUploading ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isUploading ? null : _saveProduct,
          child: _isUploading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Guardar'),
        ),
      ],
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUploading = true);
    final String? imageUrl = await _uploadImage();

    if (imageUrl == null && _imageBytes != null) {
      // Failed upload
      setState(() => _isUploading = false);
      return;
    }

    final data = {
      'name': _nameController.text,
      'description': _descController.text,
      'price': double.tryParse(_priceController.text) ?? 0.0,
      'imageUrl': imageUrl ?? '',
      'promo': _isPromo,
      'category': _selectedCategory,
      'available': _isAvailable,
      if (widget.product == null) 'createdAt': FieldValue.serverTimestamp(),
    };

    try {
      if (widget.product == null) {
        await FirebaseFirestore.instance.collection('products').add(data);
      } else {
        await FirebaseFirestore.instance
            .collection('products')
            .doc(widget.product!.id)
            .update(data);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
