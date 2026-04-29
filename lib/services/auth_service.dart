import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User?> signup(String email, String password) async {
    try {
      final res = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return res.user;
    } on FirebaseAuthException catch (e) {
      print(e.message);
      return null;
    }
  }

  Future<User?> login(String email, String password) async {
    try {
      final res = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return res.user;
    } on FirebaseAuthException catch (e) {
      print(e.message);
      return null;
    }
  }
}
