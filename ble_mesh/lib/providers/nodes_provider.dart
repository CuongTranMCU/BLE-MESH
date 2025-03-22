import 'package:flutter/material.dart';

import '../models/data.dart';

class NodesProvider extends ChangeNotifier {
  Map<String, dynamic> _data = {};

  Map<String, dynamic> get data => _data;

  set data(Map<String, dynamic> newData) {
    _data = newData;

    notifyListeners();
  }

  Map<String, Data> getNodes(List<dynamic> nodes) {
    Map<String, Data> result = {};

    for (var name in nodes) {
      if (_data[name]["Now"] != null) {
        result[name] = Data.fromRTDB(_data[name]["Now"]);
      }
    }

    return result;
  }
}
