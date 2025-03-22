import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import 'dart:convert';

import '../models/data.dart';

class DataStreamPublisher {
  final _database = FirebaseDatabase.instance.ref();
  static int count = 0;
  static int count2 = 0;
  static int count3 = 0;

  Future<List<Map<String, Data>>> getNodes({String path = ""}) async {
    try {
      final snapshot = await _database.child('Sensor/$path').get();
      if (snapshot.exists) {
        final dataMap = Map<dynamic, dynamic>.from(snapshot.value as Map);

        // Tạo danh sách kết quả bao gồm tên node và chuyển dữ liệu sang kiểu Data
        final result = dataMap.entries.map((entry) {
          final nodeKey = entry.key as String; // Tên của node (e.g., "Node 0x1234")
          final nodeData = Data.fromRTDB(Map<dynamic, dynamic>.from(entry.value as Map)); // Dữ liệu của node dưới dạng Data

          // Gộp tên node vào dữ liệu
          return {
            nodeKey: nodeData,
          };
        }).toList();
        final jsonResult = result.map((node) {
          return node.map((key, value) => MapEntry(key, value.toJson()));
        }).toList();

        // Chuyển đổi danh sách đối tượng Data thành JSON để in ra
        debugPrint("Nodes:");
        prettyPrintJson(jsonResult);

        return result;
      } else {
        print('No data available.');
        return [];
      }
    } catch (e) {
      print("Error fetching nodes: $e");
      return [];
    }
  }

  Stream<List<Map<String, Data>>> getDataStream({String path = ""}) {
    final dataStream = _database.child('Sensor/$path').onValue;

    final streamToPublish = dataStream.map((event) {
      final snapshot = event.snapshot.value;

      if (snapshot == null) {
        debugPrint("No data available in stream.");
        return <Map<String, Data>>[];
      }

      // Chuyển đổi dữ liệu snapshot thành Map
      final dataMap = Map<dynamic, dynamic>.from(snapshot as Map);

      // Tạo danh sách kết quả bao gồm tên node và chuyển dữ liệu sang kiểu Data
      final result = dataMap.entries.map((entry) {
        final nodeKey = entry.key as String; // Tên của node (e.g., "Node 0x1234")
        final nodeData = Data.fromRTDB(Map<dynamic, dynamic>.from(entry.value as Map)); // Dữ liệu của node dưới dạng Data

        // Gộp tên node vào dữ liệu
        return {
          nodeKey: nodeData,
        };
      }).toList();

      // Debug print kết quả đã sắp xếp
      debugPrint("Nodes from stream:");
      prettyPrintJson(result);

      return result;
    });

    return streamToPublish;
  }

  Stream<List<Map<String, dynamic>>> getHomeStream({String path = ""}) {
    final dataStream = _database.child('Sensor').onValue;
    final streamToPublish = dataStream.map((event) {
      final dataSnapshot = event.snapshot.value;

      if (dataSnapshot == null) {
        debugPrint("Data snapshot is null.");
        return <Map<String, dynamic>>[];
      }

      debugPrint("Raw snapshot:");
      prettyPrintJson(dataSnapshot);

      // Chuyển đổi dữ liệu snapshot thành Map
      final dataMap = dataSnapshot as Map<dynamic, dynamic>;

      // Tạo danh sách có thứ tự
      final List<Map<String, dynamic>> result = [];

      // Sắp xếp các khóa (floor keys) theo thứ tự từ điển
      final sortedKeys = dataMap.keys.toList()..sort((a, b) => a.toString().compareTo(b.toString())); // Sắp xếp thứ tự từ điển

      // Duyệt qua các khóa đã được sắp xếp
      for (var floorKey in sortedKeys) {
        final floorData = dataMap[floorKey] as Map<dynamic, dynamic>;

        // Thêm tầng (floorKey và floorValue) vào danh sách
        result.add({
          floorKey as String: floorData.map((nodeKey, nodeValue) {
            return MapEntry(nodeKey as String, Map<String, dynamic>.from(nodeValue as Map));
          })
        });
      }

      debugPrint("Final ordered result:");
      prettyPrintJson(result);

      return result;
    });

    return streamToPublish;
  }

