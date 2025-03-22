import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../cloud_functions/data_stream_publisher.dart';
import '../../../models/data.dart';
import '../../../models/node_item.dart';
import '../../../providers/data_provider.dart';
import '../../wifi/scan_wifi_screen.dart';
import 'node_info.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  final DataStreamPublisher _dataStreamPublisher = DataStreamPublisher();
  late StreamSubscription<List<String>> _latestSubscription;
  List<String> _latestData = [];
  late Data currentData;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    debugPrint("---------------------------***Nhảy vô initState ở Admin Home***---------------------------");

    _latestSubscription = _dataStreamPublisher.getLatestNodeList().listen((latestData) {
      setState(() {
        _latestData = latestData;
      });
    });
    debugPrint("---------------------------***Thoát initState ở Admin Home***---------------------------");
  }

  @override
  void dispose() {
    debugPrint("AdminHome disposed");
    _latestSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("Nhảy vào build _AdminHomeState");

    return Scaffold(
      appBar: AppBar(
        title: Text('ListView Example'),
        actions: [
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ScanWifiScreen()),
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset("assets/icons/wifi6.png", width: 38, height: 38),
            ),
          ),
          const SizedBox(width: 22),
        ],
      ),
      body: StreamBuilder<Map<String, dynamic>>(
          stream: _dataStreamPublisher.getListNodeFromData(),
          builder: (context, snapshot) {
            debugPrint("Nhảy vô dataStreamPublisher.getListNodeFromData() của Admin Home");

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.black),
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty || snapshot.data == null) {
              return const Center(
                  child: Text(
                'No data available',
                style: TextStyle(color: Colors.black),
              ));
            } else {
              final data = snapshot.data!;

              // prettyPrintJson(data);

              Future.microtask(() {
                if (mounted) {
                  final key = data.keys.elementAt(_currentIndex); // Tên Node
                  final value = data[key]; //Monitor & Now

                  // Update new data in Provider
                  if (value["Now"] != null && value["Now"] is Map<dynamic, dynamic>) {
                    Provider.of<DataProvider>(context, listen: false).updateData(Data.fromRTDB(value["Now"]));
                  }
                }
              });

              return ListView.builder(
                itemCount: data.keys.length,
                itemBuilder: (context, index) {
                  final key = data.keys.elementAt(index); // Tên Node
                  final value = data[key]; //Monitor & Now

                  final nodeItem = NodeItem(macAddress: key);
                  return ListTile(
                    leading: nodeItem.buildLeading(context),
                    title: nodeItem.buildTitle(context, _latestData.contains(key)),
                    trailing: nodeItem.buildTrailing(context),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$key tapped!')),
                      );
                      setState(() {
                        _currentIndex = index;
                      });
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NodeInfo(),
                        ),
                      );
                    },
                  );
                },
              );
            }
          }),
    );
  }

  void prettyPrintJson(dynamic json) {
    final jsonString = const JsonEncoder.withIndent('  ').convert(json);
    jsonString.split('\n').forEach(debugPrint);
  }
}
