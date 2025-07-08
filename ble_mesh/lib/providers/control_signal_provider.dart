import 'dart:async';
import 'package:flutter/material.dart';

import '../cloud_services/rtdb_service_ble.dart';
import '../models/control_data.dart';
import '../models/monitor_data.dart';

class ControlSignalProvider extends ChangeNotifier {
  final RTDBServiceBLE _controlStream = RTDBServiceBLE();
  StreamSubscription<List<ControlData>>? _controlBuzzerSubscription;
  StreamSubscription<List<ControlData>>? _controlLedSubscription;

  List<ControlData> _controlDataList = [];

  List<ControlData> get controlDataList => _controlDataList;

  void initialize(Map<String, MonitorData> data) {
    _controlBuzzerSubscription?.cancel();
    _controlLedSubscription?.cancel();

    _controlBuzzerSubscription = _controlStream.getListControlBuzzerSignal().listen((controlData) {
      _controlDataList = controlData.where((ctrl) => data.keys.contains(ctrl.deviceName)).toList();
      notifyListeners();
    });

    _controlLedSubscription = _controlStream.getListControlLedStatus().listen((controlData) {
      for (final newCtrl in controlData) {
        final index = _controlDataList.indexWhere((c) => c.deviceName == newCtrl.deviceName);
        if (index != -1) {
          final existing = _controlDataList[index];
          _controlDataList[index] = existing.copyWith(ledRGBSignal: newCtrl.ledRGBSignal);
        }
      }
      notifyListeners();
    });
  }

  /// Lấy một ControlData theo địa chỉ MAC
  ControlData? getOneNode(String deviceName) {
    for (final ctrl in _controlDataList) {
      if (ctrl.deviceName == deviceName) return ctrl;
    }
    return null;
  }

  Future<void> changeBuzzerSignal({
    String deviceName = "-1",
    String meshAddress = "-1",
    required bool buzzerSignal,
  }) async {
    try {
      ControlData controlData = ControlData(
        deviceName: deviceName,
        meshAddress: meshAddress,
        buzzerSignal: buzzerSignal,
        ledRGBSignal: null,
      );
      await _controlStream.changeBuzzerSignal(
        node: deviceName,
        json: controlData,
      );
    } catch (e) {
      debugPrint("Error changing Buzzer signal for node $deviceName: $e");
    }
  }

  Future<void> changeLedStatus({
    String deviceName = "-1",
    String meshAddress = "-1",
    required List<bool> ledSignal,
  }) async {
    try {
      ControlData controlData = ControlData(
        deviceName: deviceName,
        meshAddress: meshAddress,
        buzzerSignal: null,
        ledRGBSignal: ledSignal,
      );
      await _controlStream.changeLedStatus(
        node: deviceName,
        json: controlData,
      );
    } catch (e) {
      debugPrint("Error changing Led for node $deviceName: $e");
    }
  }

  @override
  void dispose() {
    _controlBuzzerSubscription?.cancel();
    _controlLedSubscription?.cancel();
    super.dispose();
  }
}
