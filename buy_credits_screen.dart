import 'package:flutter/material.dart';
import 'payment_screen.dart';

class BuyCreditsScreen extends StatelessWidget {
  const BuyCreditsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Buy Credits'),
          backgroundColor: Colors.transparent),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildPlanCard(context, '₹50', '100 Credits', 'Max 3/Month'),
          _buildPlanCard(context, '₹100', '220 Credits', 'Max 3/Month'),
          _buildPlanCard(context, '₹200', '450 Credits', 'Max 3/Month'),
          _buildPlanCard(context, '₹500', '1000 Credits', 'Unlimited',
              isPopular: true),
        ],
      ),
    );
  }

  Widget _buildPlanCard(
      BuildContext context, String price, String credits, String limit,
      {bool isPopular = false}) {
    return Card(
      color: const Color(0xFF16162C),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isPopular
            ? const BorderSide(color: Color(0xFFB026FF), width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isPopular)
                  const Text('POPULAR',
                      style: TextStyle(
                          color: Color(0xFFB026FF),
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                Text(price,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold)),
                Text(credits,
                    style: const TextStyle(
                        color: Color(0xFF00E5FF), fontWeight: FontWeight.bold)),
                Text(limit,
                    style:
                        const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB026FF)),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            PaymentScreen(price: price, credits: credits)));
              },
              child: const Text('Buy',
                  style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }
}
