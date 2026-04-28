import 'package:flutter/material.dart';
import '../services/payment_service.dart';
import 'payment_success_screen.dart';

class PaymentScreen extends StatefulWidget {
  final String price;   // "₹500"
  final String credits; // "1000 Credits"
  const PaymentScreen({Key? key, required this.price, required this.credits})
      : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late final PaymentService _service;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _service = PaymentService();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  int _parseRupees() {
    final digits = widget.price.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 0;
  }

  int _parseCredits() {
    final digits =
        widget.credits.split(' ').first.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 0;
  }

  Future<void> _pay() async {
    final amount = _parseRupees();
    final credits = _parseCredits();
    if (amount == 0 || credits == 0) return;

    setState(() => _processing = true);
    await _service.startPayment(
      context: context,
      amountRupees: amount,
      creditsToAdd: credits,
      planLabel: '${widget.credits} Plan',
      onSuccess: (added) {
        if (!mounted) return;
        setState(() => _processing = false);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => PaymentSuccessScreen(creditsAdded: added)),
        );
      },
      onError: (reason) {
        if (!mounted) return;
        setState(() => _processing = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(reason), backgroundColor: Colors.red));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Payment'),
          backgroundColor: Colors.transparent),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Order Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _row('Plan', widget.credits),
            _row('Amount', widget.price),
            const Divider(color: Colors.grey, height: 40),
            const Text('Pay via Razorpay',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'Supports UPI, Cards, NetBanking & Wallets.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF16162C),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFB026FF), width: 1),
              ),
              child: Row(
                children: const [
                  Icon(Icons.lock, color: Color(0xFF00E5FF)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Secure checkout powered by Razorpay. Your card details never touch our servers.',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            _processing
                ? const Center(
                    child:
                        CircularProgressIndicator(color: Color(0xFFB026FF)))
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB026FF),
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _pay,
                    child: Text('Pay ${widget.price}',
                        style: const TextStyle(
                            fontSize: 18, color: Colors.white)),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
