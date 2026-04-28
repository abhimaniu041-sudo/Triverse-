import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/auth_service.dart';
import 'admin_users_screen.dart';
import 'admin_tickets_screen.dart';
import 'admin_dashboard_screen.dart';
import 'credit_control_screen.dart';
import 'ai_logs_screen.dart';
import 'my_tickets_screen.dart';

class ShivaPanel extends StatelessWidget {
  const ShivaPanel({Key? key}) : super(key: key);

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16162C),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to exit?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(context);
              await AuthService().logout(context);
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isAdmin = appState.role == 'admin';

    return Scaffold(
      appBar: AppBar(
          title: const Text('Shiva - Control Panel'),
          backgroundColor: Colors.transparent),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _buildCard(context, Icons.dashboard, 'Dashboard', Colors.blue,
              isAdmin
                  ? () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AdminDashboardScreen()))
                  : null),
          _buildCard(context, Icons.people, 'Users', Colors.purple,
              isAdmin
                  ? () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const AdminUsersScreen()))
                  : null),
          _ticketsCard(context, isAdmin),
          _buildCard(context, Icons.monetization_on, 'Credit Control',
              Colors.amber,
              isAdmin
                  ? () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CreditControlScreen()))
                  : null),
          _buildCard(context, Icons.history, 'AI Logs', Colors.orange,
              isAdmin
                  ? () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const AiLogsScreen()))
                  : null),
          _buildCard(context, Icons.logout, 'Logout', Colors.red,
              () => _handleLogout(context)),
        ],
      ),
    );
  }

  /// Tickets card with live unread badge.
  Widget _ticketsCard(BuildContext context, bool isAdmin) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    Stream<int> unreadStream;
    if (isAdmin) {
      // total adminUnread across all tickets
      unreadStream = FirebaseFirestore.instance
          .collection('tickets')
          .snapshots()
          .map((s) => s.docs.fold<int>(
              0,
              (a, d) =>
                  a + (((d.data())['adminUnread'] ?? 0) as num).toInt()));
    } else {
      unreadStream = FirebaseFirestore.instance
          .collection('tickets')
          .where('userId', isEqualTo: uid)
          .snapshots()
          .map((s) => s.docs.fold<int>(
              0,
              (a, d) =>
                  a + (((d.data())['userUnread'] ?? 0) as num).toInt()));
    }

    return StreamBuilder<int>(
      stream: unreadStream,
      builder: (context, snap) {
        final count = snap.data ?? 0;
        return _buildCard(
          context,
          Icons.inbox,
          isAdmin ? 'All Tickets' : 'My Tickets',
          Colors.cyan,
          () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => isAdmin
                        ? const AdminTicketsScreen()
                        : const MyTicketsScreen()));
          },
          badge: count,
        );
      },
    );
  }

  Widget _buildCard(BuildContext context, IconData icon, String title,
      Color color, VoidCallback? onTap,
      {int badge = 0}) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            decoration: BoxDecoration(
              color: const Color(0xFF16162C),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: onTap == null
                      ? Colors.transparent
                      : color.withOpacity(0.25)),
              boxShadow: onTap == null
                  ? null
                  : [
                      BoxShadow(
                          color: color.withOpacity(0.15),
                          blurRadius: 14,
                          offset: const Offset(0, 6))
                    ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 40, color: color),
                const SizedBox(height: 12),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                if (onTap == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text('(admin only)',
                        style: TextStyle(fontSize: 10, color: Colors.grey)),
                  ),
              ],
            ),
          ),
          if (badge > 0)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                constraints:
                    const BoxConstraints(minWidth: 22, minHeight: 22),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x66FF1744),
                        blurRadius: 8,
                        spreadRadius: 1),
                  ],
                ),
                child: Text(
                  badge > 99 ? '99+' : '$badge',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
