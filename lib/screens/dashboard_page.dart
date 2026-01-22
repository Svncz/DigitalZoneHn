import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/product_dialog.dart';
import '../widgets/combo_dialog.dart';
import '../widgets/banner_dialog.dart';

import 'stats_view.dart';
import 'finances_view.dart';
import 'inventory_view.dart';
import 'combos_view.dart';
import 'orders_view.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const StatsView(),
    const FinancesView(),
    const InventoryView(),
    const CombosView(),
    const OrdersView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('DigitalZone Admin'),
            Text(
              'v2.3 (Stable)',
              style: TextStyle(fontSize: 10, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.campaign),
            onPressed: () => _showBannerConfig(context),
            tooltip: 'Configurar Anuncio',
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
            tooltip: 'Cerrar Sesión',
          ),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1e293b),
        selectedItemColor: const Color(0xFF6366f1),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Resumen',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money),
            label: 'Finanzas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Inventario',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.layers), label: 'Combos'),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Pedidos',
          ),
        ],
      ),
      floatingActionButton: _getFab(),
    );
  }

  Widget? _getFab() {
    if (_currentIndex == 2) {
      // Inventario
      return FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const ProductDialog(),
          );
        },
        backgroundColor: const Color(0xFF6366f1),
        child: const Icon(Icons.add),
      );
    } else if (_currentIndex == 3) {
      // Combos
      return FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const ComboDialog(),
          );
        },
        backgroundColor: const Color(0xFF6366f1),
        child: const Icon(Icons.add),
      );
    }
    return null;
  }

  void _showBannerConfig(BuildContext context) {
    showDialog(context: context, builder: (context) => const BannerDialog());
  }
}
