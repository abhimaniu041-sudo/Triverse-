import 'package:flutter/material.dart';

// Agar aapne SplashScreen banaya hai toh uska import yahan aayega
// import 'splash_screen.dart'; 

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
        primaryColor: Colors.black,
        scaffoldBackgroundColor: Colors.black,
      ),
      // Yahan home mein wo screen dalo jo aapne banayi hai
      // Agar SplashScreen nahi mil raha toh Placeholder use karo temporary
      home: const Scaffold(
        body: Center(
          child: Text(
            'TriVerse Loading...',
            style: TextStyle(color: Colors.red, fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
