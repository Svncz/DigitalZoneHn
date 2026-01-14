import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../widgets/stat_card.dart';

class FinancesView extends StatelessWidget {
  const FinancesView({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        // Calculate Total Revenue (only completed orders)
        double totalRevenue = 0;
        final now = DateTime.now();
        final List<double> weeklyData = List.filled(7, 0.0);

        // Map weekdays: (DateTime.weekday) 1=Mon .. 7=Sun
        // We want today to be the last bar.

        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['status'] == 'completed') {
            final price = (data['total'] ?? 0.0).toDouble();
            totalRevenue += price;

            final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
            if (createdAt != null) {
              final diff = now.difference(createdAt).inDays;
              if (diff < 7 && diff >= 0) {
                // diff 0 = today (index 6)
                // diff 6 = 7 days ago (index 0)
                final index = 6 - diff;
                if (index >= 0 && index < 7) {
                  weeklyData[index] += price;
                }
              }
            }
          }
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StatCard(
                title: 'Ingresos Totales (Completados)',
                value: 'HNL ${NumberFormat("#,##0.00").format(totalRevenue)}',
                color: Colors.greenAccent,
              ),
              const SizedBox(height: 30),
              const Text(
                "Ingresos: Últimos 7 Días",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 250,
                child: BarChart(
                  BarChartData(
                    gridData: FlGridData(show: false),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= 7)
                              return const SizedBox.shrink();
                            // Calculate label day
                            // index 6 is today, index 0 is 6 days ago
                            final day = now.subtract(Duration(days: 6 - index));
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                DateFormat('E', 'es').format(
                                  day,
                                ), // Needs intl initialization or simple switch
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: weeklyData.asMap().entries.map((e) {
                      return BarChartGroupData(
                        x: e.key,
                        barRods: [
                          BarChartRodData(
                            toY: e.value,
                            color: const Color(0xFF6366f1),
                            width: 16,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
