import 'dart:developer';

class Data {
  String macAddress;
  double temperature;
  double humidity;
  double smoke;
  int rssi;
  DateTime? timeline; // Thay đổi thành DateTime? để chấp nhận null

  Data({
    required this.macAddress,
    required this.temperature,
    required this.humidity,
    required this.smoke,
    required this.rssi,
    this.timeline, // Cho phép null
  });

  factory Data.fromRTDB(Map<dynamic, dynamic> data) {
    double roundToTwoDecimalPlaces(double value) {
      return (value * 100).round() / 100.0;
    }

    // Chuyển chuỗi timestamp thành DateTime
    DateTime? parseTimeline(String? timestamp) {
      if (timestamp == null) return null;
      return DateTime.tryParse(timestamp.replaceAll(' ', 'T'));
    }

    return Data(
      macAddress: data['macAddress']?.toString() ?? "",
      smoke: roundToTwoDecimalPlaces(data['smoke']?.toDouble() ?? 0.0),
      temperature: roundToTwoDecimalPlaces(data['temperature']?.toDouble() ?? 0.0),
      humidity: roundToTwoDecimalPlaces(data['humidity']?.toDouble() ?? 0.0),
      rssi: (data['rssi'] is num) ? (data['rssi'] as num).toInt() : 0,
      timeline: parseTimeline(data['timeline']?.toString()), // Có thể null
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'macAddress': macAddress,
      'temperature': temperature,
      'humidity': humidity,
      'smoke': smoke,
      'rssi': rssi,
      'timeline': timeline?.toIso8601String(), // Chuyển DateTime thành chuỗi ISO, null-safe
    };
  }

  @override
  String toString() {
    return '{macAddress: $macAddress, temperature: $temperature, humidity: $humidity, smoke: $smoke, rssi: $rssi, timeline: $timeline}';
  }
}
