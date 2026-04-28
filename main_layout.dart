import 'package:flutter/material.dart';
import '../services/fcm_service.dart';
import 'home_dashboard.dart';
import 'brahma_hub.dart';
import 'vishnu_hub.dart';
import 'shiva_panel.dart';

/// Lets any child widget switch the bottom-nav tab by looking up
/// `MainLayout.of(context)?.switchTab(index)`.
class MainLayout extends StatefulWidget {
  const MainLayout({Key? key}) : super(key: key);

  static _MainLayoutState? of(BuildContext context) =>
      context.findAncestorStateOfType<_MainLayoutState>();

  @override
  _MainLayoutState createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  void switchTab(int index) {
    if (index >= 0 && index < 4) {
      setState(() => _currentIndex = index);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FcmService.handleInitialMessage();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = const [
      HomeDashboard(),
      BrahmaHub(),
      VishnuHub(),
      ShivaPanel(),
    ];
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: switchTab,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF0A0A1A),
        selectedItemColor: const Color(0xFFB026FF),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.auto_awesome), label: 'Brahma'),
          BottomNavigationBarItem(icon: Icon(Icons.apps), label: 'Vishnu'),
          BottomNavigationBarItem(
              icon: Icon(Icons.admin_panel_settings), label: 'Shiva'),
        ],
      ),
    );
  }
}
