import 'package:ble_mesh/models/monitor_data.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../providers/data_provider.dart';
import '../../../../themes/mycolors.dart';
import '../../../../widgets/custom_widgets.dart';

class NodeInfo extends StatelessWidget {
  const NodeInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          color: AppTitleColor2,
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 28),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text("Node Information", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        foregroundColor: AppTitleColor2,
        centerTitle: true,
      ),
      body: Consumer<DataProvider>(
        builder: (context, dataProvider, child) {
          final data = dataProvider.listNode[dataProvider.selectedNode];
          if (data == null) {
            return const Center(child: Text("No data available"));
          }

          return Center(
            child: Column(
              children: [
                const SizedBox(height: 50),
                Text(
                  "Node ${data.macAddress}", // Hiển thị tên node
                  style: TextStyle(
                    fontSize: 30,
                    color: getColor(feedback: data.feedback),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildCurrentNode(data),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentNode(MonitorData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        decoration: BoxDecoration(
          color: CardColor.withOpacity(0.8),
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
                        color: getColor(feedback: data.feedback),
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
                              "BLE mesh", // Hiển thị tên node
                              style: TextStyle(
                                fontSize: 22,
                                color: Colors.white, // Màu sẽ bị shader ghi đè
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
                          "RSSI: ${data.rssi}", // Hiển thị tên node
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white, // Màu sẽ bị shader ghi đè
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        '${data.temperature}°C',
                        style: TextStyle(
                          fontSize: 48,
                          color: getColor(feedback: data.feedback),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      getText(
                        feedback: data.feedback,
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
                    value: '${data.temperature}°C',
                    label: 'Temperature',
                  ),
                  buildWeatherInfo(
                    icon: Icons.water_drop,
                    value: '${data.humidity}%',
                    label: 'Humidity',
                  ),
                  buildWeatherInfo(
                    image: 'assets/icons/smoke.png',
                    value: '${data.smoke} ppm',
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
}
