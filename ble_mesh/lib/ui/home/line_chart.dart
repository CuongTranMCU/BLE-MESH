import 'package:ble_mesh/themes/mycolors.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../cloud_services/rtdb_service_ble.dart';
import '../../models/monitor_data.dart';
import '../../themes/app_colors.dart';

class LineChartScreen extends StatefulWidget {
  const LineChartScreen({
    super.key,
    required this.nodeName,
  });

  final String nodeName;

  @override
  State<StatefulWidget> createState() => LineChartScreenState();
}

class LineChartScreenState extends State<LineChartScreen> {
  List<MonitorData> chartData = []; // Danh sách dữ liệu giới hạn cho 1 ngày
  List<MonitorData> newData = []; // Danh sách dữ liệu giới hạn cho 1 ngày
  List<MonitorData> average_one_hour = []; // Danh sách trung bình 1 giờ
  List<MonitorData> average_one_day = []; // Danh sách trung bình 1 ngày

  late TransformationController _transformationController;

  final List<String> timeOptions = ["1D", "1M", "1Y"];
  final List<String> dataOptions = ["Humidity", "Temperature", "Smoke"];

// Hàm lấy icon cho từng tùy chọn
  Widget _getIconForOption(String option) {
    switch (option) {
      case "Humidity":
        return const Icon(Icons.water_drop, size: 20);
      case "Temperature":
        return const Icon(Icons.thermostat, size: 20);
      case "Smoke":
        return const ImageIcon(
          AssetImage("assets/icons/smoke.png"),
          size: 20,
        );
      default:
        return const Icon(Icons.help, size: 20);
    }
  }

  int selectedTimeIndex = 0; // Mặc định chọn "1D"
  int selectedDataIndex = 0; // Mặc định chọn "Humidity"

