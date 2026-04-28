import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class VishnuHub extends StatelessWidget {
  const VishnuHub({Key? key}) : super(key: key);

  Future<void> _openDownload(BuildContext context, String url) async {
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No download URL available.'),
          backgroundColor: Colors.red));
      return;
    }
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not open: $url'),
          backgroundColor: Colors.red));
    }
  }

  String _formatSize(int? bytes) {
    if (bytes == null || bytes == 0) return '—';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Vishnu - App/Game Hub'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          bottom: const TabBar(
            indicatorColor: Color(0xFFB026FF),
            tabs: [
              Tab(text: 'My Apps'),
              Tab(text: 'My Games'),
              Tab(text: 'Files'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('apps')
                  .where('userId', isEqualTo: currentUser?.uid)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFFB026FF)));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text('No Apps Generated Yet.',
                          style: TextStyle(color: Colors.grey)));
                }

                final apps = snapshot.data!.docs;
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: apps.length,
                  itemBuilder: (context, index) {
                    final appData =
                        apps[index].data() as Map<String, dynamic>;
                    // Backward compat: older docs used `fileUrl` (local path)
                    final downloadUrl = (appData['downloadUrl'] ??
                            appData['fileUrl'] ??
                            '')
                        .toString();
                    final size = appData['sizeBytes'] as int?;
                    return Card(
                      color: const Color(0xFF16162C),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const Icon(Icons.cloud_download,
                            color: Colors.blueAccent),
                        title: Text(appData['name'] ?? 'Unknown App'),
                        subtitle: Text(
                          'v${appData['version'] ?? '1.0.0'}  •  ${_formatSize(size)}',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.download,
                              color: Color(0xFFB026FF)),
                          onPressed: () => _openDownload(context, downloadUrl),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const Center(
                child: Text('Games will appear here',
                    style: TextStyle(color: Colors.grey))),
            const Center(
                child: Text('Downloaded ZIP files storage',
                    style: TextStyle(color: Colors.grey))),
          ],
        ),
      ),
    );
  }
}
