import 'package:ble_mesh/themes/mycolors.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../../cloud_services/auth_service.dart';
import '../../providers/screen_ui_controller.dart';
import '../../providers/verify_email_controller.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  _VerifyEmailScreenState createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  late VerifyEmailController _verifyEmailController;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _verifyEmailController = context.read<VerifyEmailController>();
    _verifyEmailController.sendEmailVerification();
    _verifyEmailController.setTimerForAutoRedirect();
  }

  @override
  void dispose() {
    _verifyEmailController.cancelTimer();
    super.dispose();
  }

  void _resendEmail() {
    _verifyEmailController.sendEmailVerification();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Verification email resent')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: IconButton(
              icon: const Icon(
                Icons.clear_outlined,
                size: 32,
                color: Colors.black,
              ),
              onPressed: () {
                AuthService().signOut();
              },
            ),
          )
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Lottie.asset(
                'assets/images/email_verification.json',
                width: 200,
                height: 200,
              ),
              const SizedBox(height: 24.0),
              Text(
                'Check Your Email',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: TextColor04),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16.0),
              Text(
                'We’ve sent a verification link to your email address!\n'
                'Please click the link to verify your account.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: TextColor03, fontStyle: FontStyle.italic, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32.0),
              Consumer<VerifyEmailController>(
                builder: (context, verifyEmailController, child) {
                  return Column(
                    children: [
                      ElevatedButton(
                        onPressed: !verifyEmailController.verificationStatus
                            ? null
                            : () {
                                Provider.of<ScreenUiController>(context, listen: false).screen = Screen.SendingSuccessfullyScreen;
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ButtonColor01,
                          disabledBackgroundColor: DisabledBackgroundColor,
                          disabledForegroundColor: DisableForegroundColor,
                          foregroundColor: TextColor02,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: const Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      TextButton(
                        onPressed: verifyEmailController.canResend ? _resendEmail : null,
                        child: const Text(
                          'Resend Email',
                          style: TextStyle(fontSize: 16.0),
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (!verifyEmailController.canResend && !verifyEmailController.verificationStatus)
                        Text(
                          '${verifyEmailController.countDown} seconds',
                          style: TextStyle(
                            color: ErrorTextColor,
                            fontSize: 14.0,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
