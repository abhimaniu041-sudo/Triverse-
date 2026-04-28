import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';

class DailyRewardScreen extends StatefulWidget {
  const DailyRewardScreen({Key? key}) : super(key: key);

  @override
  _DailyRewardScreenState createState() => _DailyRewardScreenState();
}

class _DailyRewardScreenState extends State<DailyRewardScreen> {
  bool _isLoading = false;

  Future<void> _claimReward() async {
    setState(() => _isLoading = true);
    try {
      HttpsCallable callable =
          FirebaseFunctions.instance.httpsCallable('claimDailyReward');
      final result = await callable.call();

      if (result.data['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(result.data['message'] ?? 'Reward claimed!'),
            backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      String errorMsg = e.toString();
      if (e is FirebaseFunctionsException && e.code == 'already-exists') {
        errorMsg = 'Aap aaj ka reward pehle hi le chuke hain!';
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Daily Reward'),
          backgroundColor: Colors.transparent),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.card_giftcard,
                  size: 100, color: Colors.orangeAccent),
              const SizedBox(height: 24),
              const Text('Congratulations!',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const SizedBox(height: 12),
              const Text('You earned',
                  style: TextStyle(fontSize: 16, color: Colors.grey)),
              const Text('2 Credits',
                  style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00E5FF))),
              const SizedBox(height: 40),
              _isLoading
                  ? const CircularProgressIndicator(color: Color(0xFFB026FF))
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB026FF),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _claimReward,
                      child: const Text('Claim Reward',
                          style: TextStyle(
                              fontSize: 18, color: Colors.white)),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
