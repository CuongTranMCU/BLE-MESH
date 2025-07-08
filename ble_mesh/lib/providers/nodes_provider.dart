import 'package:flutter/material.dart';

import '../models/monitor_data.dart';

class NodesProvider extends ChangeNotifier {
  // List of node in the floor which has been selected.
  Map<String, MonitorData> _data = {};
  String _selectedFloor = "";

  Map<String, MonitorData> get data => _data;
  String get selectedFloor => _selectedFloor;

  set selectedFloor(String newFloor) => _selectedFloor = newFloor;

  set data(Map<String, MonitorData> newData) {
    _data = newData;

    notifyListeners();
  }
}
