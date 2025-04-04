import 'package:flutter/material.dart';

import 'select_node.dart';

class CreateFloor extends StatefulWidget {
  const CreateFloor({super.key});

  @override
  State<CreateFloor> createState() => _CreateFloorState();
}

class _CreateFloorState extends State<CreateFloor> {
  final _floorController = TextEditingController();

  @override
  void dispose() {
    _floorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Floor"),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _floorController,
              keyboardType: TextInputType.text,
              decoration: const InputDecoration(
                labelText: "Floor number",
                hintText: "1st Floor",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _navigateToSelectNode,
              child: const Text("Next"),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToSelectNode() {
    final floorText = _floorController.text.trim();
    if (floorText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Floor number cannot be empty")),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SelectNode(floorNumber: floorText)),
    );
  }
}
