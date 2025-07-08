import 'package:flutter/material.dart';

import '../../../../themes/mycolors.dart';
import 'select_node.dart';

class CreateGroup extends StatefulWidget {
  const CreateGroup({super.key});

  @override
  State<CreateGroup> createState() => _CreateGroupState();
}

class _CreateGroupState extends State<CreateGroup> {
  final _floorController = TextEditingController();
  final FocusNode _groupFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _groupFocusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _floorController.dispose();
    _groupFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isFocused = _groupFocusNode.hasFocus;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Create Group",
          style: TextStyle(color: AppTitleColor2, fontSize: 28, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          color: AppTitleColor2,
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/icons/BLE_mesh.png',
              width: 150,
              height: 150,
              fit: BoxFit.cover,
              color: IconColor04,
            ),
            SizedBox(height: 120),
            TextField(
              controller: _floorController,
              focusNode: _groupFocusNode,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                labelText: "Group name",
                hintText: "1st Floor",
                border: InputBorder.none,
                hintStyle: const TextStyle(color: TextColor01),
                filled: true,
                fillColor: isFocused ? FocusedColor : EnabledBorderColor,
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: const BorderSide(color: FocusedBorderColor, width: 2.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: const BorderSide(color: EnabledBorderColor, width: 1.2),
                ),
                errorStyle: const TextStyle(color: ErrorTextColor),
              ),
              style: const TextStyle(color: TextColor01),
              onEditingComplete: () {
                FocusScope.of(context).unfocus(); // Hide keyboard
                print("Editing completed!");
              },
              onSubmitted: (String value) {
                print("OnSubmitted completed!");
                _navigateToSelectNode();
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                fixedSize: const Size(200, 50),
                backgroundColor: ButtonColor01,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: _navigateToSelectNode,
              child: const Text("Next", style: TextStyle(color: TextColor02, fontWeight: FontWeight.bold)),
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
      MaterialPageRoute(
        builder: (context) => SelectNode(
          floorNumber: floorText,
          isInFloorInfo: false,
        ),
      ),
    );
  }
}
