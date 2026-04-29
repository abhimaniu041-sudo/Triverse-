import 'package:flutter/material.dart';
// Yahan apne screens ko import karo (Check karo ki file name yahi hain na)
import 'login_screen.dart'; 
import 'home_dashboard.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TriVerse',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.red, // Gaming theme
      ),
      // 'Loading' Text hata kar asli LoginScreen yahan dalo
      home: const LoginScreen(), 
    );
  }
}
