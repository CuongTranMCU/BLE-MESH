import 'package:flutter/material.dart';

import '../themes/mycolors.dart';

typedef HostEntry = DropdownMenuItem<HostLabel>;

enum HostLabel {
  mqtt('mqtt://', TextColor01),
  mqtts('mqtts://', TextColor01),
  ws('ws://', TextColor01),
  wss('wss://', TextColor01);

  const HostLabel(this.protocol, this.color);
  final String protocol;
  final Color color;

  @override
  String toString() => protocol;
}

typedef ConnectionEntry = DropdownMenuItem<ConnectionTypeLabel>;

enum ConnectionTypeLabel {
  none('None', TextColor01),
  overTCP('Over TCP', TextColor01),
  overSSL('Over SSL', TextColor01),
  overWS('Over WebSocket', TextColor01),
  overWSS('Over WebSocket Security ', TextColor01);

  const ConnectionTypeLabel(this.type, this.color);
  final String type;
  final Color color;

  @override
  String toString() => type;
}
