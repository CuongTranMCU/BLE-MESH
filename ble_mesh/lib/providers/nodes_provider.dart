import 'package:flutter/material.dart';

import '../models/data.dart';

class NodesProvider extends ChangeNotifier {
  // List of node in the floor which has been selected.
  Map<String, Data> _data = {};
  String _selectedFloor = "";

  Map<String, Data> get data => _data;
  String get selectedFloor => _selectedFloor;

  set selectedFloor(String newFloor) => _selectedFloor = newFloor;

  set data(Map<String, Data> newData) {
    _data = newData;

    notifyListeners();
  }
}
