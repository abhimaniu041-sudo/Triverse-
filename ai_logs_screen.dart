import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AiLogsScreen extends StatefulWidget {
  const AiLogsScreen({Key? key}) : super(key: key);

  @override
  State<AiLogsScreen> createState() => _AiLogsScreenState();
}

class _AiLogsScreenState extends State<AiLogsScreen> {
  String _filter = 'all'; // all | app | game

  Query<Map<String, dynamic>> _query() {
    final base = FirebaseFirestore.instance
        .collection('aiLogs')
        .orderBy('createdAt', descending: true)
        .limit(100);
    if (_filter == 'all') return base;
    return base.where('kind', isEqualTo: _filter);
  }

  String _rel(Timestamp? t) {
    if (t == null) return '';
    final d = DateTime.now().difference(t.toDate());
    if (d.inMinutes < 1) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('AI Logs'),
          backgroundColor: Colors.transparent),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _chip('All', 'all'),
                _chip('Apps', 'app'),
                _chip('Games', 'game'),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _query().snapshots(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(
                      child: Text('Error: ${snap.error}',
                          style: const TextStyle(color: Colors.red)));
                }
                if (!snap.hasData) {
                  return const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFFB026FF)));
                }
                final docs = snap.data!.docs;
                if (docs.isEmpty) {
                  return const Center(
                      child: Text('No AI usage yet.',
                          style: TextStyle(color: Colors.grey)));
                }
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final m = docs[i].data();
                    final kind = (m['kind'] ?? 'app') as String;
                    final isGame = kind == 'game';
                    return Card(
                      color: const Color(0xFF16162C),
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: (isGame
                                  ? const Color(0xFF00E5FF)
                                  : const Color(0xFFB026FF))
                              .withOpacity(0.2),
                          child: Icon(
                              isGame
                                  ? Icons.sports_esports
                                  : Icons.phone_android,
                              color: isGame
                                  ? const Color(0xFF00E5FF)
                                  : const Color(0xFFB026FF)),
                        ),
                        title: Text(m['email'] ?? 'unknown',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m['prompt'] ?? '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(
                                '−${m['creditsDeducted']} credits  •  ₹${m['costRupees']}  •  ${_rel(m['createdAt'] as Timestamp?)}',
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 11)),
                          ],
                        ),
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

  Widget _chip(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: _filter == value,
        onSelected: (_) => setState(() => _filter = value),
        selectedColor: const Color(0xFFB026FF),
        backgroundColor: const Color(0xFF16162C),
        labelStyle: TextStyle(
          color: _filter == value ? Colors.white : Colors.grey[300],
        ),
      ),
    );
  }
}
