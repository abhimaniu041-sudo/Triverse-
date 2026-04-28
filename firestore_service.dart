import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Save generated app metadata (now includes Firebase Storage URL + path)
  static Future<void> saveAppToVishnu({
    required String name,
    required String version,
    required String downloadUrl,
    required String storagePath,
    required int sizeBytes,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db.collection('apps').add({
      'userId': user.uid,
      'name': name,
      'version': version,
      'downloadUrl': downloadUrl,
      'storagePath': storagePath,
      'sizeBytes': sizeBytes,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Create a Support Ticket (top-level doc). Messages go in a subcollection.
  static Future<String?> createTicket(String issue) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _db.collection('tickets').add({
      'userId': user.uid,
      'email': user.email,
      'issue': issue,
      'status': 'Pending',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  /// Append a message to a ticket's `messages` subcollection.
  /// Roles: 'user' | 'assistant' (AI) | 'admin'
  static Future<void> appendTicketMessage({
    required String ticketId,
    required String text,
    required String role,
  }) async {
    final ref = _db.collection('tickets').doc(ticketId);
    await ref.collection('messages').add({
      'text': text,
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await ref.update({'lastMessageAt': FieldValue.serverTimestamp()});
  }

  /// Update a ticket's status (e.g. 'Pending' | 'Resolved' | 'In Progress').
  static Future<void> updateTicketStatus(String ticketId, String status) async {
    await _db.collection('tickets').doc(ticketId).update({'status': status});
  }
}
