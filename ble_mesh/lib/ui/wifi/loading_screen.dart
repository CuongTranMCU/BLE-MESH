import 'package:flutter/material.dart';
import 'package:loading_indicator/loading_indicator.dart';

class LoadingScreen extends StatelessWidget {
  final VoidCallback onCancel;

  const LoadingScreen({super.key, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(
              width: 48,
              height: 48,
              child: LoadingIndicator(
                indicatorType: Indicator.ballPulseSync,
                colors: [
                  Color(0xFFFEE97E),
                ],
              ),
            ),
            Image.asset("assets/images/pokemon.gif", width: 120, height: 120, fit: BoxFit.cover),
            const SizedBox(height: 20),
            const Text(
              "Provisioning in progress... Please wait",
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.normal, fontSize: 14),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                onCancel(); // Hủy provisioning
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFEE97E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Colors.black, width: 1.5),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              ),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Color(0xFFFef7d7), fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
