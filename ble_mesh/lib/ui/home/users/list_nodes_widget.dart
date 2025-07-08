import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../../models/monitor_data.dart';
import 'node_item_widget.dart';

/// Widget hiển thị danh sách các node
class ListNodesWidget extends StatelessWidget {
  final String floorName;
  final Map<String, MonitorData> data;

  final int selectedIndex;
  final Function(int) onTap;

  const ListNodesWidget({
    required this.floorName,
    required this.data,
    required this.selectedIndex,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: data.length,
      itemBuilder: (context, index) {
        final nodeKey = data.keys.elementAt(index);
        final nodeData = data[nodeKey]!;

        return GestureDetector(
          onTap: () => onTap(index),
          child: NodeItemWidget(
            index: index,
            deviceName: nodeKey,
            monitorData: nodeData,
            isSelected: selectedIndex == index,
          ),
        );
      },
    );
  }
}
