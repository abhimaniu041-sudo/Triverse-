import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';

/// Reusable ticket conversation screen.
/// - `isAdminView = true`  → admin can reply & mark resolved
/// - `isAdminView = false` → user read-only view (their AI + admin replies)
class TicketDetailScreen extends StatefulWidget {
  final String ticketId;
  final bool isAdminView;
  const TicketDetailScreen({
    Key? key,
    required this.ticketId,
    this.isAdminView = false,
  }) : super(key: key);

  @override
  _TicketDetailScreenState createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  final TextEditingController _replyCtrl = TextEditingController();
  final ScrollController _scroll = ScrollController();
  bool _sending = false;
  bool _updatingStatus = false;

  @override
  void initState() {
    super.initState();
    // Reset unread counter for whichever side is viewing the ticket
    WidgetsBinding.instance.addPostFrameCallback((_) => _resetUnread());
  }

  Future<void> _resetUnread() async {
    try {
      await FirebaseFirestore.instance
          .collection('tickets')
          .doc(widget.ticketId)
          .update({
        widget.isAdminView ? 'adminUnread' : 'userUnread': 0,
      });
    } catch (_) {
      // ignore — may happen for brand-new tickets where field doesn't exist
    }
  }

  Future<void> _sendAdminReply() async {
    final text = _replyCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await FirestoreService.appendTicketMessage(
        ticketId: widget.ticketId,
        text: text,
        role: 'admin',
      );
      _replyCtrl.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to send: $e'),
          backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _setStatus(String status) async {
    setState(() => _updatingStatus = true);
    try {
      await FirestoreService.updateTicketStatus(widget.ticketId, status);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _updatingStatus = false);
    }
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'user':
        return const Color(0xFFB026FF);
      case 'admin':
        return const Color(0xFF00C853); // Green for human admin
      default:
        return const Color(0xFF16162C); // AI assistant
    }
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'user':
        return 'You';
      case 'admin':
        return 'Abhimaniu (Support)';
      default:
        return 'AI Manager';
    }
  }

  IconData _roleIcon(String role) {
    switch (role) {
      case 'user':
        return Icons.person;
      case 'admin':
        return Icons.verified_user;
      default:
        return Icons.smart_toy;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticketRef =
        FirebaseFirestore.instance.collection('tickets').doc(widget.ticketId);
    final maxBubbleWidth = MediaQuery.of(context).size.width * 0.75;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isAdminView ? 'Ticket (Admin)' : 'Ticket'),
        backgroundColor: Colors.transparent,
        actions: [
          if (widget.isAdminView)
            StreamBuilder<DocumentSnapshot>(
              stream: ticketRef.snapshots(),
              builder: (context, snap) {
                final status =
                    (snap.data?.data() as Map<String, dynamic>?)?['status'] ??
                        'Pending';
                return PopupMenuButton<String>(
                  icon: _updatingStatus
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white)),
                        )
                      : const Icon(Icons.flag),
                  onSelected: _setStatus,
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                        value: 'Pending', child: Text('Mark Pending')),
                    const PopupMenuItem(
                        value: 'In Progress',
                        child: Text('Mark In Progress')),
                    const PopupMenuItem(
                        value: 'Resolved', child: Text('Mark Resolved')),
                  ],
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Ticket header card
          StreamBuilder<DocumentSnapshot>(
            stream: ticketRef.snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Padding(
                    padding: EdgeInsets.all(16),
                    child: LinearProgressIndicator(
                        color: Color(0xFFB026FF)));
              }
              final t = snap.data!.data() as Map<String, dynamic>? ?? {};
              final status = t['status'] ?? 'Pending';
              final email = t['email'] ?? '';
              final issue = t['issue'] ?? '';
              Color statusColor = status == 'Resolved'
                  ? Colors.green
                  : (status == 'In Progress' ? Colors.blue : Colors.orange);

              return Container(
                width: double.infinity,
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: const Color(0xFF16162C),
                    borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(email,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: statusColor)),
                          child: Text(status,
                              style: TextStyle(
                                  color: statusColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Issue: $issue',
                        style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              );
            },
          ),
          // Messages
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: ticketRef
                  .collection('messages')
                  .orderBy('createdAt')
                  .snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFFB026FF)));
                }
                final docs = snap.data!.docs;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scroll.hasClients) {
                    _scroll.animateTo(
                        _scroll.position.maxScrollExtent,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut);
                  }
                });
                if (docs.isEmpty) {
                  return const Center(
                      child: Text('No messages yet.',
                          style: TextStyle(color: Colors.grey)));
                }
                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final m = docs[i].data() as Map<String, dynamic>;
                    final role = (m['role'] ?? 'assistant').toString();
                    final isUser = role == 'user';
                    return Align(
                      alignment:
                          isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxBubbleWidth),
                        child: Column(
                          crossAxisAlignment: isUser
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: 4, right: 4, top: 8, bottom: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(_roleIcon(role),
                                      size: 12,
                                      color: Colors.grey[400]),
                                  const SizedBox(width: 4),
                                  Text(_roleLabel(role),
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[400])),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: _roleColor(role),
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: isUser
                                      ? const Radius.circular(16)
                                      : Radius.zero,
                                  bottomRight: isUser
                                      ? Radius.zero
                                      : const Radius.circular(16),
                                ),
                              ),
                              child: Text(m['text'] ?? '',
                                  style:
                                      const TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (widget.isAdminView)
            Container(
              padding: const EdgeInsets.all(12),
              color: const Color(0xFF16162C),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _replyCtrl,
                      enabled: !_sending,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Type your admin reply...',
                        hintStyle: const TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none),
                        filled: true,
                        fillColor: Colors.black26,
                      ),
                      onSubmitted: (_) => _sendAdminReply(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FloatingActionButton(
                    onPressed: _sending ? null : _sendAdminReply,
                    mini: true,
                    backgroundColor: const Color(0xFF00C853),
                    child: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send, color: Colors.white),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _replyCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }
}
