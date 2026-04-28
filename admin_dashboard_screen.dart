import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Dashboard'),
          backgroundColor: Colors.transparent),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _UsersAndRevenue(),
            const SizedBox(height: 16),
            _AppsAndTickets(),
            const SizedBox(height: 16),
            const Text('Usage trend (last 7 days)',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const _UsageChart(),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16162C),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
                Text(value,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UsersAndRevenue extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        final totalUsers = docs.length;
        int totalRevenue = 0;
        int blocked = 0;
        for (final d in docs) {
          final m = d.data() as Map<String, dynamic>;
          totalRevenue += (m['totalRevenue'] ?? 0) as int;
          if (m['isUsageBlocked'] == true) blocked++;
        }
        return Row(
          children: [
            Expanded(
                child: _StatCard(
                    label: 'Total Users',
                    value: '$totalUsers',
                    icon: Icons.people,
                    color: const Color(0xFFB026FF))),
            const SizedBox(width: 12),
            Expanded(
                child: _StatCard(
                    label: 'Revenue',
                    value: '₹$totalRevenue',
                    icon: Icons.monetization_on,
                    color: Colors.amber)),
          ],
        );
      },
    );
  }
}

class _AppsAndTickets extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<int>>(
      future: Future.wait([
        FirebaseFirestore.instance
            .collection('apps')
            .count()
            .get()
            .then((q) => q.count ?? 0),
        FirebaseFirestore.instance
            .collection('tickets')
            .where('status', isEqualTo: 'Pending')
            .count()
            .get()
            .then((q) => q.count ?? 0),
      ]),
      builder: (context, snap) {
        final apps = (snap.data != null && snap.data!.isNotEmpty)
            ? snap.data![0]
            : 0;
        final openTickets = (snap.data != null && snap.data!.length > 1)
            ? snap.data![1]
            : 0;
        return Row(
          children: [
            Expanded(
                child: _StatCard(
                    label: 'Apps Generated',
                    value: '$apps',
                    icon: Icons.apps,
                    color: const Color(0xFF00E5FF))),
            const SizedBox(width: 12),
            Expanded(
                child: _StatCard(
                    label: 'Open Tickets',
                    value: '$openTickets',
                    icon: Icons.support_agent,
                    color: Colors.orangeAccent)),
          ],
        );
      },
    );
  }
}

class _UsageChart extends StatelessWidget {
  const _UsageChart();

  @override
  Widget build(BuildContext context) {
    final since = DateTime.now().subtract(const Duration(days: 7));
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('aiLogs')
          .where('createdAt', isGreaterThan: Timestamp.fromDate(since))
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const SizedBox(
              height: 180,
              child: Center(
                  child:
                      CircularProgressIndicator(color: Color(0xFFB026FF))));
        }
        // Bucket by day (0 = oldest day, 6 = today)
        final buckets = List<int>.filled(7, 0);
        for (final d in snap.data!.docs) {
          final ts = (d.data() as Map<String, dynamic>)['createdAt'];
          if (ts is Timestamp) {
            final diff = DateTime.now().difference(ts.toDate()).inDays;
            final idx = 6 - diff.clamp(0, 6);
            buckets[idx] += 1;
          }
        }
        final maxY = (buckets.fold<int>(0, (a, b) => a > b ? a : b) + 1)
            .toDouble();
        return SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              maxY: maxY,
              gridData: FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, meta) {
                      final i = v.toInt();
                      final labels = ['6d', '5d', '4d', '3d', '2d', '1d', 'Now'];
                      if (i < 0 || i >= labels.length) return const SizedBox();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(labels[i],
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 10)),
                      );
                    },
                  ),
                ),
              ),
              barGroups: List.generate(7, (i) {
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: buckets[i].toDouble(),
                      color: const Color(0xFFB026FF),
                      width: 18,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                );
              }),
            ),
          ),
        );
      },
    );
  }
}
