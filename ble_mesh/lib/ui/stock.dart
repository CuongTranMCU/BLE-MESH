import 'package:flutter/material.dart';

import '../cloud_functions/data_stream_publisher.dart';
import '../models/data.dart';
import '../themes/mycolors.dart';

class StockPage extends StatefulWidget {
  const StockPage({
    Key? key,
    required this.title,
    required this.homeIndex,
  }) : super(key: key);

  final String title;
  final int homeIndex;

  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  int position = 0;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    initPosition();
    print("Node : $position");
  }

  void initPosition() async {
    List<Map<String, Data>> nodes = await DataStreamPublisher().getNodes(path: widget.title);

    if (nodes.isEmpty) {
      print("No nodes available");
      return;
    }

    for (var nodeMap in nodes) {
      // Mỗi `nodeMap` là dạng {"Node 0x1234": Data(...)}
      String nodeName = nodeMap.keys.first; // Lấy tên node, e.g., "Node 0x1234"
      Data nodeData = nodeMap[nodeName]!; // Lấy dữ liệu của node

      // Kiểm tra điều kiện dựa trên `temperature` và `smoke`
      if ((nodeData.temperature >= 35 && nodeData.temperature < 40) || (nodeData.smoke >= 35 && nodeData.smoke < 100)) {
        if (nodes[position][nodes[position].keys.first]!.temperature < 35) {
          setState(() {
            position = nodes.indexOf(nodeMap);
          });
        }
      }

      if (nodeData.temperature >= 40 || nodeData.smoke >= 100) {
        if (nodes[position][nodes[position].keys.first]!.temperature < 40) {
          setState(() {
            position = nodes.indexOf(nodeMap);
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          color: TextAppBarColor,
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 28,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          "${widget.title}",
          style: TextStyle(color: TextAppBarColor, fontSize: 24),
        ),
        centerTitle: true,
      ),
      body: Container(
        child: StreamBuilder<List<Map<String, Data>>>(
          stream: DataStreamPublisher().getDataStream(path: widget.title),
          builder: (context, snapshot) {
            // if (snapshot.connectionState == ConnectionState.waiting) {
            //   return Center(child: CircularProgressIndicator());
            // } else
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: CircularProgressIndicator());
            } else {
              return Column(
                children: [
                  SizedBox(height: 50),
                  _buildCurrentNode(snapshot.data!),
                  SizedBox(height: 20),
                  _buildListNodes(snapshot.data!),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildCurrentNode(List<Map<String, Data>> data) {
    final nodeKey = data[position].keys.first; // Lấy tên node (ví dụ: "Node 0x1234")
    final nodeData = data[position][nodeKey]!; // Lấy dữ liệu node

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        decoration: BoxDecoration(
          color: CardColor.withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Image.asset(
                        'assets/icons/warehouse.png',
                        width: 110,
                        height: 110,
                        color: getColor(nodeData.temperature, nodeData.smoke),
                      ),
                      const SizedBox(height: 25),
                      Row(
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [Color(0xFF00BFFF), Color(0xFF0077FF)], // Màu gradient đồng bộ với biểu tượng
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ).createShader(bounds),
                            child: const Text(
                              "BLE mesh", // Hiển thị tên node
                              style: TextStyle(
                                fontSize: 22,
                                color: Colors.white, // Màu sẽ bị shader ghi đè
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Image.asset(
                            'assets/icons/ble.png', // Đảm bảo file ảnh này đã có trong thư mục assets
                            width: 30,
                            height: 30,
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFF0078FF), Color(0xFF5FDCC7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        child: Text(
                          "RSSI: ${nodeData.rssi}", // Hiển thị tên node
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white, // Màu sẽ bị shader ghi đè
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        nodeKey, // Hiển thị tên node
                        style: TextStyle(
                          fontSize: 24,
                          color: getColor(nodeData.temperature, nodeData.smoke),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${nodeData.temperature}°C',
                        style: TextStyle(
                          fontSize: 48,
                          color: getColor(nodeData.temperature, nodeData.smoke),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 5),
                      _getText(
                        nodeData.temperature,
                        nodeData.smoke,
                        customize: true,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildWeatherInfo(
                    icon: Icons.thermostat,
                    value: '${nodeData.temperature}°C',
                    label: 'Temperature',
                  ),
                  _buildWeatherInfo(
                    icon: Icons.water_drop,
                    value: '${nodeData.humidity}%',
                    label: 'Humidity',
                  ),
                  _buildWeatherInfo(
                    image: 'assets/icons/smoke.png',
                    value: '${nodeData.smoke} ppm',
                    label: 'Smoke',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherInfo({IconData? icon, String image = "", required String value, required String label}) {
    return Column(
      children: [
        (icon != null)
            ? Icon(
                icon,
                color: Colors.white,
                size: 34,
              )
            : Image.asset(
                image,
                width: 34,
                height: 34,
                color: Colors.white,
              ),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(color: TextColor, fontSize: 18)),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(color: TextColor, fontSize: 14)),
      ],
    );
  }

  Widget _buildListNodes(List<Map<String, Data>> data) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              final nodeKey = data[index].keys.first; // Lấy tên node (e.g., "Node 0x1234")
              final nodeData = data[index][nodeKey]!; // Lấy dữ liệu node

              return GestureDetector(
                onTap: () {
                  setState(() {
                    position = index;
                  });
                },
                child: _buildNodeItem(
                  index: index,
                  node: nodeKey, // Tên node (e.g., "Node 0x1234")
                  temperature: nodeData.temperature,
                  smoke: nodeData.smoke,
                  rssi: nodeData.rssi,
                ),
              );
            },
            shrinkWrap: true,
          ),
        ),
      ),
    );
  }

  Widget _buildNodeItem({
    required int index,
    required String node,
    required double temperature,
    required double smoke,
    required rssi,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: position == index ? CardColor : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: position == index
            ? Border.all(
                color: BgColor, // Border color
                width: 1, // Border width
              )
            : null,
      ),
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(node, style: const TextStyle(color: TextColor, fontSize: 18)),
          Row(
            children: [
              Container(
                width: 40,
                height: 20,
                child: _getIcon(temperature, smoke),
              ),
              const SizedBox(width: 10),
              Container(
                width: 80,
                height: 25,
                child: _getText(temperature, smoke, customize: false),
              ),
              const SizedBox(width: 10),
              _getBLESignal(rssi),
            ],
          ),
        ],
      ),
    );
  }

  Icon _getIcon(double temperature, double smoke) {
    var icon = const Icon(
      Icons.check_circle_outline,
      color: Colors.green,
    );
    if (temperature < 35 || smoke < 35) {
      icon = const Icon(
        Icons.check_circle_outline,
        color: Colors.green,
      );
    }
    if ((temperature >= 35 && temperature < 40) || (smoke >= 35 && smoke < 100)) {
      icon = const Icon(
        Icons.warning_amber_rounded,
        color: Colors.orange,
      );
    }
    if (temperature >= 40 || smoke >= 100) {
      icon = const Icon(
        Icons.local_fire_department_rounded,
        color: Colors.red,
      );
    }
    return icon;
  }

  Widget _getBLESignal(int rssi) {
    Widget icon;
    double width = 34;
    double high = 34;
    Color color = Colors.transparent;

    if (rssi <= -90) {
      icon = Image.asset('assets/icons/no connection.png', width: width, height: high);
    } else if (rssi > -90 && rssi <= -80) {
      icon = Image.asset('assets/icons/low.png', width: width, height: high);
    } else if (rssi > -80 && rssi <= -72) {
      icon = Image.asset('assets/icons/lightly medium.png', width: width, height: high);
    } else if (rssi > -72 && rssi <= -67) {
      icon = Image.asset('assets/icons/medium.png', width: width, height: high);
    } else if (rssi > -67 && rssi <= -55) {
      icon = Image.asset('assets/icons/lightly high.png', width: width, height: high);
    } else if (rssi > -55 && rssi <= -30) {
      icon = Image.asset('assets/icons/high.png', width: width, height: high);
    } else {
      icon = Image.asset('assets/icons/error.png', width: width, height: high);
    }

    return icon;
  }

  Text _getText(
    double temperature,
    double smoke, {
    required bool customize,
    double fontSize = 0,
    FontWeight? fontWeight,
  }) {
    var text = const Text(
      'Safety',
      style: TextStyle(color: Colors.green, fontSize: 18),
    );
    if (temperature < 35 || smoke < 35) {
      text = const Text(
        'Safety',
        style: TextStyle(color: Colors.green, fontSize: 18),
      );
    }
    if ((temperature >= 35 && temperature < 40) || (smoke >= 35 && smoke < 100)) {
      text = const Text(
        'Warning',
        style: TextStyle(color: Colors.orange, fontSize: 18),
      );
    }
    if (temperature >= 40 || smoke >= 100) {
      text = const Text(
        'Fire',
        style: TextStyle(color: Colors.red, fontSize: 18),
      );
    }
    if (customize) {
      text = Text(
        text.data ?? '',
        style: text.style?.copyWith(fontSize: fontSize, fontWeight: fontWeight),
      );
    }
    return text;
  }

  Color getColor(double temperature, double smoke) {
    var color = Colors.green;

    if (temperature < 35 || smoke < 35) {
      color = Colors.green;
    }
    if ((temperature >= 35 && temperature < 40) || (smoke >= 35 && smoke < 100)) {
      color = Colors.orange;
    }
    if (temperature >= 40 || smoke >= 100) {
      color = Colors.red;
    }
    return color;
  }
}
