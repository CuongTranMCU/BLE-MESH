import 'package:ble_mesh/themes/mycolors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../cloud_services/rtdb_service_ble.dart';
import '../../../../../models/monitor_data.dart';
import '../../../../../providers/nodes_provider.dart';
import 'node_item_widget.dart';

/// Widget hiển thị danh sách các node
class ListNodesWidget extends StatelessWidget {
  final String floorName;
  final Map<String, MonitorData> data;

  final int selectedIndex;
  final Function(int) onTap;
  final Function() onRemove;

  const ListNodesWidget({
    required this.floorName,
    required this.data,
    required this.selectedIndex,
    required this.onTap,
    required this.onRemove,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: data.length,
      itemBuilder: (context, index) {
        final nodeKey = data.keys.elementAt(index);
        final nodeData = data[nodeKey]!;

        return Dismissible(
          background: Container(
            color: Colors.redAccent,
            child: const Icon(Icons.delete_outline_rounded, size: 32, color: IconColor03),
          ),
          direction: DismissDirection.endToStart,
          key: ValueKey<String>(nodeKey),
          onDismissed: (DismissDirection direction) {
            onRemove();
            data.remove(nodeKey);
            final List<String> listNode = data.keys.toList();
            RTDBServiceBLE().removeNodeOfFloor(floorName: floorName, newFloor: listNode);
            Provider.of<NodesProvider>(context, listen: false).data = data;
          },
          child: GestureDetector(
            onTap: () => onTap(index),
            child: NodeItemWidget(
              index: index,
              deviceName: nodeKey,
              monitorData: nodeData,
              isSelected: selectedIndex == index,
            ),
          ),
        );
      },
    );
  }
}
