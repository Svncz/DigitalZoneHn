import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import '../models/product.dart';
import '../models/combo.dart';
import '../widgets/image_selector_dialog.dart';

class ComboDialog extends StatefulWidget {
  final Combo? combo;

  const ComboDialog({super.key, this.combo});

  @override
  State<ComboDialog> createState() => _ComboDialogState();
}

class _ComboDialogState extends State<ComboDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  // Image logic
  Uint8List? _imageBytes;
  String? _imageFileName;
  String? _currentImageUrl;
  bool _isUploading = false;

  List<String> _selectedProductIds = [];
  List<Product> _allProducts = []; // Full list
  List<Product> _filteredProducts = []; // Filtered List

  // Filter logic
  String _searchQuery = '';
  String _selectedCategory = 'Todas';

  @override
  void initState() {
    super.initState();
    _loadProducts();
    if (widget.combo != null) {
      _nameController.text = widget.combo!.name;
      _descController.text = widget.combo!.description;
      _priceController.text = widget.combo!.price.toString();
      _currentImageUrl = widget.combo!.imageUrl;
      _selectedProductIds = List.from(widget.combo!.productIds);
    }
  }

  Future<void> _loadProducts() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('products')
        .get();
    setState(() {
      _allProducts = snapshot.docs
          .map((doc) => Product.fromMap(doc.id, doc.data()))
          .toList();
      _filterProducts();
    });
  }

  void _filterProducts() {
    setState(() {
      _filteredProducts = _allProducts.where((p) {
        final matchesSearch = p.name.toLowerCase().contains(
          _searchQuery.toLowerCase(),
        );
        final matchesCategory =
            _selectedCategory == 'Todas' || p.category == _selectedCategory;
        return matchesSearch && matchesCategory;
      }).toList();
    });
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
          _imageFileName = null;
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
          _imageFileName ??
          'combos/${DateTime.now().millisecondsSinceEpoch}.jpg';
      // Ensure path is combos/
      final String path = 'combos/${fileName.split('/').last}';

      final Reference ref = FirebaseStorage.instance.ref().child(path);
      // Upload bytes
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
      backgroundColor: const Color(0xFF1e293b),
      title: Text(
        widget.combo == null ? 'Nuevo Combo' : 'Editar Combo',
        style: const TextStyle(color: Colors.white),
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(_nameController, 'Nombre del Combo'),
                const SizedBox(height: 10),
                _buildTextField(_descController, 'Descripción', maxLines: 2),
                const SizedBox(height: 10),
                _buildTextField(
                  _priceController,
                  'Precio Total (HNL)',
                  isNumber: true,
                ),
                const SizedBox(height: 15),

                // Image Picker
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
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
                                Icons.add_photo_alternate,
                                size: 40,
                                color: Colors.white54,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Tocar para seleccionar imagen',
                                style: TextStyle(color: Colors.white54),
                              ),
                            ],
                          )
                        : null,
                  ),
                ),

                const SizedBox(height: 20),
                Divider(color: Colors.white24),
                const SizedBox(height: 10),

                // --- Product Selection Header ---
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Seleccionar Productos:',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Search Bar
                TextField(
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Buscar producto...',
                    hintStyle: TextStyle(color: Colors.grey),
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.black26,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 0,
                    ),
                  ),
                  onChanged: (val) {
                    _searchQuery = val;
                    _filterProducts();
                  },
                ),
                const SizedBox(height: 10),

                // Category Filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children:
                        ['Todas', 'Video', 'Música', 'Juegos', 'VPN', 'IA'].map(
                          (cat) {
                            final isSelected = _selectedCategory == cat;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(cat),
                                selected: isSelected,
                                onSelected: (val) {
                                  setState(() {
                                    _selectedCategory = cat;
                                    _filterProducts();
                                  });
                                },
                                backgroundColor: Colors.white10,
                                selectedColor: const Color(0xFF6366f1),
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white70,
                                ),
                              ),
                            );
                          },
                        ).toList(),
                  ),
                ),

                const SizedBox(height: 10),

                // Product List
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _allProducts.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : _filteredProducts.isEmpty
                      ? const Center(
                          child: Text(
                            "No hay productos",
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = _filteredProducts[index];
                            final isSelected = _selectedProductIds.contains(
                              product.id,
                            );
                            return CheckboxListTile(
                              title: Text(
                                product.name,
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                'HNL \${product.price}',
                                style: const TextStyle(color: Colors.grey),
                              ),
                              value: isSelected,
                              activeColor: const Color(0xFF6366f1),
                              checkColor: Colors.white,
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedProductIds.add(product.id);
                                  } else {
                                    _selectedProductIds.remove(product.id);
                                  }
                                });
                              },
                            );
                          },
                        ),
                ),
                if (_selectedProductIds.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      '${_selectedProductIds.length} productos seleccionados',
                      style: const TextStyle(color: Color(0xFF6366f1)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366f1),
          ),
          onPressed: _isUploading ? null : _saveCombo,
          child: _isUploading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Guardar', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white10),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF6366f1)),
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.black26,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          if (label == 'URL de Imagen (Opcional)')
            return null; // Logic handled by image picker now
          return 'Campo requerido';
        }
        return null;
      },
    );
  }

  Future<void> _saveCombo() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProductIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos un producto')),
      );
      return;
    }

    setState(() => _isUploading = true);

    final imageUrl = await _uploadImage();

    final comboData = {
      'name': _nameController.text,
      'description': _descController.text,
      'price': double.tryParse(_priceController.text) ?? 0.0,
      'imageUrl': imageUrl ?? '',
      'productIds': _selectedProductIds,
      'available': true, // Default to true on create/edit
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      if (widget.combo == null) {
        comboData['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection('combos').add(comboData);
      } else {
        await FirebaseFirestore.instance
            .collection('combos')
            .doc(widget.combo!.id)
            .update(comboData);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isUploading = false);
      }
    }
  }
}
