import 'package:ble_mesh/ui/home/home.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../providers/user_provider.dart';
import 'authentication/authenticate.dart';

class MainNavigator extends StatelessWidget {
  const MainNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModels?>(context);
    return (user == null) ? const Authenticate() : const Home();
  }
}
