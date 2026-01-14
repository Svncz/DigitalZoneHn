import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/combo.dart';
import '../widgets/combo_dialog.dart';

class CombosView extends StatelessWidget {
  const CombosView({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('combos').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(
            child: Text(
              'No hay combos creados.',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final combo = Combo.fromDocument(docs[index]);
            return Card(
              color: const Color(0xFF1e293b),
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: combo.imageUrl.isNotEmpty
                    ? Image.network(
                        combo.imageUrl,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) =>
                            const Icon(Icons.layers, color: Colors.white54),
                      )
                    : const Icon(Icons.layers, color: Colors.white54),
                title: Text(
                  combo.name,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  'HNL ${combo.price.toStringAsFixed(2)} • ${combo.productIds.length} productos',
                  style: const TextStyle(color: Colors.grey),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: combo.available,
                      onChanged: (val) {
                        FirebaseFirestore.instance
                            .collection('combos')
                            .doc(combo.id)
                            .update({'available': val});
                      },
                      activeColor: const Color(0xFF6366f1),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blueAccent),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => ComboDialog(combo: combo),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => _confirmDelete(context, combo),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, Combo combo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1e293b),
        title: const Text(
          'Eliminar Combo',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '¿Seguro que quieres eliminar "${combo.name}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('combos')
                  .doc(combo.id)
                  .delete();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
