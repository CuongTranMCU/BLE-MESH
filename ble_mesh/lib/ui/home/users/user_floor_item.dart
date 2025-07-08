import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../../models/monitor_data.dart';

class UserFloorItem extends StatelessWidget {
  final String floorName;
  final Map<String, MonitorData> nodeData;
  final bool activeOnTap;
  final VoidCallback onTap;

  const UserFloorItem({
    Key? key,
    required this.floorName,
    required this.nodeData,
    required this.activeOnTap,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: activeOnTap ? onTap : null,
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
                  color: Colors.black.withAlpha(((0.7 * 255)).toInt()),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: Offset(0, 2),
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
        ],
      ),
    );
  }

  Color getColor(Map<String, MonitorData> nodes) {
    var color = Colors.green;

    for (var value in nodes.values) {
      if (value.feedback == "Fire") {
        return Colors.red;
      } else if (value.feedback == "Warning") {
        return Colors.orange;
      }
    }

    return color;
  }
}
