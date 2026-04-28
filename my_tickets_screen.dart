import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import 'ticket_detail_screen.dart';

class MyTicketsScreen extends StatelessWidget {
  const MyTicketsScreen({Key? key}) : super(key: key);

  void _showCreateTicketDialog(BuildContext context) {
    String issue = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16162C),
        title: const Text('Create New Ticket'),
        content: TextField(
          maxLines: 3,
          decoration: const InputDecoration(
              hintText: 'Describe your issue...',
              filled: true,
              fillColor: Colors.black26),
          onChanged: (val) => issue = val,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB026FF)),
            onPressed: () async {
              if (issue.isNotEmpty) {
                await FirestoreService.createTicket(issue);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Ticket created!'),
                    backgroundColor: Colors.green));
              }
            },
            child: const Text('Submit',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
          title: const Text('My Tickets'),
          backgroundColor: Colors.transparent),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFB026FF),
        onPressed: () => _showCreateTicketDialog(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tickets')
            .where('userId', isEqualTo: currentUser?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final tickets = snapshot.data!.docs;
          if (tickets.isEmpty) {
            return const Center(child: Text('No tickets found.'));
          }

          return ListView.builder(
            itemCount: tickets.length,
            itemBuilder: (context, index) {
              final doc = tickets[index];
              final tData = doc.data() as Map<String, dynamic>;
              final status = tData['status'] ?? 'Pending';
              Color statusColor = status == 'Resolved'
                  ? Colors.green
                  : (status == 'In Progress' ? Colors.blue : Colors.orange);
              return Card(
                color: const Color(0xFF16162C),
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(tData['issue'] ?? 'No Description'),
                  subtitle: Text('Status: $status',
                      style: TextStyle(
                          color: statusColor, fontWeight: FontWeight.bold)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (((tData['userUnread'] ?? 0) as num).toInt() > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text('${tData['userUnread']}',
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
                          isAdminView: false,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
