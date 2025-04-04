import 'package:ble_mesh/providers/nodes_provider.dart';
import 'package:ble_mesh/ui/home/admin/line_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/data.dart';
import '../../../themes/mycolors.dart';
import '../../../widgets/custom_widget.dart';

class FloorInfo extends StatefulWidget {
  final String floorName;

  const FloorInfo({super.key, required this.floorName});

  @override
  _FloorInfoState createState() => _FloorInfoState();
}

class _FloorInfoState extends State<FloorInfo> {
  int selectedIndex = 0;
  late String nodeName;

  @override
  void initState() {
    super.initState();
    // Đảm bảo init sau khi widget được build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final nodesProvider = Provider.of<NodesProvider>(context, listen: false);
      initSelectedIndex(nodesProvider.data);
      nodeName = nodesProvider.data.keys.elementAt(selectedIndex);
    });
  }

  /// Khởi tạo chỉ số node được chọn dựa trên dữ liệu
  void initSelectedIndex(Map<String, Data> data) {
    if (data.isEmpty) {
      print("No nodes available");
      return;
    }

    for (int index = 0; index < data.length; index++) {
      final nodeData = data.values.elementAt(index);
      // Ưu tiên trạng thái nghiêm trọng trước
      if (nodeData.temperature >= 40 || nodeData.smoke >= 100) {
        setState(() => selectedIndex = index);
        return;
      } else if ((nodeData.temperature >= 35 && nodeData.temperature < 40) || (nodeData.smoke >= 35 && nodeData.smoke < 100)) {
        setState(() => selectedIndex = index);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          color: textAppBarColor,
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            color: textAppBarColor,
            icon: const Icon(Icons.area_chart, size: 28),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => LineChartScreen(
                        nodeName: nodeName,
                      )),
            ),
          ),
        ],
        title: Text(
          widget.floorName,
          style: const TextStyle(color: textAppBarColor, fontSize: 24),
        ),
        centerTitle: true,
      ),
      body: Consumer<NodesProvider>(
        builder: (context, nodesProvider, child) {
          final data = nodesProvider.data;
          if (data.isEmpty) {
            return const Center(child: Text("No data available"));
          }
          final nodeKey = data.keys.elementAt(selectedIndex);
          final nodeData = data[nodeKey]!;
          return Column(
            children: [
              const SizedBox(height: 15),
              Text(
                nodeKey,
                style: TextStyle(
                  fontSize: 30,
                  color: getColor(nodeData.temperature, nodeData.smoke),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              CurrentNodeWidget(data: data, selectedIndex: selectedIndex),
              const SizedBox(height: 20),
              Expanded(
                child: ListNodesWidget(
                  data: data,
                  selectedIndex: selectedIndex,
                  onTap: (index) => setState(() {
                    selectedIndex = index;
                    nodeName = nodesProvider.data.keys.elementAt(selectedIndex);
                  }),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Widget hiển thị thông tin node hiện tại
class CurrentNodeWidget extends StatelessWidget {
  final Map<String, Data> data;
  final int selectedIndex;

  const CurrentNodeWidget({required this.data, required this.selectedIndex, super.key});

  @override
  Widget build(BuildContext context) {
    if (selectedIndex >= data.length) return const SizedBox.shrink();

    final nodeKey = data.keys.elementAt(selectedIndex);
    final nodeData = data[nodeKey]!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor.withAlpha((255 * 0.8).toInt()),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Image.asset(
                      'assets/icons/warehouse.png',
                      width: 110,
                      height: 110,
                      color: getColor(nodeData.temperature, nodeData.smoke),
                    ),
                    const SizedBox(height: 25),
                    Row(
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFF00BFFF), Color(0xFF0077FF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds),
                          child: const Text(
                            "BLE mesh",
                            style: TextStyle(
                              fontSize: 22,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Image.asset('assets/icons/ble.png', width: 30, height: 30),
                      ],
                    ),
                    const SizedBox(height: 5),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFF0078FF), Color(0xFF5FDCC7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: Text(
                        "RSSI: ${nodeData.rssi}",
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      '${nodeData.temperature}°C',
                      style: TextStyle(
                        fontSize: 48,
                        color: getColor(nodeData.temperature, nodeData.smoke),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    getText(
                      nodeData.temperature,
                      nodeData.smoke,
                      customize: true,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                buildWeatherInfo(
                  icon: Icons.thermostat,
                  value: '${nodeData.temperature}°C',
                  label: 'Temperature',
                ),
                buildWeatherInfo(
                  icon: Icons.water_drop,
                  value: '${nodeData.humidity}%',
                  label: 'Humidity',
                ),
                buildWeatherInfo(
                  image: 'assets/icons/smoke.png',
                  value: '${nodeData.smoke} ppm',
                  label: 'Smoke',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget hiển thị danh sách các node
class ListNodesWidget extends StatelessWidget {
  final Map<String, Data> data;
  final int selectedIndex;
  final Function(int) onTap;

  const ListNodesWidget({
    required this.data,
    required this.selectedIndex,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      itemCount: data.length,
      itemBuilder: (context, index) {
        final nodeKey = data.keys.elementAt(index);
        final nodeData = data[nodeKey]!;

        return GestureDetector(
          onTap: () => onTap(index),
          child: NodeItemWidget(
            index: index,
            node: nodeKey,
            temperature: nodeData.temperature,
            smoke: nodeData.smoke,
            rssi: nodeData.rssi,
            isSelected: selectedIndex == index,
          ),
        );
      },
    );
  }
}

/// Widget hiển thị từng node trong danh sách
class NodeItemWidget extends StatelessWidget {
  final int index;
  final String node;
  final double temperature;
  final double smoke;
  final int rssi;
  final bool isSelected;

  const NodeItemWidget({
    required this.index,
    required this.node,
    required this.temperature,
    required this.smoke,
    required this.rssi,
    required this.isSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? cardColor : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isSelected ? Border.all(color: bgColor, width: 1) : null,
      ),
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(node, style: const TextStyle(color: textColor, fontSize: 18)),
          Row(
            children: [
              SizedBox(width: 40, height: 20, child: getIcon(temperature, smoke)),
              const SizedBox(width: 10),
              SizedBox(width: 80, height: 25, child: getText(temperature, smoke, customize: false)),
              const SizedBox(width: 10),
              getBLESignal(rssi),
            ],
          ),
        ],
      ),
    );
  }
}
