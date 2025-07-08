class MonitorData {
  String macAddress;
  String meshAddress;
  double temperature;
  double humidity;
  double smoke;
  int rssi;
  DateTime? timeline;
  String? feedback;

  MonitorData({
    required this.macAddress,
    this.meshAddress = "-1",
    required this.temperature,
    required this.humidity,
    required this.smoke,
    required this.rssi,
    this.timeline,
    this.feedback,
  });

  factory MonitorData.fromRTDB(Map<dynamic, dynamic> data) {
    double roundToTwoDecimalPlaces(double value) {
      return (value * 100).round() / 100.0;
    }

    // Chuyển chuỗi timestamp thành DateTime
    DateTime? parseTimeline(String? timestamp) {
      if (timestamp == null) return null;
      return DateTime.tryParse(timestamp.replaceAll(' ', 'T'));
    }

    return MonitorData(
      macAddress: data['macAddress']?.toString() ?? "-1",
      meshAddress: data['meshAddress']?.toString() ?? "-1",
      smoke: roundToTwoDecimalPlaces(data['smoke']?.toDouble() ?? 0.0),
      temperature: roundToTwoDecimalPlaces(data['temperature']?.toDouble() ?? 0.0),
      humidity: roundToTwoDecimalPlaces(data['humidity']?.toDouble() ?? 0.0),
      rssi: (data['rssi'] is num) ? (data['rssi'] as num).toInt() : 0,
      timeline: parseTimeline(data['timeline']?.toString()),
      feedback: data['feedback']?.toString() ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'macAddress': macAddress,
      'meshAddress': meshAddress,
      'temperature': temperature,
      'humidity': humidity,
      'smoke': smoke,
      'rssi': rssi,
      'timeline': timeline?.toIso8601String(),
      'feedback': feedback,
    };
  }

  @override
  String toString() {
    return '{macAddress: $macAddress, temperature: $temperature, humidity: $humidity, smoke: $smoke, rssi: $rssi, timeline: $timeline, feedback: $feedback}';
  }
}
