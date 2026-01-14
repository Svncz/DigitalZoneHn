import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'order_detail_page.dart'; // Ensure StatusBadge is exported or import from widget

class OrdersView extends StatefulWidget {
  const OrdersView({super.key});

  @override
  State<OrdersView> createState() => _OrdersViewState();
}

class _OrdersViewState extends State<OrdersView> {
  int _currentPage = 0;
  static const int _perPage = 30;
  final List<DocumentSnapshot> _checkpoints = [];

  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .limit(_perPage);

    // Apply cursor if not on first page
    if (_currentPage > 0 && _checkpoints.length >= _currentPage) {
      query = query.startAfterDocument(_checkpoints[_currentPage - 1]);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          if (_currentPage == 0) {
            return const Center(
              child: Text(
                'No hay pedidos registrados',
                style: TextStyle(color: Colors.grey),
              ),
            );
          } else {
            // Handle case where next page is empty (shouldn't happen with disabled button, but safe fallback)
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'No hay más pedidos.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  TextButton(onPressed: _prevPage, child: const Text("Volver")),
                ],
              ),
            );
          }
        }

        final docs = snapshot.data!.docs;
        final isLastPage = docs.length < _perPage;

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final items = (data['items'] as List<dynamic>?) ?? [];
                  final total = data['total'] ?? 0.0;
                  final date = (data['createdAt'] as Timestamp?)?.toDate();

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    color: Colors.white10,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                OrderDetailPage(data: data, orderId: doc.id),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blueAccent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.shopping_bag,
                                color: Colors.blueAccent,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['customerName'] ?? 'Cliente',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'HNL ${total.toStringAsFixed(2)} • ${items.length} items',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                  Text(
                                    date != null
                                        ? DateFormat(
                                            'dd MMM, hh:mm a',
                                          ).format(date)
                                        : '',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            StatusBadge(status: data['status'] ?? 'pending'),
                            const SizedBox(width: 8),
                            const Icon(Icons.chevron_right, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Pagination Controls
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.black26,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: _currentPage > 0 ? _prevPage : null,
                  ),
                  Text('Página ${_currentPage + 1}'),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    // If we have less than _perPage, we are at the end.
                    // IMPORTANT: We need snapshot data here to know if we can go next.
                    // But we are inside the builder, so we have 'docs'.
                    onPressed: !isLastPage ? () => _nextPage(docs.last) : null,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _nextPage(DocumentSnapshot lastDoc) {
    if (_checkpoints.length == _currentPage) {
      _checkpoints.add(lastDoc);
    } else {
      // Should match
      _checkpoints[_currentPage] = lastDoc;
    }
    setState(() {
      _currentPage++;
    });
  }

  void _prevPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
    }
  }
}
