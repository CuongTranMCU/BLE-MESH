import 'package:ble_mesh/database_services/hive_boxes.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';

import '../widgets/constant_values.dart';

class MqttData {
  final hiveBox = Hive.box(mqttBox);

  String mqttHostName = "";
  String mqttPort = "";
  String mqttUserName = "";
  String mqttPassword = "";

  HostLabel mqttHost = HostLabel.mqtt;

  MqttData() {
    if (hiveBox.isNotEmpty) {
      final String? hostProtocol = hiveBox.get("mqttHost");

      mqttHostName = hiveBox.get("mqttHostName", defaultValue: "") ?? "";
      mqttPort = hiveBox.get("mqttPort", defaultValue: "") ?? "";
      mqttUserName = hiveBox.get("mqttUserName", defaultValue: "") ?? "";
      mqttPassword = hiveBox.get("mqttPassword", defaultValue: "") ?? "";

      if (hostProtocol != null) {
        mqttHost = HostLabel.values.firstWhere(
          (e) => e.protocol == hostProtocol,
          orElse: () => HostLabel.mqtt,
        );
      }
    }
  }

  Future<void> updateData() async {
    await hiveBox.put("mqttHost", mqttHost.protocol);
    await hiveBox.put("mqttHostName", mqttHostName);
    await hiveBox.put("mqttPort", mqttPort);
    await hiveBox.put("mqttUserName", mqttUserName);
    await hiveBox.put("mqttPassword", mqttPassword);

    debugPrint("Hive Box keys: ${hiveBox.keys} -- values: ${hiveBox.values.toList()}");
  }
}
