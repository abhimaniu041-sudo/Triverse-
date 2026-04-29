import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'home_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passController = TextEditingController();
  final AuthService _auth = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("COMMANDER LOGIN", style: TextStyle(color: Colors.red, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email', labelStyle: TextStyle(color: Colors.white))),
            TextField(controller: passController, obscureText: true, decoration: const InputDecoration(labelText: 'Password', labelStyle: TextStyle(color: Colors.white))),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                await _auth.login(context, emailController.text, passController.text);
                // Sirf testing ke liye direct navigate kar rahe hain:
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeDashboard()));
              },
              child: const Text("ACCESS SYSTEM", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
