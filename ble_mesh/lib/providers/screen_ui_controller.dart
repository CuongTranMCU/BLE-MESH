import 'package:flutter/material.dart';

enum Screen {
  LoginScreen,
  SignupScreen,
  VerifyEmailScreen,
  SendingSuccessfullyScreen,
  ResetPasswordScreen,
  HomeScreen,
  LoadingScreen,
}

class ScreenUiController extends ChangeNotifier {
  Screen _screen = Screen.LoadingScreen;
  bool _isLoading = false;

  Screen get screen => _screen;
  bool get isLoading => _isLoading;

  set screen(Screen newScreen) {
    _screen = newScreen;
    notifyListeners();
  }

  set isLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
