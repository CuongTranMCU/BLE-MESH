import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../../providers/screen_ui_controller.dart';

class SendEmailSuccessfullyScreen extends StatelessWidget {
  const SendEmailSuccessfullyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Animation success checkmark
                Lottie.asset(
                  "assets/images/successful_check.json",
                  width: 200,
                  height: 200,
                  repeat: false,
                ),

                const SizedBox(height: 24.0),
                Text(
                  "Everything's verified and ready to go!",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 24.0,
                        color: const Color(0xFF3B5AFB),
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20.0),
                // Mô tả
                Text(
                  'Welcome to the BLE Mesh App',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18.0,
                        color: Colors.black87,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8.0),
                Text(
                  'Your verification has been completed.'
                  ' This app is designed to monitor and warn about fires in your building.\n'
                  'Hope you enjoy using it!\n',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                        fontSize: 16.0,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32.0),
                // Nút Continue
                ElevatedButton(
                  onPressed: () {
                    Provider.of<ScreenUiController>(context, listen: false).screen = Screen.HomeScreen;
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B5AFB),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(fontSize: 16.0),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
