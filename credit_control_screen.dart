import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

class CreditControlScreen extends StatefulWidget {
  const CreditControlScreen({Key? key}) : super(key: key);

  @override
  State<CreditControlScreen> createState() => _CreditControlScreenState();
}

class _CreditControlScreenState extends State<CreditControlScreen> {
  final _signupCtrl = TextEditingController();
  final _dailyCtrl = TextEditingController();
  final _maxCtrl = TextEditingController();
  final _appCtrl = TextEditingController();
  final _gameCtrl = TextEditingController();
  bool _loaded = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final doc = await FirebaseFirestore.instance
        .collection('config')
        .doc('global')
        .get();
    final data = doc.exists ? doc.data()! : <String, dynamic>{};
    _signupCtrl.text = (data['signupCredits'] ?? 7).toString();
    _dailyCtrl.text = (data['dailyReward'] ?? 2).toString();
    _maxCtrl.text = (data['maxLimit'] ?? 1000).toString();
    _appCtrl.text = (data['appCost'] ?? 100).toString();
    _gameCtrl.text = (data['gameCost'] ?? 70).toString();
    if (mounted) setState(() => _loaded = true);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final callable =
          FirebaseFunctions.instance.httpsCallable('adminUpdateConfig');
      await callable.call(<String, dynamic>{
        'signupCredits': int.tryParse(_signupCtrl.text),
        'dailyReward': int.tryParse(_dailyCtrl.text),
        'maxLimit': int.tryParse(_maxCtrl.text),
        'appCost': int.tryParse(_appCtrl.text),
        'gameCost': int.tryParse(_gameCtrl.text),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Global config updated!'),
          backgroundColor: Colors.green));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _signupCtrl.dispose();
    _dailyCtrl.dispose();
    _maxCtrl.dispose();
    _appCtrl.dispose();
    _gameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Credit Control'),
          backgroundColor: Colors.transparent),
      body: !_loaded
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFB026FF)))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Global Pricing & Limits',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _field('Signup free credits', _signupCtrl),
                _field('Daily reward credits', _dailyCtrl),
                _field('Usage cap per user (₹)', _maxCtrl),
                _field('App generator cost (credits)', _appCtrl),
                _field('Game generator cost (credits)', _gameCtrl),
                const SizedBox(height: 16),
                _saving
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFFB026FF)))
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFB026FF),
                            minimumSize: const Size(double.infinity, 50)),
                        onPressed: _save,
                        child: const Text('Save Changes',
                            style: TextStyle(color: Colors.white)),
                      ),
                const SizedBox(height: 32),
                const Text('Top 10 spenders',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _Leaderboard(),
              ],
            ),
    );
  }

  Widget _field(String label, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          filled: true,
          fillColor: const Color(0xFF16162C),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none),
        ),
      ),
    );
  }
}

class _Leaderboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .orderBy('totalUsageCost', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFFB026FF)));
        }
        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return const Text('No usage yet.',
              style: TextStyle(color: Colors.grey));
        }
        return Column(
          children: List.generate(docs.length, (i) {
            final m = docs[i].data() as Map<String, dynamic>;
            return Card(
              color: const Color(0xFF16162C),
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: i < 3
                      ? const Color(0xFFB026FF)
                      : Colors.grey[700],
                  child: Text('${i + 1}',
                      style: const TextStyle(color: Colors.white)),
                ),
                title: Text(m['email'] ?? 'Unknown',
                    style: const TextStyle(color: Colors.white)),
                subtitle: Text(
                    'Spent ₹${m['totalUsageCost'] ?? 0}  •  ${m['credits'] ?? 0} credits left',
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
                trailing: (m['isUsageBlocked'] == true)
                    ? const Icon(Icons.block, color: Colors.red)
                    : const Icon(Icons.check_circle,
                        color: Colors.greenAccent),
              ),
            );
          }),
        );
      },
    );
  }
}
