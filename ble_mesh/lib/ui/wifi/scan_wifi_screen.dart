import 'dart:async';

import 'package:ble_mesh/ui/wifi/provisioning_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:toastification/toastification.dart';

/// Example app for wifi_scan plugin.
class ScanWifiScreen extends StatefulWidget {
  /// Default constructor for [ScanWifiScreen] widget.
  const ScanWifiScreen({Key? key}) : super(key: key);

  @override
  State<ScanWifiScreen> createState() => _ScanWifiScreenState();
}

class _ScanWifiScreenState extends State<ScanWifiScreen> {
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
    final resultStartScan = await WiFiScan.instance.startScan();
    toastification.show(
      title: Text('startScan: $resultStartScan'),
      direction: TextDirection.ltr,
      autoCloseDuration: const Duration(seconds: 2),
    );
    _startPeriodicScan();
    // if (resultStartScan == true) {
    //   _startPeriodicScan();
    // } else {
    //   if (mounted) {
    //     print("❌ Không thể quét WiFi.");
    //     toastification.show(
    //       title: Text('startScan: $resultStartScan'),
    //       direction: TextDirection.ltr,
    //       autoCloseDuration: const Duration(seconds: 5),
    //     );
    //   }
    // }
  }

  Future<void> _getScannedResults() async {
    if (await _canGetScannedResults()) {
      // Lấy danh sách kết quả quét WiFi
      final results = await WiFiScan.instance.getScannedResults();

      final filteredResults = results.where((ap) => ap.ssid.isNotEmpty && ap.level > -90).toList();

      // Loại bỏ các SSID trùng nhau, chỉ giữ lại BSSID có tín hiệu mạnh nhất
      Map<String, WiFiAccessPoint> bestAPs = {}; // Chỉ định rõ kiểu dữ liệu

      for (var ap in filteredResults) {
        if (!bestAPs.containsKey(ap.ssid) || bestAPs[ap.ssid]!.level < ap.level) {
          bestAPs[ap.ssid] = ap;
        }
      }

      setState(() {
        accessPoints = bestAPs.values.toList(); // Kiểu dữ liệu bây giờ là List<WiFiAccessPoint>
      });

      // In danh sách sau khi lọc
      for (var ap in accessPoints) {
        print("🔹 SSID: ${ap.ssid}, BSSID: ${ap.bssid}, Level: ${ap.level}");
      }
    }
  }

  Future<bool> _canGetScannedResults() async {
    final can = await WiFiScan.instance.canGetScannedResults();
    if (can != CanGetScannedResults.yes) {
      if (mounted) {
        toastification.show(
          title: Text("Cannot get scanned results: $can"),
          direction: TextDirection.ltr,
          autoCloseDuration: const Duration(seconds: 5),
        );
      }
      return false;
    }
    return true;
  }

  void _startPeriodicScan() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (mounted) {
        await _getScannedResults();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('WiFi'),
          centerTitle: true,
          leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back_ios),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: accessPoints.length,
                  itemBuilder: (context, i) => _AccessPointTile(
                    accessPoint: accessPoints[i],
                  ),
                ),
              ),
            ],
          ),
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
      trailing: Text("$frequency GHz"),
      onTap: () {
        final myAppState = context.findAncestorStateOfType<_ScanWifiScreenState>();
        myAppState?._timer?.cancel();
        Navigator.of(context)
            .push(MaterialPageRoute(
          builder: (context) => ProvisioningScreen(
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

  Widget wifiIcon(int dBm) {
    const double width = 32;
    const double height = 32;

    if (dBm <= -90) {
      return Image.asset("assets/icons/wifi0.png", width: width, height: height);
    } else if (dBm <= -80 && dBm > -90) {
      return Image.asset("assets/icons/wifi1.png", width: width, height: height);
    } else if (dBm <= -70 && dBm > -80) {
      return Image.asset("assets/icons/wifi2.png", width: width, height: height);
    } else if (dBm <= -67 && dBm > -70) {
      return Image.asset("assets/icons/wifi3.png", width: width, height: height);
    } else if (dBm <= -30 && dBm > -67) {
      return Image.asset("assets/icons/wifi4.png", width: width, height: height);
    } else {
      return Image.asset("assets/icons/wifi5.png", width: width, height: height);
    }
  }
}