  @override
  void initState() {
    _transformationController = TransformationController();
    debugPrint("Node name : ${widget.nodeName}");

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          color: AppTitleColor1,
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: SizedBox(
          width: double.infinity,
          child: Text(
            widget.nodeName,
            textAlign: TextAlign.center,
            softWrap: true,
            maxLines: 2,
          ),
        ),
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: AppTitleColor1,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppTitleColor1,
        foregroundColor: IconColor03,
        shape: const CircleBorder(),
        child: _TransformationButtons(
          controller: _transformationController,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ToggleButtons(
                  isSelected: List.generate(dataOptions.length, (index) => index == selectedDataIndex),
                  borderRadius: BorderRadius.circular(12),
                  selectedColor: Colors.black,
                  color: Colors.black54,
                  splashColor: Colors.transparent,
                  fillColor: Colors.transparent,
                  borderWidth: 0,
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 36),
                  onPressed: (index) {
                    setState(() {
                      selectedDataIndex = index;
                    });
                  },
                  children: dataOptions
                      .map(
                        (text) => Container(
                          decoration: BoxDecoration(
                            color: selectedDataIndex == dataOptions.indexOf(text) ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(
                              selectedDataIndex == dataOptions.indexOf(text) ? 12 : 0,
                            ),
                          ),
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          child: _getIconForOption(text), // Gọi hàm trả về Widget
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(width: 30),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ToggleButtons(
                  isSelected: List.generate(timeOptions.length, (index) => index == selectedTimeIndex),
                  borderRadius: BorderRadius.circular(12),
                  selectedColor: Colors.black,
                  color: Colors.black54,
                  splashColor: Colors.transparent,
                  fillColor: Colors.transparent,
                  borderWidth: 0,
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 36),
                  onPressed: (index) {
                    setState(() {
                      selectedTimeIndex = index;
                    });
                  },
                  children: timeOptions
                      .map(
                        (text) => Container(
                          decoration: BoxDecoration(
                            color: selectedTimeIndex == timeOptions.indexOf(text) ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(
                              selectedTimeIndex == timeOptions.indexOf(text) ? 12 : 0,
                            ),
                          ),
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 37),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 12, top: 15, right: 20),
              child: StreamBuilder<List<MonitorData>>(
                stream: RTDBServiceBLE().getListOneNodeInData(nodeName: widget.nodeName),
                builder: (context, snapshot) {
                  debugPrint("Nhảy vô DataStreamPublisher().getListFloor() của ListOfFloors");

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.black),
                      ),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text(
                        'No data available',
                        style: TextStyle(color: Colors.black),
                      ),
                    );
                  }

                  newData = snapshot.data!;

                  switch (selectedTimeIndex) {
                    case 0:
                      _updateChartDataForOneDay(newData);
                      break;
                    case 1:
                      _updateChartDataForOneMonth(newData);
                      break;
                    case 2:
                      _updateChartDataForOneYear(newData);
                      break;
                  }

                  return _LineChart(
                    data: (selectedTimeIndex == 0) ? chartData : ((selectedTimeIndex == 1) ? average_one_hour : average_one_day),
                    isPanEnabled: true,
                    isScaleEnabled: true,
                    transformationController: _transformationController,
                    timeOptions: timeOptions[selectedTimeIndex],
                    dataOptions: dataOptions[selectedDataIndex],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 70),
        ],
      ),
    );
  }

  ////////////////////////////////////////////////////////////////////
  // Thuật toán chưa tối ưu, (sort, where) // Chưa được chọn một ngày cụ thể
  void _updateChartDataForOneDay(List<MonitorData> newData) {
    // Kiểm tra nếu newData rỗng
    if (newData.isEmpty) return;

    // Lọc dữ liệu có timeline không null
    final validData = newData.where((d) => d.timeline != null).toList();

    // Nếu không có dữ liệu hợp lệ, không làm gì
    if (validData.isEmpty) return;

    // Sắp xếp dữ liệu để lấy bản ghi mới nhất
    validData.sort((a, b) => a.timeline!.compareTo(b.timeline!));
    final latestData = validData.last; // Bản ghi mới nhất
    final latestDate = latestData.timeline!;

    // Xác định ngày của bản ghi mới nhất (bỏ qua giờ, phút, giây)
    final latestDayStart = DateTime(latestDate.year, latestDate.month, latestDate.day);

    // Lọc dữ liệu chỉ trong cùng ngày với bản ghi mới nhất
    final filteredData = validData.where((d) {
      final dataDate = d.timeline!;
      // So sánh ngày, tháng, năm
      return dataDate.year == latestDayStart.year && dataDate.month == latestDayStart.month && dataDate.day == latestDayStart.day;
    }).toList();

    // Xóa dữ liệu cũ và thêm dữ liệu mới
    chartData.clear();
    chartData.addAll(filteredData);

    // Sắp xếp lại theo thời gian để đảm bảo thứ tự
    chartData.sort((a, b) => a.timeline!.compareTo(b.timeline!));
  }

  ////////////////////////////////////////////////////////////////////
  // Thuật toán chưa tối ưu, (sort, where) // Chưa được chọn một tháng cụ thể
  void _updateChartDataForOneMonth(List<MonitorData> newData) {
    // Kiểm tra nếu newData rỗng
    if (newData.isEmpty) return;

    // Tìm bản ghi mới nhất và lọc dữ liệu trong cùng tháng
    MonitorData? latestData;
    final filteredData = <MonitorData>[];

    // Giả định stream đã sắp xếp theo thời gian tăng dần
    // Nếu không, cần sort trước: newData.sort((a, b) => a.timeline!.compareTo(b.timeline!));
    newData.sort((a, b) => a.timeline!.compareTo(b.timeline!));
    for (var d in newData) {
      // Kiểm tra timeline không null
      if (d.timeline == null) continue;

      // Cập nhật bản ghi mới nhất
      if (latestData == null || d.timeline!.isAfter(latestData.timeline!)) {
        latestData = d;
      }
    }

    // Nếu không có dữ liệu hợp lệ, không làm gì
    if (latestData == null) return;

    // Xác định tháng của bản ghi mới nhất (bỏ qua ngày, giờ, phút, giây)
    final latestDate = latestData.timeline!;
    final latestMonthStart = DateTime(latestDate.year, latestDate.month, 1);

    // Lọc dữ liệu trong cùng tháng với bản ghi mới nhất
    for (var d in newData) {
      if (d.timeline == null) continue;
      final dataDate = d.timeline!;
      // So sánh năm và tháng
      if (dataDate.year == latestMonthStart.year && dataDate.month == latestMonthStart.month) {
        filteredData.add(d);
      }
    }

    // **Tính dữ liệu trung bình 1 giờ**
    // Nhóm dữ liệu theo giờ
    final Map<DateTime, List<MonitorData>> hourlyData = {};
    for (var d in filteredData) {
      final hourKey = DateTime(
        d.timeline!.year,
        d.timeline!.month,
        d.timeline!.day,
        d.timeline!.hour,
      );
      if (!hourlyData.containsKey(hourKey)) {
        hourlyData[hourKey] = [];
      }
      hourlyData[hourKey]!.add(d);
    }

    // Tính trung bình cho mỗi giờ và thêm vào average_one_hour
    average_one_hour.clear(); // Xóa dữ liệu cũ nếu có
    for (var entry in hourlyData.entries) {
      final hour = entry.key;
      final dataList = entry.value;
      String macAddress = dataList.first.macAddress;

      if (dataList.isNotEmpty) {
        // Tính trung bình các giá trị
        final avgTemp = dataList.map((d) => d.temperature).reduce((a, b) => a + b) / dataList.length;
        final avgHumidity = dataList.map((d) => d.humidity).reduce((a, b) => a + b) / dataList.length;
        final avgSmoke = dataList.map((d) => d.smoke).reduce((a, b) => a + b) / dataList.length;
        final avgRSSI = dataList.map((d) => d.rssi).reduce((a, b) => a + b) / dataList.length;

        // Tạo bản ghi trung bình mới
        final avgData = MonitorData(
          macAddress: macAddress,
          timeline: hour,
          temperature: avgTemp,
          humidity: avgHumidity,
          smoke: avgSmoke,
          rssi: avgRSSI.toInt(),
        );

        average_one_hour.add(avgData);
      }
    }
    debugPrint("New Data $newData");
    debugPrint("Average one hour ${average_one_hour}");
  }

  ////////////////////////////////////////////////////////////////////
  void _updateChartDataForOneYear(List<MonitorData> newData) {
    // Kiểm tra nếu newData rỗng
    if (newData.isEmpty) return;

    // Tìm bản ghi mới nhất
    MonitorData? latestData;
    final filteredData = <MonitorData>[];

    // Giả định stream đã sắp xếp theo thời gian tăng dần
    // Nếu không, cần sort trước: newData.sort((a, b) => a.timeline!.compareTo(b.timeline!));
    newData.sort((a, b) => a.timeline!.compareTo(b.timeline!));
    for (var d in newData) {
      // Kiểm tra timeline không null
      if (d.timeline == null) continue;

      // Cập nhật bản ghi mới nhất
      if (latestData == null || d.timeline!.isAfter(latestData.timeline!)) {
        latestData = d;
      }
    }

    // Nếu không có dữ liệu hợp lệ, không làm gì
    if (latestData == null) return;

    // Xác định năm của bản ghi mới nhất (bỏ qua tháng, ngày, giờ, phút, giây)
    final latestDate = latestData.timeline!;
    final latestYearStart = DateTime(latestDate.year, 1, 1); // Bắt đầu từ ngày 1/1 của năm đó

    // Lọc dữ liệu trong cùng năm với bản ghi mới nhất
    for (var d in newData) {
      if (d.timeline == null) continue;
      final dataDate = d.timeline!;
      // So sánh năm
      if (dataDate.year == latestYearStart.year) {
        filteredData.add(d);
      }
    }

    // **Tính dữ liệu trung bình 1 ngày**
    // Nhóm dữ liệu theo ngày
    final Map<DateTime, List<MonitorData>> dailyData = {};
    for (var d in filteredData) {
      final dayKey = DateTime(
        d.timeline!.year,
        d.timeline!.month,
        d.timeline!.day,
      );
      if (!dailyData.containsKey(dayKey)) {
        dailyData[dayKey] = [];
      }
      dailyData[dayKey]!.add(d);
    }

    // Tính trung bình cho mỗi ngày và thêm vào average_one_day
    average_one_day.clear(); // Xóa dữ liệu cũ nếu có
    for (var entry in dailyData.entries) {
      final day = entry.key;
      final dataList = entry.value;
      String macAddress = dataList.first.macAddress;

      if (dataList.isNotEmpty) {
        // Tính trung bình các giá trị
        final avgTemp = dataList.map((d) => d.temperature).reduce((a, b) => a + b) / dataList.length;
        final avgHumidity = dataList.map((d) => d.humidity).reduce((a, b) => a + b) / dataList.length;
        final avgSmoke = dataList.map((d) => d.smoke).reduce((a, b) => a + b) / dataList.length;
        final avgRSSI = dataList.map((d) => d.rssi).reduce((a, b) => a + b) / dataList.length;

        // Tạo bản ghi trung bình mới
        final avgData = MonitorData(
          macAddress: macAddress,
          timeline: day,
          temperature: avgTemp,
          humidity: avgHumidity,
          smoke: avgSmoke,
          rssi: avgRSSI.toInt(),
        );

        average_one_day.add(avgData);
      }
    }
    debugPrint("New Data $newData");
    debugPrint("Average one day $average_one_day");
  }
}

