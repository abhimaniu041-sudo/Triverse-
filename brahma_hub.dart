import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/gemini_service.dart';
import '../services/zip_service.dart';
import '../services/firestore_service.dart';
import '../providers/app_state.dart';

class BrahmaHub extends StatefulWidget {
  const BrahmaHub({Key? key}) : super(key: key);
  @override
  _BrahmaHubState createState() => _BrahmaHubState();
}

class _BrahmaHubState extends State<BrahmaHub>
    with SingleTickerProviderStateMixin {
  bool _isGenerating = false;
  String _statusMessage = '';
  final TextEditingController _promptCtrl = TextEditingController();
  late final AnimationController _fadeCtrl;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450))
      ..forward();
  }

  @override
  void dispose() {
    _promptCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleGeneration({
    required String kind, // 'app' | 'game'
    required int cost,
    required String defaultPrompt,
    required String appName,
  }) async {
    setState(() {
      _isGenerating = true;
      _statusMessage = 'Deducting Credits & Checking Limits...';
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      if (appState.credits < cost) {
        throw Exception('Not enough credits! Need $cost.');
      }

      final prompt =
          _promptCtrl.text.trim().isEmpty ? defaultPrompt : _promptCtrl.text.trim();

      setState(() => _statusMessage = 'Generating $kind with Gemini AI...');
      final code = await GeminiService.generateCode(
          context: context, prompt: prompt, credits: cost, kind: kind);

      if (code == null || code.isEmpty) {
        throw Exception('Failed to generate code.');
      }

      setState(() => _statusMessage = 'Packaging & uploading to cloud...');
      final result = await ZipService.createAndUploadZip(appName, code);
      if (result == null) throw Exception('Failed to upload ZIP.');

      await FirestoreService.saveAppToVishnu(
        name: appName,
        version: '1.0.0',
        downloadUrl: result.downloadUrl,
        storagePath: result.storagePath,
        sizeBytes: result.sizeBytes,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Success! $appName uploaded. Check Vishnu Hub to download.',
            style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 4),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text(e.toString(), style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _statusMessage = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Brahma - AI Creation Hub'),
          backgroundColor: Colors.transparent,
          elevation: 0),
      body: _isGenerating
          ? _buildProgress()
          : FadeTransition(
              opacity: _fadeCtrl,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    color: const Color(0xFF16162C),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Describe your creation',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _promptCtrl,
                            maxLines: 3,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.black26,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none),
                              hintText:
                                  'e.g. A Flutter fitness tracker with charts',
                              hintStyle: const TextStyle(color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildGeneratorCard(
                    icon: Icons.phone_android,
                    title: 'App Generator',
                    subtitle: 'Flutter apps, dashboards, trackers',
                    cost: 100,
                    accent: const Color(0xFFB026FF),
                    onTap: () => _handleGeneration(
                      kind: 'app',
                      cost: 100,
                      defaultPrompt:
                          'Write a complete Flutter ToDo App in a single main.dart file with a dark theme.',
                      appName: 'Generated App',
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildGeneratorCard(
                    icon: Icons.sports_esports,
                    title: 'Game Generator',
                    subtitle: 'Flutter Flame games, puzzles, arcade',
                    cost: 70,
                    accent: const Color(0xFF00E5FF),
                    onTap: () => _handleGeneration(
                      kind: 'game',
                      cost: 70,
                      defaultPrompt:
                          'Write a complete Flutter game in a single main.dart file. A simple tap-the-target arcade game with score tracking, dark neon theme, and smooth animations. Use only the stock flutter sdk, no external game engines.',
                      appName: 'Generated Game',
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProgress() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Color(0xFFB026FF)),
          const SizedBox(height: 20),
          Text(_statusMessage,
              style: const TextStyle(color: Colors.white, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildGeneratorCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required int cost,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF16162C),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withOpacity(0.4), width: 1),
          boxShadow: [
            BoxShadow(
                color: accent.withOpacity(0.15),
                blurRadius: 16,
                offset: const Offset(0, 6)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: accent, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(subtitle,
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(20)),
              child: Text('$cost',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
