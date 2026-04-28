import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppState extends ChangeNotifier {
  int credits = 0;
  int totalUsageCost = 0;
  String role = 'user';
  bool isLoading = false;

  AppState() {
    _listenToUser();
  }

  void _listenToUser() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots()
            .listen((doc) {
          if (doc.exists) {
            credits = doc.data()?['credits'] ?? 0;
            totalUsageCost = doc.data()?['totalUsageCost'] ?? 0;
            role = doc.data()?['role'] ?? 'user';
            notifyListeners();
          }
        });
      }
    });
  }
}
