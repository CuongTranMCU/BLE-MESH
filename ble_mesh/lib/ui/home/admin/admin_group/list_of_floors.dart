import 'package:ble_mesh/providers/nodes_provider.dart';
import 'package:ble_mesh/ui/home/admin/admin_group/custom_widget/admin_floor_item.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../cloud_services/rtdb_service_ble.dart';
import '../../../../models/monitor_data.dart';
import 'floor_info.dart';

class ListOfFloors extends StatefulWidget {
  const ListOfFloors({super.key, required this.context});

  final BuildContext context;

  @override
  State<ListOfFloors> createState() => _ListOfFloorsState();
}

class _ListOfFloorsState extends State<ListOfFloors> {
  final RTDBServiceBLE _dataStreamPublisher = RTDBServiceBLE();
  bool showDeleteIcon = false;
  bool activeOnTap = true;

  @override
  Widget build(BuildContext context) {
    debugPrint("Nhảy vào build _ListOfFloorsState");
    final nodesProvider = Provider.of<NodesProvider>(context, listen: false);

    return StreamBuilder<Map<String, dynamic>>(
      stream: _dataStreamPublisher.getListFloor(),
      builder: (context, snapshot) {
        debugPrint("Nhảy vô DataStreamPublisher().getListFloor() của ListOfFloors");

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox();
        } else if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.black),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          if (showDeleteIcon && !activeOnTap) {
            showDeleteIcon = !showDeleteIcon;
            activeOnTap = !activeOnTap;
          }
          nodesProvider.selectedFloor = "";
          return const Center(
            child: Text(
              'No data available',
              style: TextStyle(color: Colors.black),
            ),
          );
        }

        final mapData = snapshot.data!;

        return GridView.builder(
          shrinkWrap: true,
          physics: const ScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10.0,
            mainAxisSpacing: 10.0,
          ),
          itemCount: mapData.length,
          itemBuilder: (context, index) {
            final entry = mapData.entries.elementAt(index);
            final floorName = entry.key;
            final nodes = entry.value as List<dynamic>;

            return StreamBuilder<Map<String, MonitorData>>(
              stream: _dataStreamPublisher.getListNodeFromData(path: nodes),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.black)));
                }

                final nodeData = snapshot.data ?? {};

                if (nodesProvider.selectedFloor == floorName) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (nodesProvider.data != nodeData) {
                      nodesProvider.data = nodeData;
                    }
                  });
                }

                return FloorItem(
                  floorName: floorName,
                  nodeData: nodeData,
                  showDeleteIcon: showDeleteIcon,
                  activeOnTap: activeOnTap,
                  onDelete: () async {
                    await _dataStreamPublisher.removeFloor(floorNumber: floorName);
                  },
                  onTap: () {
                    nodesProvider.selectedFloor = floorName;
                    nodesProvider.data = nodeData;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FloorInfo(floorName: floorName),
                      ),
                    );
                  },
                  onLongPress: () {
                    setState(() {
                      showDeleteIcon = !showDeleteIcon;
                      activeOnTap = !activeOnTap;
                    });
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
