import 'package:ble_mesh/ui/stock.dart';
import 'package:ble_mesh/ui/wifi/scan_wifi_screen.dart';
import 'package:flutter/material.dart';

import '../cloud_functions/data_stream_publisher.dart';
import '../themes/mycolors.dart';

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    const title = 'Home';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          title,
          style: TextStyle(color: TextAppBarColor, fontSize: 28),
        ),
        centerTitle: true,
        actions: [
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ScanWifiScreen()),
              );
            },
            borderRadius: BorderRadius.circular(8), // Hiệu ứng bo góc khi nhấn
            child: Padding(
              padding: const EdgeInsets.all(8.0), // Tạo khoảng cách để dễ nhấn hơn
              child: Image.asset("assets/icons/wifi6.png", width: 38, height: 38),
            ),
          ),
          const SizedBox(width: 22),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: DataStreamPublisher().getHomeStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.black),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
                child: Text(
              'No data available',
              style: TextStyle(color: Colors.black),
            ));
          } else {
            final data = snapshot.data!;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // 2 cột
                crossAxisSpacing: 10.0,
                mainAxisSpacing: 10.0,
              ),
              itemCount: data.length,
              itemBuilder: (context, index) {
                final floorData = data[index];
                final floorName = floorData.keys.first;
                final nodes = floorData[floorName] as Map<String, dynamic>;
                return GestureDetector(
                  onTap: () {
                    // Navigate to detail page when tapped
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StockPage(
                          title: floorName,
                          homeIndex: index + 1,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(10, 15, 10, 0),
                    decoration: BoxDecoration(
                      color: getColor(nodes),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 25),
                            child: Image.asset(
                              'assets/icons/warehouse.png',
                              width: 112,
                              height: 112,
                            ),
                          ),
                          Text(
                            floorName,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }

  Color getColor(Map<String, dynamic> nodes) {
    // Khởi tạo màu mặc định
    var color = Colors.green;

    // Duyệt qua từng node
    nodes.forEach((key, value) {
      final smoke = (value['smoke'] as num).toDouble();
      final temperature = (value['temperature'] as num).toDouble();

      if (temperature >= 40 || smoke >= 100) {
        color = Colors.red;
      } else if ((temperature >= 35 && temperature < 40) || (smoke >= 35 && smoke < 100)) {
        if (color != Colors.red) {
          color = Colors.orange;
        }
      }
    });

    return color;
  }
}
