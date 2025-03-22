import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../cloud_functions/data_stream_publisher.dart';
import '../../../models/data.dart';
import '../../../providers/nodes_provider.dart';
import '../../stock.dart';
import 'floor_info.dart';

class ListOfFloors extends StatefulWidget {
  const ListOfFloors({super.key, required this.context});

  final BuildContext context;

  @override
  State<ListOfFloors> createState() => _ListOfFloorsState();
}

class _ListOfFloorsState extends State<ListOfFloors> {
  late StreamSubscription<Map<String, dynamic>> _dataSubscription;
  final DataStreamPublisher _dataStreamPublisher = DataStreamPublisher();
  bool showDeleteIcon = false;
  bool activeOnTap = true;

  @override
  void initState() {
    super.initState();
    debugPrint("---------------------------***Nhảy vô initState ListOfFloors***---------------------------");

    final context = widget.context;
    _dataSubscription = _dataStreamPublisher.getListNodeFromData().listen(
      (newData) {
        if (mounted) {
          Provider.of<NodesProvider>(context, listen: false).data = newData;
        }
      },
      onError: (error) {
        debugPrint("Error in node data stream: $error");
      },
    );

    debugPrint("---------------------------***Thoát initState ListOfFloors***---------------------------");
  }

  @override
  void dispose() {
    debugPrint("ListOfFloors disposed");
    _dataSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("Nhảy vào build _ListOfFloorsState");

    return StreamBuilder<Map<String, dynamic>>(
      stream: _dataStreamPublisher.getListFloor(),
      builder: (context, snapshot) {
        debugPrint("Nhảy vô  DataStreamPublisher().getListFloor() của ListOfFloors");

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.black),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          if (showDeleteIcon == true || activeOnTap == false) {
            showDeleteIcon = !showDeleteIcon;
            activeOnTap = !activeOnTap;
          }

          return const Center(
            child: Text(
              'No data available',
              style: TextStyle(color: Colors.black),
            ),
          );
        }

        final mapData = snapshot.data!;
        final List<Map<String, dynamic>> data = mapData.entries.map((entry) => {entry.key: entry.value}).toList();

        return Consumer<NodesProvider>(
          builder: (context, nodesProvider, child) {
            debugPrint("Nhảy vô Consumer của ListOfFloors");

            return GridView.builder(
              shrinkWrap: true,
              physics: const ScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10.0,
                mainAxisSpacing: 10.0,
              ),
              itemCount: data.length,
              itemBuilder: (context, index) {
                final floorData = data[index];
                final floorName = floorData.keys.single;
                final nodes = floorData.values.single as List<dynamic>;
                final nodeData = nodesProvider.getNodes(nodes);

                return FloorItem(
                  floorName: floorName,
                  index: index,
                  nodes: nodes,
                  nodeData: nodeData,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget FloorItem({
    required String floorName,
    required int index,
    required Map<String, Data> nodeData,
    required List<dynamic> nodes,
  }) {
    return GestureDetector(
      onTap: (activeOnTap)
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  // Lưu ý về trạng thái update của node Data và nodes, chưa check
                  builder: (context) => FloorInfo(floorName: floorName, nodes: nodes, nodeData: nodeData),
                ),
              );
            }
          : null,
      onLongPress: () {
        setState(() {
          showDeleteIcon = !showDeleteIcon;
          activeOnTap = !activeOnTap;
        });
      },
      child: Stack(
        children: [
          Container(
            width: 200,
            height: 200,
            margin: const EdgeInsets.fromLTRB(15, 15, 10, 0),
            decoration: BoxDecoration(
              color: getColor(nodeData),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha((showDeleteIcon ? (0.3 * 255) : (0.7 * 255)).toInt()),
                  spreadRadius: showDeleteIcon ? 2 : 1,
                  blurRadius: showDeleteIcon ? 8 : 4,
                  offset: Offset(0, showDeleteIcon ? 4 : 2),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(
                  'assets/icons/warehouse.png',
                  width: 120,
                  height: 120,
                ),
                Align(
                  alignment: const Alignment(0, -0.2),
                  child: Text(
                    floorName,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          if (showDeleteIcon)
            Align(
              alignment: const Alignment(-0.95, -0.95),
              child: GestureDetector(
                onTap: () async {
                  await _dataStreamPublisher.removeFloor(floorNumber: floorName);
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.black87,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.cancel_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color getColor(Map<String, Data> nodes) {
    var color = Colors.green;

    for (var value in nodes.values) {
      final smoke = value.smoke.toDouble();
      final temperature = value.temperature.toDouble();

      if (temperature >= 40 || smoke >= 100) {
        return Colors.red;
      } else if ((temperature >= 35 && temperature < 40) || (smoke >= 35 && smoke < 100)) {
        if (color != Colors.red) {
          color = Colors.orange;
        }
      }
    }

    return color;
  }
}
