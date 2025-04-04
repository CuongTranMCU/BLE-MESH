import 'package:ble_mesh/providers/nodes_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../cloud_functions/data_stream_publisher.dart';
import '../../../models/data.dart';
import 'floor_info.dart';

class ListOfFloors extends StatefulWidget {
  const ListOfFloors({super.key, required this.context});

  final BuildContext context;

  @override
  State<ListOfFloors> createState() => _ListOfFloorsState();
}

class _ListOfFloorsState extends State<ListOfFloors> {
  final DataStreamPublisher _dataStreamPublisher = DataStreamPublisher();
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

            return StreamBuilder<Map<String, Data>>(
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
                  WidgetsBinding.instance.addPostFrameCallback((_) => nodesProvider.data = nodeData);
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

class FloorItem extends StatelessWidget {
  final String floorName;
  final Map<String, Data> nodeData;
  final bool showDeleteIcon;
  final bool activeOnTap;
  final VoidCallback onDelete;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const FloorItem({
    Key? key,
    required this.floorName,
    required this.nodeData,
    required this.showDeleteIcon,
    required this.activeOnTap,
    required this.onDelete,
    required this.onTap,
    required this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: activeOnTap ? onTap : null,
      onLongPress: onLongPress,
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
                onTap: onDelete,
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
