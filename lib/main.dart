import 'package:flutter/material.dart';

void main() {
  runApp(const TriVerseApp());
}

class TriVerseApp extends StatelessWidget {
  const TriVerseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TriVerse',
      theme: ThemeData.dark(),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("TriVerse"),
      ),
      body: const Center(
        child: Text(
          "🔥 TriVerse Running Successfully",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
