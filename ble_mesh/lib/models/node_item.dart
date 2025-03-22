import 'package:flutter/material.dart';

class NodeItem {
  final String macAddress;

  NodeItem({required this.macAddress});

  @override
  Widget buildLeading(BuildContext context) {
    return Icon(Icons.next_week_outlined);
  }

  @override
  Widget buildTitle(BuildContext context, bool isConnect) {
    return Row(
      children: [
        Text(macAddress),
        SizedBox(width: 20),
        Text(isConnect ? "Connection" : "No connection"),
      ],
    );
  }

  @override
  Widget buildSubtitle(BuildContext context) => const SizedBox.shrink();

  @override
  Widget buildTrailing(BuildContext context) => const Icon(Icons.arrow_forward_ios);
}
