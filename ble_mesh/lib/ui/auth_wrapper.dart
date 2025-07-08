import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../cloud_services/auth_service.dart';
import '../providers/screen_ui_controller.dart';
import 'main_navigator.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    final controller = Provider.of<ScreenUiController>(context, listen: false);
    final authService = AuthService();
    final userStream = authService.user;

    userStream.listen((user) {
      debugPrint("USER : $user");

      if (user == null) {
        controller.screen = Screen.LoginScreen;
      } else {
        if (user.emailVerify) {
          controller.screen = Screen.HomeScreen;
        } else {
          controller.screen = Screen.VerifyEmailScreen;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const MainNavigator();
  }
}
