import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/stat_card.dart';

class StatsView extends StatelessWidget {
  const StatsView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Resumen del Negocio',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          // Products Count
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('products')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text(
                  'Error: ${snapshot.error}',
                  style: TextStyle(color: Colors.red),
                );
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData) return const Text('No Data');

              final docs = snapshot.data!.docs;
              final total = docs.length;
              final unavailable = docs.where((d) {
                final data = d.data() as Map<String, dynamic>;
                return (data['available'] ?? true) == false;
              }).length;

              return Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Productos Totales',
                      value: total.toString(),
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: StatCard(
                      title: 'Agotados',
                      value: unavailable.toString(),
                      color: Colors.redAccent,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          // Orders Count
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('orders').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text(
                  'Error: ${snapshot.error}',
                  style: TextStyle(color: Colors.red),
                );
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final totalOrders = snapshot.data?.size ?? 0;
              return StatCard(
                title: 'Pedidos Recibidos',
                value: totalOrders.toString(),
                color: Colors.green,
              );
            },
          ),
          const SizedBox(height: 30),
          const Text(
            'Accesos Directos',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ListTile(
            tileColor: Colors.white10,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            leading: const Icon(Icons.star, color: Colors.yellow),
            title: const Text('Ver Opiniones (Web)'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () async {
              // TODO: Update URL to the deployed Firebase Hosting URL
              final url = Uri.parse(
                'https://digitalzonehn.web.app/opiniones.html',
              );
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              }
            },
          ),
        ],
      ),
    );
  }
}
