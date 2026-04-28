import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import 'daily_reward_screen.dart';
import 'buy_credits_screen.dart';
import 'support_hub_screen.dart';

class HomeDashboard extends StatelessWidget {
  const HomeDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Hello, Creator 👋'),
        actions: [
          IconButton(
            icon: const Icon(Icons.card_giftcard, color: Colors.orangeAccent),
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const DailyRewardScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.support_agent),
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SupportHubScreen()));
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: const Color(0xFF4A148C),
                  borderRadius: BorderRadius.circular(16)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Your Credits',
                          style: TextStyle(color: Colors.white70)),
                      Text('${appState.credits}',
                          style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const BuyCreditsScreen()));
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFB026FF)),
                        child: const Text('Buy Credits',
                            style: TextStyle(color: Colors.white)),
                      )
                    ],
                  ),
                  const Icon(Icons.monetization_on,
                      size: 80, color: Colors.amber),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Quick Access',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: [
                  _buildQuickCard(
                      context: context,
                      title: 'Brahma',
                      sub: 'AI Creation Hub',
                      icon: Icons.auto_awesome,
                      color: Colors.purple,
                      onTap: () => MainLayout.of(context)?.switchTab(1)),
                  _buildQuickCard(
                      context: context,
                      title: 'Vishnu',
                      sub: 'App/Game Hub',
                      icon: Icons.apps,
                      color: Colors.blue,
                      onTap: () => MainLayout.of(context)?.switchTab(2)),
                  _buildQuickCard(
                      context: context,
                      title: 'Shiva',
                      sub: 'Control Panel',
                      icon: Icons.admin_panel_settings,
                      color: Colors.green,
                      onTap: () => MainLayout.of(context)?.switchTab(3)),
                  _buildQuickCard(
                      context: context,
                      title: 'Rewards',
                      sub: 'Daily Bonus',
                      icon: Icons.card_giftcard,
                      color: Colors.orange,
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const DailyRewardScreen()))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickCard({
    required BuildContext context,
    required String title,
    required String sub,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
            color: const Color(0xFF16162C),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.25))),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color),
              const Spacer(),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              Text(sub,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}
