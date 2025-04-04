import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../cloud_functions/data_stream_publisher.dart';
import '../../../models/data.dart';
import '../../../themes/app_colors.dart';

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
  List<Data> chartData = []; // Danh sách dữ liệu giới hạn cho 1 ngày
  List<Data> newData = []; // Danh sách dữ liệu giới hạn cho 1 ngày
  List<Data> average_one_hour = []; // Danh sách trung bình 1 giờ
  List<Data> average_one_day = []; // Danh sách trung bình 1 ngày

  late TransformationController _transformationController;
  bool _isPanEnabled = true;
  bool _isScaleEnabled = true;
  final List<String> options = ["1D", "1M", "1Y"];
  int selectedIndex = 0; // Mặc định chọn "1D"

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
          color: Colors.grey,
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: SizedBox(
          width: double.infinity,
          child: Text(
            widget.nodeName,
            textAlign: TextAlign.center,
            softWrap: true, // Cho phép xuống dòng
            maxLines: 2, // Giới hạn tối đa 2 dòng
          ),
        ),
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: AppColors.primary,
          fontSize: 28,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
      floatingActionButton: Align(
        alignment: Alignment.bottomRight,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.blue, // Màu nền cho TransformationButtons
            borderRadius: BorderRadius.circular(50),
          ),
          child: _TransformationButtons(
            controller: _transformationController,
          ),
        ),
      ),
      body: AspectRatio(
        aspectRatio: 3 / 4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.max,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(width: 20),
                const Text('Pan'),
                Switch(
                  value: _isPanEnabled,
                  onChanged: (value) {
                    setState(() {
                      _isPanEnabled = value;
                    });
                  },
                ),
                const SizedBox(width: 10),
                const Text('Scale'),
                Switch(
                  value: _isScaleEnabled,
                  onChanged: (value) {
                    setState(() {
                      _isScaleEnabled = value;
                    });
                  },
                ),
                const SizedBox(width: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ToggleButtons(
                    isSelected: List.generate(options.length, (index) => index == selectedIndex),
                    borderRadius: BorderRadius.circular(12),
                    selectedColor: Colors.black,
                    color: Colors.black54,
                    fillColor: Colors.white,
                    splashColor: Colors.transparent,
                    borderWidth: 0,
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 36),
                    onPressed: (index) {
                      setState(() {
                        selectedIndex = index;
                      });
                    },
                    children: options
                        .map((text) => Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 37),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: StreamBuilder<List<Data>>(
                  stream: DataStreamPublisher().getListOneNodeInData(nodeName: widget.nodeName),
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

                    switch (selectedIndex) {
                      case 0:
                        _updateChartDataForOneDay(newData);
                        break;
                      case 1:
                        _updateChartDataForOneMonth(newData);
                        break;
                      case 2:
                        _updateChartDataForOneYear(newData);
                        debugPrint("Hello world");
                        break;
                    }

                    return _LineChart(
                      data: (selectedIndex == 0) ? chartData : average_one_hour,
                      isPanEnabled: _isPanEnabled,
                      isScaleEnabled: _isScaleEnabled,
                      transformationController: _transformationController,
                      option: options[selectedIndex],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Thuật toán chưa tối ưu, (sort, where) // Chưa được chọn một ngày cụ thể
  void _updateChartDataForOneDay(List<Data> newData) {
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

  // Thuật toán chưa tối ưu, (sort, where) // Chưa được chọn một tháng cụ thể
  void _updateChartDataForOneMonth(List<Data> newData) {
    // Kiểm tra nếu newData rỗng
    if (newData.isEmpty) return;

    // Tìm bản ghi mới nhất và lọc dữ liệu trong cùng tháng
    Data? latestData;
    final filteredData = <Data>[];

    // Giả định stream đã sắp xếp theo thời gian tăng dần
    // Nếu không, cần sort trước: newData.sort((a, b) => a.timeline!.compareTo(b.timeline!));
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

    // Nếu stream không đảm bảo thứ tự, sắp xếp lại filteredData
    filteredData.sort((a, b) => a.timeline!.compareTo(b.timeline!));

    // **Tính dữ liệu trung bình 1 giờ**
    // Nhóm dữ liệu theo giờ
    final Map<DateTime, List<Data>> hourlyData = {};
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
        final avgData = Data(
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

  void _updateChartDataForOneYear(List<Data> newData) {
    // Kiểm tra nếu newData rỗng
    if (newData.isEmpty) return;

    // Tìm bản ghi mới nhất
    Data? latestData;
    final filteredData = <Data>[];

    // Giả định stream đã sắp xếp theo thời gian tăng dần
    // Nếu không, cần sort trước: newData.sort((a, b) => a.timeline!.compareTo(b.timeline!));
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

    // Xóa dữ liệu cũ và thêm dữ liệu mới
    chartData.clear();
    chartData.addAll(filteredData);

    // Nếu stream không đảm bảo thứ tự, sắp xếp lại
    chartData.sort((a, b) => a.timeline!.compareTo(b.timeline!));
  }
}

class _LineChart extends StatefulWidget {
  _LineChart({
    required this.data,
    required this.isPanEnabled,
    required this.isScaleEnabled,
    required this.transformationController,
    required this.option,
  });

  final List<Data> data;
  late TransformationController transformationController;
  late bool isPanEnabled;
  late bool isScaleEnabled;
  late String option;

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
            maxScale: (widget.option == "1D") ? 12.0 : ((widget.option == "1M") ? 1008.0 : 5880.0),
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
        maxY: 400,
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

            // Gom dữ liệu lại
            Map<int, double> values = {};
            for (var barSpot in touchedBarSpots) {
              values[barSpot.barIndex] = barSpot.y;
            }

            String temp = values[0]?.toStringAsFixed(1) ?? 'N/A';
            String hum = values[1]?.toStringAsFixed(1) ?? 'N/A';
            String smoke = values[2]?.toStringAsFixed(1) ?? 'N/A';

            // Tạo danh sách với cùng độ dài, nhưng chỉ tooltip đầu tiên chứa dữ liệu
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
                          text: 'Temperature: $temp \nHumidity: $hum \nSmoke: $smoke',
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
        interval: 20,
        reservedSize: 40,
      );

  SideTitles get bottomTitles {
    final scale = widget.transformationController.value.getMaxScaleOnAxis();

    final minX = _getMinX();
    final maxX = _getMaxX();

    debugPrint("Min X : $minX");
    debugPrint("Max X : $maxX");

    final visibleRange = (maxX - minX) / scale;

    final screenWidth = MediaQuery.of(context).size.width - 32;
    final maxLabels = (screenWidth / 60).floor(); // 60px mỗi nhãn

    double interval;
    String Function(DateTime) formatter;
    bool rotateLabel = false;

    if (widget.option == "1D") {
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
    } else if (widget.option == "1M") {
      if (scale < 7) {
        interval = 7 * 24 * 3600; // 7 ngày
        formatter = (dt) => '${dt.day}/${dt.month}';
      } else if (scale < 168) {
        interval = 24 * 3600; // 1 ngày
        formatter = (dt) => '${dt.day}/${dt.month}';
      } else if (scale < 1008) {
        interval = 3600; // 1  giờ
        formatter = (dt) => '${dt.hour}h';
      } else {
        interval = 10 * 60; // 10 phút
        rotateLabel = true;
        formatter = (dt) => '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
      }
    } else if (widget.option == "1Y") {
      if (scale < 5) {
        interval = 30 * 24 * 3600; // 30 ngày (1 tháng)
        formatter = (dt) => '${dt.month}Mon';
      } else if (scale < 35) {
        interval = 7 * 24 * 3600; // 7 ngày (1 tuần)
        formatter = (dt) => '${dt.day}/${dt.month}';
      } else if (scale < 245) {
        interval = 24 * 3600; // 1 ngày
        formatter = (dt) => '${dt.day}/${dt.month}';
      } else if (scale < 5880) {
        interval = 1 * 3600; // 1 giờ
        formatter = (dt) => '${dt.hour}h';
      } else {
        interval = 1 * 3600; // 1 giờ
        formatter = (dt) => '${dt.hour}h';
      }
    } else {
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

  List<LineChartBarData> get lineBarsData1 => [
        lineChartBarData1_1, // Độ ẩm
        // lineChartBarData1_2, // Nhiệt độ
        // lineChartBarData1_3, // Khói
      ];

  LineChartBarData get lineChartBarData1_1 => LineChartBarData(
        isCurved: true,
        preventCurveOverShooting: true,
        color: AppColors.contentColorGreen,
        barWidth: 1,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: false),
        spots: _getSpots((data) => data.humidity),
      );

  LineChartBarData get lineChartBarData1_2 => LineChartBarData(
        isCurved: true,
        preventCurveOverShooting: true,
        color: AppColors.contentColorPink,
        barWidth: 2,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: false),
        spots: _getSpots((data) => data.temperature),
      );

  LineChartBarData get lineChartBarData1_3 => LineChartBarData(
        isCurved: true,
        preventCurveOverShooting: true,
        color: AppColors.contentColorCyan,
        barWidth: 2,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: false),
        spots: _getSpots((data) => data.smoke),
      );

  List<FlSpot> _getSpots(double Function(Data) valueExtractor) {
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildIconButton(Icons.add, "Zoom in", _transformationZoomIn),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIconButton(Icons.arrow_back_ios, "Move left", _transformationMoveLeft),
            _buildIconButton(Icons.refresh, "Reset zoom", _transformationReset),
            _buildIconButton(Icons.arrow_forward_ios, "Move right", _transformationMoveRight),
          ],
        ),
        _buildIconButton(Icons.minimize, "Zoom out", _transformationZoomOut),
      ],
    );
  }

  Widget _buildIconButton(IconData icon, String tooltip, VoidCallback onPressed) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, size: 30),
        onPressed: onPressed,
      ),
    );
  }

  void _transformationReset() {
    controller.value = Matrix4.identity();
  }

  void _transformationZoomIn() {
    controller.value *= Matrix4.diagonal3Values(1.1, 1.1, 1);
  }

  void _transformationMoveLeft() {
    controller.value *= Matrix4.translationValues(20, 0, 0);
  }

  void _transformationMoveRight() {
    controller.value *= Matrix4.translationValues(-20, 0, 0);
  }

  void _transformationZoomOut() {
    controller.value *= Matrix4.diagonal3Values(0.9, 0.9, 1);
  }
}