class _LineChart extends StatefulWidget {
  _LineChart({
    required this.data,
    required this.isPanEnabled,
    required this.isScaleEnabled,
    required this.transformationController,
    required this.timeOptions,
    required this.dataOptions,
  });

  final List<MonitorData> data;
  late TransformationController transformationController;
  late bool isPanEnabled;
  late bool isScaleEnabled;
  late String timeOptions;
  late String dataOptions;

  @override
  State<_LineChart> createState() => _LineChartState();
}

class _LineChartState extends State<_LineChart> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: widget.transformationController,
      builder: (context, Matrix4 value, child) {
        return LineChart(
          transformationConfig: FlTransformationConfig(
            scaleAxis: FlScaleAxis.horizontal,
            minScale: 1.0,
            maxScale: (widget.timeOptions == "1D") ? 12.0 : ((widget.timeOptions == "1M") ? 168.0 : 91.0),
            panEnabled: widget.isPanEnabled,
            scaleEnabled: widget.isScaleEnabled,
            transformationController: widget.transformationController,
          ),
          sampleData1,
        );
      },
    );
  }

  LineChartData get sampleData1 => LineChartData(
        lineTouchData: lineTouchData1,
        gridData: gridData,
        titlesData: titlesData1,
        borderData: borderData,
        lineBarsData: lineBarsData1,
        minX: _getMinX(),
        maxX: _getMaxX(),
        maxY: (widget.dataOptions == "Smoke") ? 2000 : 120,
        minY: 0,
      );

  double _getMinX() {
    if (widget.data.isEmpty) return (DateTime.now().millisecondsSinceEpoch / 1000) - 3600;
    final earliestTime = widget.data.first.timeline!;
    return (earliestTime.millisecondsSinceEpoch / 1000).floorToDouble();
  }

  double _getMaxX() {
    if (widget.data.isEmpty) return DateTime.now().millisecondsSinceEpoch / 1000;
    final latestTime = widget.data.last.timeline!;
    return (latestTime.millisecondsSinceEpoch / 1000).ceilToDouble();
  }

  LineTouchData get lineTouchData1 => LineTouchData(
        handleBuiltInTouches: true,
        touchSpotThreshold: 5,
        getTouchLineStart: (_, __) => -double.infinity,
        getTouchLineEnd: (_, __) => double.infinity,
        getTouchedSpotIndicator: (barData, spotIndexes) {
          if (spotIndexes.isEmpty) return const [];
          return spotIndexes.map((spotIndex) {
            return TouchedSpotIndicatorData(
              const FlLine(
                color: AppColors.contentColorRed,
                strokeWidth: 1.5,
                dashArray: [8, 2],
              ),
              FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: AppColors.contentColorYellow,
                    strokeWidth: 0,
                    strokeColor: AppColors.contentColorYellow,
                  );
                },
              ),
            );
          }).toList();
        },
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
            if (touchedBarSpots.isEmpty) return [];

            final firstSpot = touchedBarSpots.first;
            final dateTime = DateTime.fromMillisecondsSinceEpoch((firstSpot.x * 1000).toInt());

            // Chỉ lấy giá trị Temperature từ đường đầu tiên (index 0)
            final temp = touchedBarSpots.firstWhere((spot) => spot.barIndex == 0, orElse: () => firstSpot).y.toStringAsFixed(1);

            // Tạo danh sách tooltip, chỉ hiển thị cho spot đầu tiên
            return List.generate(touchedBarSpots.length, (index) {
              return index == 0
                  ? LineTooltipItem(
                      '${dateTime.year}/${dateTime.month.toString().padLeft(2, '0')}/'
                      '${dateTime.day.toString().padLeft(2, '0')} '
                      '${dateTime.hour.toString().padLeft(2, '0')}:'
                      '${dateTime.minute.toString().padLeft(2, '0')}:'
                      '${dateTime.second.toString().padLeft(2, '0')}\n',
                      const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      children: [
                        TextSpan(
                          text: (widget.dataOptions == "Temperature") ? 'Temperature: $temp' : ((widget.dataOptions == "Smoke") ? 'Humidity: $temp' : 'Smoke: $temp'),
                          style: const TextStyle(
                            color: Colors.yellow,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    )
                  : const LineTooltipItem('', TextStyle()); // Tooltip trống cho các spot còn lại
            });
          },
          getTooltipColor: (_) => Colors.black.withOpacity(0.5),
          fitInsideHorizontally: true,
          fitInsideVertically: true,
        ),
      );

  FlTitlesData get titlesData1 => FlTitlesData(
        bottomTitles: AxisTitles(sideTitles: bottomTitles),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(sideTitles: leftTitles()),
      );

  Widget leftTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(fontWeight: FontWeight.bold, fontSize: 14);
    return SideTitleWidget(
      meta: meta,
      child: Text("${value.toInt()}", style: style),
    );
  }

  SideTitles leftTitles() => SideTitles(
        getTitlesWidget: leftTitleWidgets,
        showTitles: true,
        interval: (widget.dataOptions == "Smoke") ? 100 : 20,
        reservedSize: 50,
      );

  SideTitles get bottomTitles {
    final scale = widget.transformationController.value.getMaxScaleOnAxis();

    final minX = _getMinX();
    final maxX = _getMaxX();

    final visibleRange = (maxX - minX) / scale;

    final screenWidth = MediaQuery.of(context).size.width - 32;
    final maxLabels = (screenWidth / 60).floor(); // 60px mỗi nhãn

    double interval;
    String Function(DateTime) formatter;
    bool rotateLabel = false;

    // Scale with the ratio of 1 day - Min is 5 minutes
    if (widget.timeOptions == "1D") {
      if (scale < 6) {
        interval = 3600; // 1 giờ
        formatter = (dt) => '${dt.hour}h';
      } else if (scale < 12) {
        interval = 600; // 10 phút
        rotateLabel = true;
        formatter = (dt) => '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
      } else {
        interval = 300; // 5 phút
        rotateLabel = true;
        formatter = (dt) => '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
      }
    }

    // Scale with the ratio of 1 month - Min is average 1 hour
    else if (widget.timeOptions == "1M") {
      if (scale < 7) {
        interval = 7 * 24 * 3600; // 7 ngày
        formatter = (dt) => '${dt.day}/${dt.month}';
      } else if (scale < 168) {
        interval = 24 * 3600; // 1 ngày
        formatter = (dt) => '${dt.day}/${dt.month}';
      } else {
        interval = 3600; // 1  giờ
        formatter = (dt) => '${dt.hour}h';
      }
      // } else if (scale < 1008) {
      //   interval = 3600; // 1  giờ
      //   formatter = (dt) => '${dt.hour}h';
      // } else {
      //   interval = 10 * 60; // 10 phút
      //   rotateLabel = true;
      //   formatter = (dt) => '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
      // }
    }

    // Scale with the ratio of 1 year - Min is average 1 day
    else if (widget.timeOptions == "1Y") {
      if (scale < 3) {
        interval = 3 * 30 * 24 * 3600; // 1 quý (3 tháng)
        formatter = (dt) => '${dt.month}Mon';
      } else if (scale < 13) {
        interval = 30 * 24 * 3600; // 30 ngày (1 tháng)
        formatter = (dt) => '${dt.month}Mon';
      } else if (scale < 91) {
        interval = 7 * 24 * 3600; // 7 ngày (1 tuần)
        formatter = (dt) => '${dt.day}/${dt.month}';
      } else {
        interval = 24 * 3600; // 1 ngày
        formatter = (dt) => '${dt.day}/${dt.month}';
      }
    }

    // ***************** This case has not been handled yet**************
    else {
      // Mặc định cho "All" (nếu có dữ liệu nhiều năm)
      interval = 31536000; // 1 năm
      formatter = (dt) => '${dt.year}';
    }

    // Điều chỉnh interval để không vượt quá maxLabels
    final numLabels = (visibleRange / interval).ceil();
    if (numLabels > maxLabels) {
      interval = (visibleRange / maxLabels).ceilToDouble();
    }

    debugPrint("Scale: $scale, Visible Range: $visibleRange, Max Labels: $maxLabels, Numlabels : $numLabels, Interval = $interval");

    return SideTitles(
      showTitles: true,
      reservedSize: 32,
      interval: interval,
      getTitlesWidget: (value, meta) {
        if (value < minX || value > maxX) return const SizedBox.shrink();

        final dt = DateTime.fromMillisecondsSinceEpoch((value * 1000).toInt());
        return SideTitleWidget(
          meta: meta,
          child: rotateLabel
              ? Transform.rotate(
                  angle: -45 * 3.14 / 180,
                  child: Text(
                    formatter(dt),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                )
              : Text(
                  formatter(dt),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
        );
      },
    );
  }

  FlGridData get gridData => const FlGridData(drawVerticalLine: false);

  FlBorderData get borderData => FlBorderData(
        show: true,
        border: Border(
          bottom: BorderSide(color: AppColors.primary.withOpacity(0.2), width: 4),
          left: const BorderSide(color: Colors.transparent),
          right: const BorderSide(color: Colors.transparent),
          top: const BorderSide(color: Colors.transparent),
        ),
      );

  List<LineChartBarData> get lineBarsData1 {
    if (widget.dataOptions == "Humidity") {
      return [lineChartBarHumidityData]; // Độ ẩm
    } else if (widget.dataOptions == "Temperature") {
      return [lineChartBarTemperatureData]; // Nhiet do
    } else {
      return [lineChartBarSmokeData]; // Khoi
    }
  }

  LineChartBarData get lineChartBarHumidityData => LineChartBarData(
        isCurved: false,
        preventCurveOverShooting: false,
        color: AppColors.contentColorGreen,
        barWidth: 1,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: false),
        spots: _getSpots((data) => data.humidity),
      );

  LineChartBarData get lineChartBarTemperatureData => LineChartBarData(
        isCurved: false,
        preventCurveOverShooting: false,
        color: AppColors.contentColorPink,
        barWidth: 1,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: false),
        spots: _getSpots((data) => data.temperature),
      );

  LineChartBarData get lineChartBarSmokeData => LineChartBarData(
        isCurved: false,
        preventCurveOverShooting: false,
        color: AppColors.contentColorCyan,
        barWidth: 1,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: false),
        spots: _getSpots((data) => data.smoke),
      );

  List<FlSpot> _getSpots(double Function(MonitorData) valueExtractor) {
    if (widget.data.isEmpty) return [];
    return widget.data
        .where((d) => d.timeline != null)
        .map((d) => FlSpot(
              (d.timeline!.millisecondsSinceEpoch / 1000),
              valueExtractor(d),
            ))
        .toList();
  }
}

class _TransformationButtons extends StatelessWidget {
  const _TransformationButtons({
    required this.controller,
  });

  final TransformationController controller;

  @override
  Widget build(BuildContext context) {
    return _buildIconButton(Icons.refresh, "Reset zoom", _transformationReset);
  }

  Widget _buildIconButton(IconData icon, String tooltip, VoidCallback onPressed) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, size: 38),
        onPressed: onPressed,
      ),
    );
  }

  void _transformationReset() {
    controller.value = Matrix4.identity();
  }
}
