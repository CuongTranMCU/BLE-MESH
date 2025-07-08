import 'package:ble_mesh/themes/mycolors.dart';
import 'package:ble_mesh/ui/home/admin/admin_group/create_group.dart';
import 'package:ble_mesh/ui/home/admin/admin_group/list_of_floors.dart';
import 'package:flutter/material.dart';

class AdminGroup extends StatelessWidget {
  const AdminGroup({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint("Có build lại ở admin group không ?");

    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin group", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        centerTitle: true,
        foregroundColor: AppTitleColor2,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: NavigationBarColor,
        shape: const CircleBorder(),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => CreateGroup()));
        },
        child: const Icon(Icons.add, color: IconColor03, size: 32),
      ),
      body: ListOfFloors(context: context),
    );
  }
}
