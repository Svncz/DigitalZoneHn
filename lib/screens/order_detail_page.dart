import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

class OrderDetailPage extends StatelessWidget {
  final Map<String, dynamic> data;
  final String orderId;

  const OrderDetailPage({super.key, required this.data, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final items = (data['items'] as List<dynamic>?) ?? [];
    final total = data['total'] ?? 0.0;
    final date = (data['createdAt'] as Timestamp?)?.toDate();
    final status = data['status'] ?? 'pending';
    final phone = data['phone'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Orden'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () {
              _copyOrderToClipboard(
                context,
                items,
                total,
                data['customerName'] ?? 'Cliente',
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Orden #${orderId.substring(0, 8)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                        ),
                      ),
                      Text(
                        date != null
                            ? DateFormat('dd MMM yyyy, hh:mm a').format(date)
                            : '',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                StatusBadge(status: status),
              ],
            ),
            const Divider(height: 32),

            // Customer
            const Text(
              'Cliente',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(
                data['customerName'] ?? 'Sin Nombre',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(phone),
              trailing: IconButton(
                icon: const Icon(Icons.message, color: Colors.green),
                onPressed: () => _launchWhatsApp(phone),
              ),
            ),
            const Divider(height: 32),

            // Items
            const Text(
              'Productos',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 8),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                final imgUrl = item['imageUrl'] as String?;
                return Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: (imgUrl != null && imgUrl.isNotEmpty)
                            ? Image.network(
                                imgUrl,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 60,
                                  height: 60,
                                  color: Colors.grey,
                                  child: const Icon(Icons.image_not_supported),
                                ),
                              )
                            : Container(
                                width: 60,
                                height: 60,
                                color: Colors.blueGrey,
                                child: const Icon(Icons.shopping_bag),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['name'] ?? 'Producto',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              'Cant: ${item['qty'] ?? 1} x HNL ${item['price']}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'HNL ${(item['qty'] ?? 1) * (item['price'] ?? 0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total General:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'HNL ${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.greenAccent,
                  ),
                ),
              ],
            ),
            const Divider(height: 40),

            // Actions
            const Text(
              'Gestionar Estado',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ActionBtn(
                  label: 'Pendiente',
                  color: Colors.orange,
                  icon: Icons.schedule,
                  onTap: () => _updateStatus(context, 'pending'),
                ),
                ActionBtn(
                  label: 'Completar',
                  color: Colors.green,
                  icon: Icons.check_circle,
                  onTap: () => _updateStatus(context, 'completed'),
                ),
                ActionBtn(
                  label: 'Cancelar',
                  color: Colors.red,
                  icon: Icons.cancel,
                  onTap: () => _updateStatus(context, 'cancelled'),
                ),
                ActionBtn(
                  label: 'Archivar',
                  color: Colors.grey,
                  icon: Icons.archive,
                  onTap: () => _updateStatus(context, 'archived'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _launchWhatsApp(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    // Remove +504 if double
    var cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (!cleanPhone.startsWith('504') && cleanPhone.length == 8)
      cleanPhone = '504$cleanPhone';

    final url = Uri.parse("https://wa.me/$cleanPhone");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _copyOrderToClipboard(
    BuildContext context,
    List items,
    dynamic total,
    String name,
  ) {
    String text = "*Pedido de $name:*\n";
    for (var item in items) {
      text += "- ${item['qty']}x ${item['name']}\n";
    }
    text += "*Total: HNL $total*";
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pedido copiado al portapapeles')),
    );
  }

  void _updateStatus(BuildContext context, String newStatus) {
    FirebaseFirestore.instance.collection('orders').doc(orderId).update({
      'status': newStatus,
    });
    Navigator.pop(context); // Go back after update
  }
}

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'completed':
        color = Colors.green;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      case 'archived':
        color = Colors.grey;
        break;
      default:
        color = Colors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

class ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const ActionBtn({
    super.key,
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
