import 'package:ble_mesh/ui/home/admin/list_of_floors.dart';
import 'package:flutter/material.dart';

class UserHome extends StatelessWidget {
  const UserHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Home"),
        centerTitle: true,
      ),
      body: ListOfFloors(context: context),
    );
  }
}
