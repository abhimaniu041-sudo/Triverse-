import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:audioplayers/audioplayers.dart';
import '../main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..forward();

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      if (!firebaseReady) {
        // Stay on splash so the config-hint banner is visible.
        return;
      }
      final user = FirebaseAuth.instance.currentUser;
      Navigator.pushReplacementNamed(context, user != null ? '/home' : '/login');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: FadeTransition(
              opacity: _controller,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.change_history,
                      size: 100, color: Color(0xFFB026FF)),
                  const SizedBox(height: 20),
                  const Text(
                    'TRIVERSE',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 4,
                      shadows: [Shadow(color: Color(0xFFB026FF), blurRadius: 20)],
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text('Powered by Abhimaniu',
                      style: TextStyle(color: Colors.grey, fontSize: 14)),
                ],
              ),
            ),
          ),
          if (!firebaseReady)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.redAccent),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning, color: Colors.redAccent),
                        SizedBox(width: 8),
                        Text('Firebase not configured',
                            style: TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    SizedBox(height: 6),
                    Text(
                      'This APK is built without real Firebase credentials.\n'
                      '1. Download google-services.json from Firebase Console\n'
                      '2. Commit it at android/app/google-services.json\n'
                      '3. Fill lib/firebase_options.dart\n'
                      '4. Re-run the GitHub workflow',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
