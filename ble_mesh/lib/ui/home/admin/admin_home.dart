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

class AdminHome extends StatelessWidget {
  AdminHome({super.key});
  final DataStreamPublisher _dataStreamPublisher = DataStreamPublisher();

  @override
  Widget build(BuildContext context) {
    debugPrint("Nhảy vào build _AdminHomeState");
    final dataProvider = Provider.of<DataProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ListView Example'),
        actions: [
          InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ScanWifiScreen())),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset("assets/icons/wifi6.png", width: 38, height: 38),
            ),
          ),
          const SizedBox(width: 22),
        ],
      ),
      body: StreamBuilder<List<String>>(
        stream: _dataStreamPublisher.getLatestNodeList(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox();
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.black)));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty || snapshot.data == null) {
            return const Center(child: Text('No nodes in latest list available', style: TextStyle(color: Colors.black)));
          } else {
            final latestData = snapshot.data!;
            return StreamBuilder<Map<String, Data>>(
              stream: _dataStreamPublisher.getListNodeFromData(path: latestData),
              builder: (context, snapshot) {
                debugPrint("Nhảy vô dataStreamPublisher.getListNodeFromData() của Admin Home");
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.black));
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.black)));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty || snapshot.data == null) {
                  return const Center(child: Text('No data available', style: TextStyle(color: Colors.black)));
                } else {
                  final data = snapshot.data!;
                  Map<String, Data> _listNode = dataProvider.listNode;
                  _listNode.addAll(data);
                  WidgetsBinding.instance.addPostFrameCallback((_) => dataProvider.listNode = data);
                  return ListView.builder(
                    itemCount: _listNode.length,
                    itemBuilder: (context, index) {
                      final key = _listNode.keys.elementAt(index);
                      final value = _listNode[key];
                      final nodeItem = NodeItem(macAddress: key);
                      return ListTile(
                        leading: nodeItem.buildLeading(context),
                        title: nodeItem.buildTitle(context),
                        subtitle: Text(latestData.contains(key) ? "Connection" : "No connection"),
                        trailing: nodeItem.buildTrailing(context),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$key tapped!')));
                          dataProvider.selectedNode = key;
                          dataProvider.selectedData = value;
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const NodeInfo()));
                        },
                      );
                    },
                  );
                }
              },
            );
          }
        },
      ),
    );
  }

  void prettyPrintJson(dynamic json) {
    final jsonString = const JsonEncoder.withIndent('  ').convert(json);
    jsonString.split('\n').forEach(debugPrint);
  }
}
