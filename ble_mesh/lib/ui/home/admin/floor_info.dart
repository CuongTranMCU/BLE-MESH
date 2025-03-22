import 'package:ble_mesh/providers/nodes_provider.dart';
import 'package:ble_mesh/ui/home/admin/testlinechart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/data.dart';
import '../../../themes/mycolors.dart';

class FloorInfo extends StatefulWidget {
  final String floorName;
  final List<dynamic> nodes;
  final Map<String, Data> nodeData;

  const FloorInfo({super.key, required this.floorName, required this.nodes, required this.nodeData});

  @override
  _FloorInfoState createState() => _FloorInfoState();
}

class _FloorInfoState extends State<FloorInfo> {
  int position = 0;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    initPosition(widget.nodeData);
  }

  void initPosition(Map<String, Data> data) {
    if (data.isEmpty) {
      print("No nodes available");
      return;
    }

    int index = 0;
    for (var node in data.entries) {
      String nodeName = node.key;
      Data nodeData = node.value;

      if ((nodeData.temperature >= 35 && nodeData.temperature < 40) || (nodeData.smoke >= 35 && nodeData.smoke < 100)) {
        position = index;
      }

      if (nodeData.temperature >= 40 || nodeData.smoke >= 100) {
        position = index;
      }
      index++;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          color: TextAppBarColor,
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 28),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            color: TextAppBarColor,
            icon: const Icon(Icons.area_chart, size: 28),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const LineChartSample1()));
            },
          ),
        ],
        title: Text(
          widget.floorName,
          style: const TextStyle(color: TextAppBarColor, fontSize: 24),
        ),
        centerTitle: true,
      ),
      body: Consumer<NodesProvider>(
        // Lưu ý về trạng thái update của node Data và nodes, chưa check

        builder: (context, nodesProvider, child) {
          final data = nodesProvider.getNodes(widget.nodes);
          if (data == null || data.isEmpty) {
            return const Center(child: Text("No data available"));
          }

          return Column(
            children: [
              const SizedBox(height: 50),
              _buildCurrentNode(data),
              const SizedBox(height: 20),
              _buildListNodes(data),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCurrentNode(Map<String, Data> data) {
    if (position >= data.length) position = 0;

    final nodeKey = data.keys.elementAt(position);
    final nodeData = data[nodeKey]!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        decoration: BoxDecoration(
          color: CardColor.withAlpha((255 * 0.8).toInt()),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
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
                          Image.asset(
                            'assets/icons/ble.png',
                            width: 30,
                            height: 30,
                          ),
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
                        nodeKey,
                        style: TextStyle(
                          fontSize: 24,
                          color: getColor(nodeData.temperature, nodeData.smoke),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${nodeData.temperature}°C',
                        style: TextStyle(
                          fontSize: 48,
                          color: getColor(nodeData.temperature, nodeData.smoke),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      _getText(
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
                  _buildWeatherInfo(
                    icon: Icons.thermostat,
                    value: '${nodeData.temperature}°C',
                    label: 'Temperature',
                  ),
                  _buildWeatherInfo(
                    icon: Icons.water_drop,
                    value: '${nodeData.humidity}%',
                    label: 'Humidity',
                  ),
                  _buildWeatherInfo(
                    image: 'assets/icons/smoke.png',
                    value: '${nodeData.smoke} ppm',
                    label: 'Smoke',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherInfo({IconData? icon, String image = "", required String value, required String label}) {
    return Column(
      children: [
        (icon != null)
            ? Icon(
                icon,
                color: Colors.white,
                size: 34,
              )
            : Image.asset(
                image,
                width: 34,
                height: 34,
                color: Colors.white,
              ),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(color: TextColor, fontSize: 18)),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(color: TextColor, fontSize: 14)),
      ],
    );
  }

  Widget _buildListNodes(Map<String, Data> data) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: ListView.builder(
          itemCount: data.length,
          itemBuilder: (context, index) {
            final nodeKey = data.keys.elementAt(index);
            final nodeData = data[nodeKey]!;

            return GestureDetector(
              onTap: () {
                setState(() {
                  position = index;
                });
              },
              child: _buildNodeItem(
                index: index,
                node: nodeKey,
                temperature: nodeData.temperature,
                smoke: nodeData.smoke,
                rssi: nodeData.rssi,
              ),
            );
          },
          shrinkWrap: true,
        ),
      ),
    );
  }

  Widget _buildNodeItem({
    required int index,
    required String node,
    required double temperature,
    required double smoke,
    required int rssi,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: position == index ? CardColor : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: position == index
            ? Border.all(
                color: BgColor,
                width: 1,
              )
            : null,
      ),
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(node, style: const TextStyle(color: TextColor, fontSize: 18)),
          Row(
            children: [
              SizedBox(
                width: 40,
                height: 20,
                child: _getIcon(temperature, smoke),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 80,
                height: 25,
                child: _getText(temperature, smoke, customize: false),
              ),
              const SizedBox(width: 10),
              _getBLESignal(rssi),
            ],
          ),
        ],
      ),
    );
  }

  Icon _getIcon(double temperature, double smoke) {
    if (temperature >= 40 || smoke >= 100) {
      return const Icon(
        Icons.local_fire_department_rounded,
        color: Colors.red,
      );
    } else if ((temperature >= 35 && temperature < 40) || (smoke >= 35 && smoke < 100)) {
      return const Icon(
        Icons.warning_amber_rounded,
        color: Colors.orange,
      );
    } else {
      return const Icon(
        Icons.check_circle_outline,
        color: Colors.green,
      );
    }
  }

  Widget _getBLESignal(int rssi) {
    const double width = 34;
    const double height = 34;

    if (rssi <= -90) {
      return Image.asset('assets/icons/no connection.png', width: width, height: height);
    } else if (rssi > -90 && rssi <= -80) {
      return Image.asset('assets/icons/low.png', width: width, height: height);
    } else if (rssi > -80 && rssi <= -72) {
      return Image.asset('assets/icons/lightly medium.png', width: width, height: height);
    } else if (rssi > -72 && rssi <= -67) {
      return Image.asset('assets/icons/medium.png', width: width, height: height);
    } else if (rssi > -67 && rssi <= -55) {
      return Image.asset('assets/icons/lightly high.png', width: width, height: height);
    } else if (rssi > -55 && rssi <= -30) {
      return Image.asset('assets/icons/high.png', width: width, height: height);
    } else {
      return Image.asset('assets/icons/error.png', width: width, height: height);
    }
  }

  Text _getText(
    double temperature,
    double smoke, {
    required bool customize,
    double fontSize = 18,
    FontWeight? fontWeight,
  }) {
    String textData;
    Color color;

    if (temperature >= 40 || smoke >= 100) {
      textData = 'Fire';
      color = Colors.red;
    } else if ((temperature >= 35 && temperature < 40) || (smoke >= 35 && smoke < 100)) {
      textData = 'Warning';
      color = Colors.orange;
    } else {
      textData = 'Safety';
      color = Colors.green;
    }

    return Text(
      textData,
      style: TextStyle(
        color: color,
        fontSize: customize ? fontSize : 18,
        fontWeight: customize ? fontWeight : null,
      ),
    );
  }

  Color getColor(double temperature, double smoke) {
    if (temperature >= 40 || smoke >= 100) {
      return Colors.red;
    } else if ((temperature >= 35 && temperature < 40) || (smoke >= 35 && smoke < 100)) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }
}
