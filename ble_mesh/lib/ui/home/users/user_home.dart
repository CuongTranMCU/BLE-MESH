import 'package:ble_mesh/ui/home/users/user_list_of_floors.dart';
import 'package:flutter/material.dart';

import '../../../themes/mycolors.dart';

class UserHome extends StatelessWidget {
  const UserHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Home",
          style: TextStyle(color: AppTitleColor2, fontSize: 28, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: UserListOfFloors(context: context),
    );
  }
}
