import 'package:ble_mesh/ui/home/admin/list_of_floors.dart';
import 'package:flutter/material.dart';

import 'create_floor.dart';

class AdminGroup extends StatelessWidget {
  const AdminGroup({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint("Có build lại ở admin group không ?");

    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin group"),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(
          Icons.add,
          color: Colors.black,
        ),
        backgroundColor: Colors.white,
        shape: const CircleBorder(),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => CreateFloor()));
        },
      ),
      body: ListOfFloors(context: context),
    );
  }
}
