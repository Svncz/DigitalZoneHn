import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import '../widgets/product_card.dart';

class InventoryView extends StatefulWidget {
  const InventoryView({super.key});

  @override
  State<InventoryView> createState() => _InventoryViewState();
}

class _InventoryViewState extends State<InventoryView> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Todas';
  String _searchText = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Búsqueda
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar producto...',
              prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (val) => setState(() => _searchText = val.toLowerCase()),
          ),
        ),

        // Categorías (Diseño horizontal)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: ['Todas', 'Video', 'Música', 'Juegos', 'VPN', 'IA'].map((
              cat,
            ) {
              final isSelected = _selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  onSelected: (val) {
                    if (val) setState(() => _selectedCategory = cat);
                  },
                  backgroundColor: Colors.white10,
                  selectedColor: Colors.blueAccent.withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.blueAccent : Colors.white70,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 8),

        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('products')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.requireData.docs;

              // Filtrado Local
              final filteredDocs = docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name = (data['name'] ?? '').toString().toLowerCase();
                final desc = (data['description'] ?? '')
                    .toString()
                    .toLowerCase();
                final category = data['category'] ?? 'Video';

                bool matchesSearch =
                    name.contains(_searchText) || desc.contains(_searchText);
                bool matchesCategory =
                    _selectedCategory == 'Todas' ||
                    category == _selectedCategory;

                return matchesSearch && matchesCategory;
              }).toList();

              if (filteredDocs.isEmpty) {
                return const Center(
                  child: Text(
                    'No se encontraron productos.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredDocs.length,
                itemBuilder: (context, index) {
                  final doc = filteredDocs[index];
                  final product = Product.fromMap(
                    doc.id,
                    doc.data() as Map<String, dynamic>,
                  );
                  return ProductCard(product: product);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
