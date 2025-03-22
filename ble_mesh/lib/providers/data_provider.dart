import 'package:flutter/material.dart';

import '../models/data.dart';

class DataProvider extends ChangeNotifier {
  Data? _currentData;

  Data? get currentData => _currentData;

  void updateData(Data newData) {
    _currentData = newData;
    notifyListeners(); // Cập nhật toàn bộ widget đang listen
  }
}
