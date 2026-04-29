import 'package:flutter/material.dart';

// Inka address badal gaya hai, isliye 'services/' lagana zaroori hai
import 'services/auth_service.dart';
import 'services/gemini_service.dart';
import 'services/support_chat_service.dart';

// Screens usi folder mein hain toh ye seedha rahega
import 'login_screen.dart'; 
import 'home_dashboard.dart';
import 'splash_screen.dart';

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
      theme: ThemeData.dark(), // Premium Gaming Look
      home: const SplashScreen(), // Pehle Splash dikhao
    );
  }
}
