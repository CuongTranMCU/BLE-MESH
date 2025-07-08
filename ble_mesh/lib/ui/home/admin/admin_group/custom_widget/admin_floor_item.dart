import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../../models/monitor_data.dart';

class FloorItem extends StatelessWidget {
  final String floorName;
  final Map<String, MonitorData> nodeData;
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
