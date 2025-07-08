class ControlData {
  final String deviceName;
  final String meshAddress;
  final bool? buzzerSignal;
  final List<bool>? ledRGBSignal;

  ControlData({
    required this.deviceName,
    required this.meshAddress,
    required this.buzzerSignal,
    required this.ledRGBSignal,
  });

  factory ControlData.fromBuzzerRTDB(String key, dynamic value) {
    return ControlData(
      deviceName: key,
      meshAddress: value["MeshAddress"]?.toString() ?? "",
      buzzerSignal: value["TurnOn"] ?? false,
      ledRGBSignal: null,
    );
  }

  factory ControlData.fromLedRTDB(String key, dynamic value) {
    return ControlData(
      deviceName: key,
      meshAddress: value["MeshAddress"]?.toString() ?? "",
      buzzerSignal: null,
      ledRGBSignal: [
        value["LedRed"] ?? false,
        value["LedGreen"] ?? false,
        value["LedBlue"] ?? false,
      ],
    );
  }

  ControlData copyWith({
    String? deviceName,
    String? meshAddress,
    bool? buzzerSignal,
    List<bool>? ledRGBSignal,
  }) {
    return ControlData(
      deviceName: deviceName ?? this.deviceName,
      meshAddress: meshAddress ?? this.meshAddress,
      buzzerSignal: buzzerSignal ?? this.buzzerSignal,
      ledRGBSignal: ledRGBSignal ?? this.ledRGBSignal,
    );
  }

  Map<String, dynamic> toBuzzerJson() {
    return {
      "MeshAddress": meshAddress,
      "TurnOn": buzzerSignal,
    };
  }

  Map<String, dynamic> toLedJson() {
    return {
      "MeshAddress": meshAddress,
      "LedRed": (ledRGBSignal != null && ledRGBSignal!.length > 0) ? ledRGBSignal![0] : null,
      "LedGreen": (ledRGBSignal != null && ledRGBSignal!.length > 1) ? ledRGBSignal![1] : null,
      "LedBlue": (ledRGBSignal != null && ledRGBSignal!.length > 2) ? ledRGBSignal![2] : null,
    };
  }

  @override
  String toString() {
    return '{deviceName: $deviceName, meshAddress: $meshAddress, buzzerSignal: $buzzerSignal, ledRGBSignal: $ledRGBSignal}';
  }
}
