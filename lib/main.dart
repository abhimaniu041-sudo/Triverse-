import 'package:flutter/material.dart';
// Baaki imports...

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Agar Firebase use kar rahe ho toh initialize yahan hoga
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TriVerse',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(), // Aapka premium dark theme
      home: const SplashScreen(), // Ya jo bhi aapka pehla screen hai
    );
  }
}
