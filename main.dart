import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_layout.dart';
import 'providers/app_state.dart';

void main() {
  // 1. Flutter Engine ko initialize karna zaruri hai
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(
    MultiProvider(
      providers: [
        // 2. Aapka state management provider
        ChangeNotifierProvider(create: (_) => AppState()),
      ],
      child: const TriVerseApp(),
    ),
  );
}

class TriVerseApp extends StatelessWidget {
  const TriVerseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TriVerse',
      debugShowCheckedModeBanner: false,
      
      // 3. Theme Setting (Dark Theme for Premium Gaming Style)
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A1A),
        primaryColor: const Color(0xFFB026FF),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFB026FF),
          secondary: Color(0xFF00E5FF),
          surface: Color(0xFF16162C),
        ),
      ),

      // 4. Routes Setup (Firebase calls hata diye hain crash rokne ke liye)
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const MainLayout(),
      },
    );
  }
}