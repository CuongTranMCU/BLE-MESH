import 'package:ble_mesh/ui/authentication/signup.dart';
import 'package:flutter/material.dart';

import 'login.dart';

class Authenticate extends StatefulWidget {
  const Authenticate({super.key});

  @override
  _AuthenticateState createState() => _AuthenticateState();
}

class _AuthenticateState extends State<Authenticate> {
  bool showLogin = true;

  void toggleView() {
    setState(() => (showLogin = !showLogin));
  }

  @override
  Widget build(BuildContext context) {
    return (showLogin) ? Login(toggleView: toggleView) : Signup(toggleView: toggleView);
  }
}
