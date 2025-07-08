import 'package:ble_mesh/providers/screen_ui_controller.dart';
import 'package:ble_mesh/ui/authentication/reset_password_screen.dart';
import 'package:ble_mesh/ui/authentication/send_email_successfully_screen.dart';
import 'package:ble_mesh/ui/authentication/verify_email_screen.dart';
import 'package:ble_mesh/ui/home/home.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/loading.dart';
import 'authentication/login_screen.dart';
import 'authentication/signup_screen.dart';

class MainNavigator extends StatelessWidget {
  const MainNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ScreenUiController>(builder: (context, screenController, child) {
      final screen = screenController.screen;
      switch (screen) {
        case Screen.LoginScreen:
          return const LoginScreen();
        case Screen.SignupScreen:
          return const SignupScreen();
        case Screen.VerifyEmailScreen:
          return const VerifyEmailScreen();
        case Screen.SendingSuccessfullyScreen:
          return const SendEmailSuccessfullyScreen();
        case Screen.ResetPasswordScreen:
          return const ResetPasswordScreen();
        case Screen.HomeScreen:
          return const Home();
        default:
          return Loading();
      }
    });
  }
}
