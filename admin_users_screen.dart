import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({Key? key}) : super(key: key);

  void _manageUserDialog(
      BuildContext context, Map<String, dynamic> userData, String docId) {
    int addCredits = 0;
    bool isBlocked = userData['isUsageBlocked'] ?? false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF16162C),
            title: Text(userData['email'] ?? 'Unknown'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Current Credits: ${userData['credits']}',
                    style: const TextStyle(color: Colors.white)),
                Text('Total Usage: ₹${userData['totalUsageCost']}',
                    style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 16),
                TextField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Add Credits',
                      filled: true,
                      fillColor: Colors.black26),
                  onChanged: (val) => addCredits = int.tryParse(val) ?? 0,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Block User',
                      style: TextStyle(color: Colors.redAccent)),
                  value: isBlocked,
                  onChanged: (val) => setState(() => isBlocked = val),
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB026FF)),
                onPressed: () async {
                  try {
                    HttpsCallable callable = FirebaseFunctions.instance
                        .httpsCallable('adminManageUser');
                    await callable.call(<String, dynamic>{
                      'targetUid': userData['uid'] ?? docId,
                      'addCredits': addCredits,
                      'isBlocked': isBlocked,
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('User updated successfully!'),
                        backgroundColor: Colors.green));
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red));
                  }
                },
                child: const Text('Save Changes',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('User Management'),
          backgroundColor: Colors.transparent),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!.docs;
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              var userData = users[index].data() as Map<String, dynamic>;
              String docId = users[index].id;
              bool blocked = userData['isUsageBlocked'] ?? false;

              return Card(
                color: const Color(0xFF16162C),
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                      backgroundColor: blocked ? Colors.red : Colors.green,
                      child:
                          const Icon(Icons.person, color: Colors.white)),
                  title: Text(userData['email'] ?? 'Unknown User'),
                  subtitle: Text(
                      'Credits: ${userData['credits']} | Role: ${userData['role']}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, color: Color(0xFFB026FF)),
                    onPressed: () =>
                        _manageUserDialog(context, userData, docId),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
