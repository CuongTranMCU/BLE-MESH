import 'package:flutter/material.dart';

import '../models/data.dart';

class DataProvider extends ChangeNotifier {
  Data? _selectedData;
  String? _selectedNode;

  final Map<String, Data> _listNode = {};

  Data? get selectedData => _selectedData;
  String? get selectedNode => _selectedNode;
  Map<String, Data> get listNode => _listNode;

  set selectedNode(String? value) => _selectedNode = value;
  set selectedData(Data? newData) => _selectedData = newData;

  set listNode(Map<String, Data> newList) {
    _listNode.addAll(newList);
    notifyListeners();
  }
}
