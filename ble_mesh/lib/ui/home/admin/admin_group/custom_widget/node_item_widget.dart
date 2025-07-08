import 'package:ble_mesh/models/monitor_data.dart';
import 'package:ble_mesh/providers/control_signal_provider.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../../../../../themes/mycolors.dart';
import '../../../../../widgets/custom_widgets.dart';

/// Widget hiển thị từng node trong danh sách
class NodeItemWidget extends StatelessWidget {
  final int index;
  final String deviceName;
  final MonitorData monitorData;
  final bool isSelected;

  const NodeItemWidget({
    required this.index,
    required this.deviceName,
    required this.monitorData,
    required this.isSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ControlSignalProvider>(
      builder: (context, controlProvider, child) {
        final controlSignal = controlProvider.getOneNode(deviceName);

        return Container(
          height: 100,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? CardBorderColor1.withAlpha((255.0 * 0.1).round()) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? CardBorderColor2 : CardBorderColor1,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: CardBorderColor1.withAlpha((255.0 * 0.05).round()),
                      offset: Offset(0, 4),
                      blurRadius: 8,
                    ),
                  ]
                : [],
          ),
          child: ListTile(
            leading: Image.asset("assets/icons/node.png", width: 32, height: 32, color: Colors.blue),
            title: Text(deviceName),
            titleTextStyle: const TextStyle(color: textColor, fontSize: 18, fontStyle: FontStyle.italic),
            subtitle: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                SizedBox(width: 32, height: 38, child: getIcon(feedback: monitorData.feedback)),
                getText(
                  feedback: monitorData.feedback,
                  fontWeight: FontWeight.bold,
                ),
                Wrap(
                  spacing: 0,
                  children: [
                    IconButton(
                      onPressed: (controlSignal?.ledRGBSignal == null)
                          ? null
                          : () async {
                              final updatedSignal = controlSignal!.copyWith(
                                ledRGBSignal: [false, false, false],
                              );

                              await controlProvider.changeLedStatus(
                                deviceName: deviceName,
                                meshAddress: monitorData.meshAddress,
                                ledSignal: updatedSignal.ledRGBSignal!,
                              );
                            },
                      icon: Image.asset(
                        "assets/icons/led_icon.png",
                        width: 32,
                        height: 32,
                        color: getLedRGB(controlSignal?.ledRGBSignal),
                      ),
                    ),
                    IconButton(
                      onPressed: (controlSignal?.buzzerSignal == null)
                          ? null
                          : () async {
                              await controlProvider.changeBuzzerSignal(
                                deviceName: deviceName,
                                meshAddress: monitorData.meshAddress,
                                buzzerSignal: false,
                              );
                            },
                      icon: controlSignal?.buzzerSignal == true
                          ? Lottie.asset(
                              "assets/images/alarm.json",
                              width: 32,
                              height: 32,
                              repeat: true,
                            )
                          : Image.asset(
                              "assets/images/alarm.png",
                              width: 32,
                              height: 32,
                            ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: getBLESignal(monitorData.rssi),
          ),
        );
      },
    );
  }
}
