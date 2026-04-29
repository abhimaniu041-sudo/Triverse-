import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// Agar FcmService bahaar hai toh 'import '../fcm_service.dart';' dalo
// Lekin abhi ke liye ise safe rakhne ke liye error handle kar lete hain

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> login(BuildContext context, String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      debugPrint("Auth Error: ${e.message}");
    }
  }
}