  Stream<List<String>> getLatestNodeList({String path = ""}) {
    ++count2;
    debugPrint("---------------------------***Nhảy vào getLatestNodeList $count2***---------------------------");

    final dataStream = _database.child('LatestList').onValue;
    return dataStream.map((event) {
      final dataSnapshot = event.snapshot.value;

      if (dataSnapshot == null || dataSnapshot is! List) {
        debugPrint("Data snapshot is null or not a List.");
        return <String>[];
      }
      debugPrint("getLatestNodeList:  ${dataSnapshot}");
      debugPrint("Count LatestNodeList : ${count2}");
      debugPrint("---------------------------***Thoát getLatestNodeList $count2***---------------------------");

      return List<String>.from(dataSnapshot); // Chuyển đổi thành List<String>
    });
  }

  Stream<Map<String, dynamic>> getListNodeFromData({String path = ""}) {
    ++count;
    debugPrint("---------------------------***Nhảy vào getListNodeFromData $count***---------------------------");

    final dataStream = _database.child('Data').onValue;

    return dataStream.map((event) {
      final dataSnapshot = event.snapshot.value;

      if (dataSnapshot == null || dataSnapshot is! Map) {
        debugPrint("Data snapshot is null or not a valid Map.");
        return {}; // Trả về Map rỗng nếu dữ liệu không hợp lệ
      }

      // Chuyển đổi dữ liệu thành Map<String, dynamic>
      final mappedData = Map<String, dynamic>.from(dataSnapshot);

      //  prettyPrintJson(mappedData); // kiểm tra dữ liệu

      debugPrint("getListNodeFromData - Keys :  ${mappedData.keys}");
      debugPrint("Count ListNodeFromData : ${count}");
      debugPrint("---------------------------***Thoát getListNodeFromData $count***---------------------------");

      return mappedData;
    });
  }

  Stream<Map<String, dynamic>> getListFloor() {
    ++count3;
    debugPrint("---------------------------***Nhảy vào getListFloor$count3***---------------------------");

    final dataStream = _database.child('Floor').onValue;

    return dataStream.map((event) {
      final dataSnapshot = event.snapshot.value;

      if (dataSnapshot == null || dataSnapshot is! Map) {
        debugPrint("Data snapshot is null or not a valid Map.");
        return {};
      }

      // Chuyển đổi dữ liệu thành Map<String, dynamic>
      final mappedData = Map<String, dynamic>.from(dataSnapshot);
      debugPrint("Count ListNodeFromData : ${count3}");

      debugPrint("---------------------------***Thoát getListFloor$count3***---------------------------");

      return mappedData;
    });
  }

  Future<void> updateFloor({required String floorNumber, required int length, required List<String> nodes}) async {
    try {
      Map<String, String> data = {};
      for (var i = 0; i < nodes.length; i++) {
        data[(length + i).toString()] = nodes[i];
      }

      await _database.child('Floor/$floorNumber').update(data);
      // await _database.remove();

      print('Successfully updated floor: $floorNumber');
    } catch (e) {
      print("Error updating floor data: $e");
    }
  }

  Future<void> removeFloor({required String floorNumber}) async {
    try {
      await _database.child('Floor/$floorNumber').remove();
      print('Successfully removed floor: $floorNumber');
    } catch (e) {
      print("Error removing floor data: $e");
    }
  }

  Stream<List<Data>> getListOneNodeInData({String nodeName = ""}) {
    final dataStream = _database.child('Data/$nodeName/Monitor').onValue;
    List<Data> result = [];
    return dataStream.map((event) {
      final dataSnapshot = event.snapshot.value;

      if (dataSnapshot == null || dataSnapshot is! List) {
        debugPrint("Data snapshot is null or not a valid List.");
        return result;
      }

      // Chuyển đổi dữ liệu từ List <Map<String, dynamic>> sang List<Data>
      dataSnapshot.forEach((value) {
        final data = Data.fromRTDB(value);
        result.add(data);
      });

      return result;
    });
  }

  void prettyPrintJson(dynamic json) {
    final jsonString = const JsonEncoder.withIndent('  ').convert(json);
    jsonString.split('\n').forEach(debugPrint);
  }
}
