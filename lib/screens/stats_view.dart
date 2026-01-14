import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class StatsView extends StatefulWidget {
  const StatsView({super.key});

  @override
  State<StatsView> createState() => _StatsViewState();
}

class _StatsViewState extends State<StatsView> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {});
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Add logout logic if needed
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.collection('products').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No hay productos disponibles'));
          }

          // Calculate stats
          final products = snapshot.data!.docs;
          final totalProducts = products.length;
          final availableProducts = products.where((d) {
            final data = d.data() as Map<String, dynamic>;
            return data['available'] != false;
          }).length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCards(totalProducts, availableProducts),
                const SizedBox(height: 30),
                const Text(
                  "Enlace Rápido a Opiniones",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () async {
                    final Uri url = Uri.parse('/opiniones');
                    if (!await launchUrl(url)) {
                      // Handle error
                    }
                  },
                  icon: const Icon(Icons.star),
                  label: const Text("Ver Opiniones (Web)"),
                ),
                const SizedBox(height: 30),
                const Text(
                  "Inventario Reciente",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                _buildProductList(products),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCards(int total, int available) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      children: [
        _statCard("Total Productos", "$total", Colors.blue),
        _statCard("Disponibles", "$available", Colors.green),
        // Add more stats here (e.g. Orders)
      ],
    );
  }

  Widget _statCard(String title, String value, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(15),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: TextStyle(color: color, fontSize: 16)),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductList(List<QueryDocumentSnapshot> docs) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final data = docs[index].data() as Map<String, dynamic>;
        return Card(
          color: const Color(0xFF1E293B),
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: _buildImage(data['imageUrl']),
            title: Text(
              data['name'] ?? 'Sin nombre',
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              "HNL ${data['price']}",
              style: TextStyle(color: Colors.grey[400]),
            ),
            trailing: data['available'] == false
                ? const Icon(Icons.error, color: Colors.red)
                : const Icon(Icons.check_circle, color: Colors.green),
          ),
        );
      },
    );
  }

  Widget _buildImage(String? url) {
    if (url == null || url.isEmpty) return const Icon(Icons.image);
    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: Image.network(
        url,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
      ),
    );
  }
}
