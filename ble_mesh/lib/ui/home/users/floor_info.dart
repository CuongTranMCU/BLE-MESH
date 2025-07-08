import 'package:ble_mesh/providers/nodes_provider.dart';
import 'package:ble_mesh/ui/home/line_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../models/monitor_data.dart';
import '../../../../providers/control_signal_provider.dart';
import '../../../../themes/mycolors.dart';
import '../../../../widgets/custom_widgets.dart';
import '../admin/admin_group/custom_widget/current_node_widget.dart';
import 'list_nodes_widget.dart';

class UserFloorInfo extends StatefulWidget {
  final String floorName;

  const UserFloorInfo({super.key, required this.floorName});

  @override
  _UserFloorInfoState createState() => _UserFloorInfoState();
}

class _UserFloorInfoState extends State<UserFloorInfo> {
  int selectedIndex = 0;
  late String nodeName;
  late Map<String, MonitorData> data;

  @override
  void initState() {
    super.initState();
    debugPrint("Selected Index : $selectedIndex");
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controlProvider = Provider.of<ControlSignalProvider>(context, listen: false);
      controlProvider.initialize(data); // truyền Map<String, MonitorData> sau khi Provider data đã có
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Map<String, MonitorData> sortData(Map<String, MonitorData> data) {
    if (data.isEmpty) {
      debugPrint("No nodes available");
      return {};
    }

    // Define priority map
    const feedbackPriority = {
      "Big Fire": 0,
      "Fire": 1,
      "Warning": 2,
      "Safety": 3,
      "Undefined": 4,
    };

    // Sort entries based on feedback priority
    final sortedEntries = data.entries.toList()
      ..sort((a, b) {
        final aPriority = feedbackPriority[a.value.feedback] ?? 5;
        final bPriority = feedbackPriority[b.value.feedback] ?? 5;
        return aPriority.compareTo(bPriority);
      });

    // Convert back to Map
    final sortedData = Map<String, MonitorData>.fromEntries(sortedEntries);

    // // Debug output (có thể xóa nếu không cần)
    // for (var entry in sortedData.entries) {
    //   print("${entry.key}: ${entry.value.feedback}");
    // }

    return sortedData;
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("Selected Index : $selectedIndex");

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          color: AppTitleColor2,
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              color: AppTitleColor2,
              icon: const Icon(Icons.area_chart, size: 32),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => LineChartScreen(
                          nodeName: nodeName,
                        )),
              ),
            ),
          ),
        ],
        title: Text(widget.floorName,
            style: const TextStyle(
              color: AppTitleColor2,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            )),
        centerTitle: true,
      ),
      body: Consumer<NodesProvider>(
        builder: (context, nodesProvider, child) {
          data = nodesProvider.data;
          if (data.isEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              nodesProvider.selectedFloor = "";
              Navigator.pop(context);
            });
            return const SizedBox();
          } else {
            data = sortData(data);
            nodeName = data.keys.elementAt(selectedIndex);
            final nodeData = data[nodeName]!;

            return Column(
              children: [
                const SizedBox(height: 15),
                Text(
                  nodeName,
                  style: TextStyle(
                    fontSize: 30,
                    color: getColor(feedback: nodeData.feedback),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                CurrentNodeWidget(data: data, selectedIndex: selectedIndex),
                const SizedBox(height: 20),
                Expanded(
                  child: ListNodesWidget(
                    floorName: widget.floorName,
                    data: data,
                    selectedIndex: selectedIndex,
                    onTap: (index) => setState(() {
                      selectedIndex = index;
                    }),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
