import 'dart:async';

import 'package:ble_mesh/models/control_data.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

import 'dart:convert';

import '../models/monitor_data.dart';

class RTDBServiceBLE {
  final _database = FirebaseDatabase.instance.ref();

  Stream<List<String>> getLatestNodeList({String path = ""}) {
    debugPrint("---------------------------***Nhảy vào getLatestNodeList***---------------------------");

    final dataStream = _database.child('LatestList').onValue;
    return dataStream.map((event) {
      final dataSnapshot = event.snapshot.value;

      if (dataSnapshot == null || dataSnapshot is! List) {
        debugPrint("Data snapshot is null or not a List.");
        return <String>[];
      }
      debugPrint("getLatestNodeList:  ${dataSnapshot}");
      debugPrint("---------------------------***Thoát getLatestNodeList***---------------------------");

      return List<String>.from(dataSnapshot); // Chuyển đổi thành List<String>
    });
  }

  Stream<Map<String, MonitorData>> getListNodeFromData({List<dynamic> path = const []}) {
    debugPrint("---------------------------***Nhảy vào getListNodeFromData***---------------------------");

    if (path.isEmpty) {
      debugPrint("Path list is empty.");
      return Stream.value({});
    }

    final List<Stream<Map<String, MonitorData>>> streams = path.map((dynamic serverKey) {
      final String key = serverKey.toString(); // Ép kiểu về String
      return _database.child('Data/$key/Now').onValue.map((event) {
        final dataSnapshot = event.snapshot.value;
        if (dataSnapshot == null || dataSnapshot is! Map) {
          return {key: MonitorData.fromRTDB({})};
        }

        final data = MonitorData.fromRTDB(dataSnapshot as Map);
        return {key: data}; // Trả về map chứa dữ liệu của serverKey
      });
    }).toList();

    // Dùng merge và scan để gộp dữ liệu
    return Rx.merge(streams).scan<Map<String, MonitorData>>(
      (acc, map, _) => {...acc, ...map},
      {},
    );
  }

  Stream<Map<String, dynamic>> getListFloor() {
    debugPrint("---------------------------***Nhảy vào getListFloor***---------------------------");

    final dataStream = _database.child('Group').onValue;

    return dataStream.map((event) {
      final dataSnapshot = event.snapshot.value;

      if (dataSnapshot == null || dataSnapshot is! Map) {
        debugPrint("Data snapshot is null or not a valid Map.");
        return {};
      }

      // Chuyển đổi dữ liệu thành Map<String, dynamic>
      final mappedData = Map<String, dynamic>.from(dataSnapshot);

      debugPrint("---------------------------***Thoát getListFloor***---------------------------");

      return mappedData;
    });
  }

  Future<void> updateFloor({required String floorNumber, required int length, required List<String> nodes}) async {
    try {
      Map<String, String> data = {};
      for (var i = 0; i < nodes.length; i++) {
        data[(length + i).toString()] = nodes[i];
      }
      await _database.child('Group/$floorNumber').update(data);
      print('Successfully updated floor: $floorNumber');
    } catch (e) {
      print("Error updating floor data: $e");
    }
  }

  Future<void> removeFloor({required String floorNumber}) async {
    try {
      await _database.child('Group/$floorNumber').remove();
      print('Successfully removed floor: $floorNumber');
    } catch (e) {
      print("Error removing floor data: $e");
    }
  }

  Future<void> removeNodeOfFloor({required String floorName, required List<String> newFloor}) async {
    try {
      await _database.child('Group/$floorName').set(newFloor);
    } catch (e) {
      print("Error removing node of floor: $e");
    }
  }

  // Use for linechart
  Stream<List<MonitorData>> getListOneNodeInData({String nodeName = ""}) {
    final dataStream = _database.child('Data/$nodeName/Monitor').onValue;

    return dataStream.map((event) {
      final dataSnapshot = event.snapshot.value;

      // Khởi tạo danh sách mới cho mỗi lần emit của stream
      List<MonitorData> result = [];

      // Check if dataSnapshot is null
      if (dataSnapshot == null) {
        debugPrint("Data snapshot is null.");
        return result; // Return an empty list
      }

      // Handle case where dataSnapshot is a Map
      if (dataSnapshot is Map) {
        final dataMap = dataSnapshot;
        dataMap.forEach((key, value) {
          final data = MonitorData.fromRTDB(value);
          result.add(data);
        });
      }
      // Handle case where dataSnapshot is a List
      else if (dataSnapshot is List) {
        final dataList = dataSnapshot;
        for (var value in dataList) {
          if (value != null) {
            final data = MonitorData.fromRTDB(value);
            result.add(data);
          }
        }
      }
      // Handle unexpected data type
      else {
        debugPrint("Data snapshot:");
        prettyPrintJson(dataSnapshot);
        debugPrint("***************************Data snapshot is neither a Map nor a List***************************");
        return result; // Return an empty list
      }

      return result;
    });
  }

  // Use for control BLE nodes
  Stream<List<ControlData>> getListControlBuzzerSignal({String path = "Control/ControlBuzzer"}) {
    final dataStream = _database.child(path).onValue;

    return dataStream.map((event) {
      final dataSnapshot = event.snapshot.value;

      if (dataSnapshot == null || dataSnapshot is! Map) {
        debugPrint("ControlBuzzer snapshot is null or invalid.");
        return [];
      }

      final mapped = Map<String, dynamic>.from(dataSnapshot);

      final result = mapped.entries.map((entry) {
        return ControlData.fromBuzzerRTDB(entry.key, entry.value);
      }).toList();

      //debugPrint("Fetched ControlData list: $result");
      return result;
    });
  }

  Future<void> changeBuzzerSignal({
    required String node,
    required ControlData json,
    String pathPrefix = "Control/ControlBuzzer",
  }) async {
    final path = "$pathPrefix/$node";
    await _database.child(path).set(json.toBuzzerJson());
    print('Successfully updated $node: ${json.toBuzzerJson()}');
  }

  Stream<List<ControlData>> getListControlLedStatus({String path = "Control/ControlLed"}) {
    final dataStream = _database.child(path).onValue;

    return dataStream.map((event) {
      final dataSnapshot = event.snapshot.value;

      if (dataSnapshot == null || dataSnapshot is! Map) {
        debugPrint("ControlBuzzer snapshot is null or invalid.");
        return [];
      }

      final mapped = Map<String, dynamic>.from(dataSnapshot);

      final result = mapped.entries.map((entry) {
        return ControlData.fromLedRTDB(entry.key, entry.value);
      }).toList();

      //debugPrint("Fetched ControlData list: $result");
      return result;
    });
  }

  Future<void> changeLedStatus({
    required String node,
    required ControlData json,
    String pathPrefix = "Control/ControlLed",
  }) async {
    final path = "$pathPrefix/$node";
    await _database.child(path).set(json.toLedJson());
    print('Successfully updated $node: ${json.toLedJson()}');
  }

  void prettyPrintJson(dynamic json) {
    final jsonString = const JsonEncoder.withIndent('  ').convert(json);
    jsonString.split('\n').forEach(debugPrint);
  }
}
