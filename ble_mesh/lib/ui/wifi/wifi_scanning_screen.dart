import 'dart:async';
import 'package:ble_mesh/widgets/loading.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ble_mesh/ui/wifi/wifi_config_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:wifi_scan/wifi_scan.dart';
import '../../widgets/custom_widgets.dart';

/// Example app for wifi_scan plugin.
class WifiScanningScreen extends StatefulWidget {
  /// Default constructor for [WifiScanningScreen] widget.
  const WifiScanningScreen({Key? key}) : super(key: key);

  @override
  State<WifiScanningScreen> createState() => _WifiScanningScreenState();
}

class _WifiScanningScreenState extends State<WifiScanningScreen> {
  List<WiFiAccessPoint> accessPoints = <WiFiAccessPoint>[];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initializeScan();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _initializeScan() async {
    _startPeriodicScan();
  }

  void _startPeriodicScan() async {
    if (mounted) {
      await _getScannedResults();
    }

    _timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (mounted) {
        await _getScannedResults();
      }
    });
  }

  Future<void> _getScannedResults() async {
    if (await _canGetScannedResults()) {
      // Lấy danh sách kết quả quét WiFi
      final accessPoints = await WiFiScan.instance.getScannedResults();

      final filteredResults = accessPoints.where((ap) => ap.ssid.isNotEmpty && ap.level > -90).toList();

      // Loại bỏ các SSID trùng nhau, chỉ giữ lại BSSID có tín hiệu mạnh nhất
      Map<String, WiFiAccessPoint> bestAPs = {};

      for (var ap in filteredResults) {
        if (!bestAPs.containsKey(ap.ssid) || bestAPs[ap.ssid]!.level < ap.level) {
          bestAPs[ap.ssid] = ap;
        }
      }

      if (mounted) {
        setState(() {
          this.accessPoints = bestAPs.values.toList();
        });
      }

      // In danh sách sau khi lọc
      // for (var ap in accessPoints) {
      //   print("🔹 SSID: ${ap.ssid}, BSSID: ${ap.bssid}, Level: ${ap.level}");
      // }
    }
  }

  Future<bool> _canGetScannedResults() async {
    // 1. Kiểm tra dịch vụ định vị
    if (!await _checkLocationService()) return false;

    // 2. Kiểm tra quyền truy cập vị trí
    if (!await _checkLocationPermission()) return false;

    // 3. Kiểm tra khả năng quét Wi-Fi
    return await _checkWifiScanCapability();
  }

// Kiểm tra dịch vụ định vị
  Future<bool> _checkLocationService() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      showError("Dịch vụ định vị đang tắt. Vui lòng bật định vị để quét Wi-Fi.");
      await Geolocator.openLocationSettings();
      return false;
    }
    return true;
  }

// Kiểm tra quyền truy cập vị trí
  Future<bool> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      showError("Ứng dụng cần quyền truy cập vị trí để quét Wi-Fi.");
      return false;
    }

    if (permission == LocationPermission.deniedForever) {
      showError("Quyền vị trí đã bị từ chối vĩnh viễn. Vui lòng cấp quyền trong cài đặt.");
      await openAppSettings();
      return false;
    }

    return true;
  }

// Kiểm tra khả năng quét Wi-Fi
  Future<bool> _checkWifiScanCapability() async {
    final can = await WiFiScan.instance.canGetScannedResults(askPermissions: true);
    if (can != CanGetScannedResults.yes) {
      String message;
      switch (can) {
        case CanGetScannedResults.notSupported:
          message = "Thiết bị không hỗ trợ quét Wi-Fi.";
          break;
        case CanGetScannedResults.noLocationPermissionRequired:
          message = "Ứng dụng cần quyền truy cập vị trí để quét Wi-Fi.";
          break;
        case CanGetScannedResults.noLocationPermissionDenied:
          message = "Quyền truy cập vị trí đã bị từ chối.";
          break;
        case CanGetScannedResults.noLocationPermissionUpgradeAccuracy:
          message = "Cần quyền truy cập vị trí với độ chính xác cao.";
          break;
        case CanGetScannedResults.noLocationServiceDisabled:
          message = "Dịch vụ vị trí đã tắt. Vui lòng bật nó từ cài đặt.";
          break;
        default:
          message = "Không thể lấy kết quả quét Wi-Fi: $can";
      }
      showError(message);
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wi-Fi'),
        titleTextStyle: const TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold),
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 15),
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 28),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        child: accessPoints.isEmpty
            ? const Center(child: Text("Không tìm thấy mạng Wi-Fi nào."))
            : ListView.builder(
                itemCount: accessPoints.length,
                itemBuilder: (context, i) => _AccessPointTile(accessPoint: accessPoints[i]),
              ),
      ),
    );
  }
}

class _AccessPointTile extends StatelessWidget {
  final WiFiAccessPoint accessPoint;
  const _AccessPointTile({Key? key, required this.accessPoint}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final SSID = accessPoint.ssid.isNotEmpty ? accessPoint.ssid : "**EMPTY**";
    final signalIcon = wifiIcon(accessPoint.level);
    final frequency = (accessPoint.frequency / 1024).toStringAsFixed(1);

    return ListTile(
      leading: signalIcon,
      title: Text(SSID),
      titleTextStyle: const TextStyle(color: Colors.black),
      trailing: Text(
        "$frequency GHz",
        style: const TextStyle(color: Colors.black),
      ),
      onTap: () {
        final myAppState = context.findAncestorStateOfType<_WifiScanningScreenState>();
        myAppState?._timer?.cancel();
        Navigator.of(context)
            .push(MaterialPageRoute(
          builder: (context) => WifiConfigScreen(
            SSID: SSID,
            BSSID: accessPoint.bssid,
          ),
        ))
            .then((_) {
          myAppState?._startPeriodicScan();
        });
      },
    );
  }
}
