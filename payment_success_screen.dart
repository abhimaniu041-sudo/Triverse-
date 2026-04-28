import 'package:flutter/material.dart';

class PaymentSuccessScreen extends StatelessWidget {
  final int creditsAdded;
  const PaymentSuccessScreen({Key? key, this.creditsAdded = 0})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle,
                  size: 120, color: Colors.greenAccent),
              const SizedBox(height: 30),
              const Text('Payment Successful!',
                  style: TextStyle(
                      fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(
                creditsAdded > 0
                    ? '+$creditsAdded credits added to your account'
                    : 'Credits added to your account',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 50),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB026FF),
                  minimumSize: const Size(200, 50),
                ),
                onPressed: () =>
                    Navigator.popUntil(context, ModalRoute.withName('/home')),
                child: const Text('Back to Home',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
