import 'package:ble_mesh/themes/mycolors.dart';
import 'package:flutter/material.dart';

class NodeItem {
  final String macAddress;

  NodeItem({required this.macAddress});

  @override
  Widget buildLeading(BuildContext context) {
    return Image.asset(
      "assets/icons/node.png",
      width: 32,
      height: 32,
      color: Colors.blue,
    );
  }

  @override
  Widget buildTitle(BuildContext context) {
    return Row(
      children: [Text(macAddress)],
    );
  }

  @override
  Widget buildSubtitle(BuildContext context) => const SizedBox.shrink();

  @override
  Widget buildTrailing(BuildContext context) => const Icon(
        Icons.arrow_forward_ios,
        color: IconColor04,
      );
}
