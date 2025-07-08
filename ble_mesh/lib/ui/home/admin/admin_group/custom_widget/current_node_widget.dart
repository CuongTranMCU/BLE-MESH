import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../../models/monitor_data.dart';
import '../../../../../themes/mycolors.dart';
import '../../../../../widgets/custom_widgets.dart';

/// Widget hiển thị thông tin node hiện tại
class CurrentNodeWidget extends StatelessWidget {
  final Map<String, MonitorData> data;
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
                      color: getColor(feedback: nodeData.feedback),
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
                        color: getColor(feedback: nodeData.feedback),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    getText(
                      feedback: nodeData.feedback,
                      fontSize: 32,
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
