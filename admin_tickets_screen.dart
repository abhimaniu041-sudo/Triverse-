import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ticket_detail_screen.dart';

/// Admin-only inbox of ALL tickets across all users.
class AdminTicketsScreen extends StatefulWidget {
  const AdminTicketsScreen({Key? key}) : super(key: key);

  @override
  _AdminTicketsScreenState createState() => _AdminTicketsScreenState();
}

class _AdminTicketsScreenState extends State<AdminTicketsScreen> {
  String _filter = 'All'; // All | Pending | In Progress | Resolved

  Query<Map<String, dynamic>> _buildQuery() {
    final base = FirebaseFirestore.instance
        .collection('tickets')
        .orderBy('lastMessageAt', descending: true);
    if (_filter == 'All') return base;
    return base.where('status', isEqualTo: _filter);
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'Resolved':
        return Colors.green;
      case 'In Progress':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  String _relativeTime(Timestamp? t) {
    if (t == null) return '';
    final diff = DateTime.now().difference(t.toDate());
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Tickets (Admin)'),
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: ['All', 'Pending', 'In Progress', 'Resolved']
                  .map((s) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(s),
                          selected: _filter == s,
                          onSelected: (_) => setState(() => _filter = s),
                          selectedColor: const Color(0xFFB026FF),
                          backgroundColor: const Color(0xFF16162C),
                          labelStyle: TextStyle(
                            color: _filter == s
                                ? Colors.white
                                : Colors.grey[300],
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _buildQuery().snapshots(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('Error: ${snap.error}',
                          style: const TextStyle(color: Colors.red)),
                    ),
                  );
                }
                if (!snap.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFFB026FF)));
                }
                final docs = snap.data!.docs;
                if (docs.isEmpty) {
                  return const Center(
                      child: Text('No tickets found.',
                          style: TextStyle(color: Colors.grey)));
                }
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final doc = docs[i];
                    final t = doc.data();
                    final status = (t['status'] ?? 'Pending').toString();
                    final statusColor = _statusColor(status);
                    final last =
                        _relativeTime(t['lastMessageAt'] as Timestamp?);

                    return Card(
                      color: const Color(0xFF16162C),
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: statusColor.withOpacity(0.2),
                          child: Icon(Icons.support_agent,
                              color: statusColor, size: 20),
                        ),
                        title: Text(t['email'] ?? 'Unknown',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t['issue'] ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                          color: statusColor, width: 1)),
                                  child: Text(status,
                                      style: TextStyle(
                                          color: statusColor,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 8),
                                Text(last,
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 11)),
                              ],
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (((t['adminUnread'] ?? 0) as num).toInt() > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                    color: Colors.redAccent,
                                    borderRadius:
                                        BorderRadius.circular(12)),
                                child: Text('${t['adminUnread']}',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold)),
                              ),
                            const SizedBox(width: 6),
                            const Icon(Icons.chevron_right,
                                color: Color(0xFFB026FF)),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => TicketDetailScreen(
                                        ticketId: doc.id,
                                        isAdminView: true,
                                      )));
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
