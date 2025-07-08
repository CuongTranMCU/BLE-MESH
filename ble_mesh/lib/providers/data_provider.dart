import 'package:flutter/material.dart';

import '../models/monitor_data.dart';

class DataProvider extends ChangeNotifier {
  MonitorData? _selectedData;
  String? _selectedNode;

  final Map<String, MonitorData> _listNode = {};

  MonitorData? get selectedData => _selectedData;
  String? get selectedNode => _selectedNode;
  Map<String, MonitorData> get listNode => _listNode;

  set selectedNode(String? value) => _selectedNode = value;
  set selectedData(MonitorData? newData) => _selectedData = newData;

  set listNode(Map<String, MonitorData> newList) {
    _listNode.addAll(newList);
    notifyListeners();
  }
}
