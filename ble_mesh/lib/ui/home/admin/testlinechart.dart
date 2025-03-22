import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../cloud_functions/data_stream_publisher.dart';
import '../../../models/data.dart';
import '../../../themes/app_colors.dart';

class LineChartSample1 extends StatefulWidget {
  const LineChartSample1({super.key});

  @override
  State<StatefulWidget> createState() => LineChartSample1State();
}

class LineChartSample1State extends State<LineChartSample1> {
  List<Data> chartData = []; // Danh sách dữ liệu giới hạn cho 1 ngày
  List<Data> newData = []; // Danh sách dữ liệu giới hạn cho 1 ngày

  late TransformationController _transformationController;
  bool _isPanEnabled = true;
  bool _isScaleEnabled = true;
  final List<String> options = ["1D", "1M", "1Y"];
  int selectedIndex = 0; // Mặc định chọn "1D"

  @override
  void initState() {
    _transformationController = TransformationController();

    super.initState();
    // Khởi tạo lắng nghe stream
    DataStreamPublisher().getListOneNodeInData(nodeName: "Server0x136020").listen((newData) {
      setState(() {
        this.newData = newData;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (selectedIndex == 0) {
      _updateChartDataForOneDay(newData);
    } else if (selectedIndex == 1) {
      _updateChartDataForOneMonth(newData);
    } else if (selectedIndex == 2) {
      _updateChartDataForOneYear(newData);
      debugPrint("Hello world");
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          color: Colors.grey,
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: AppColors.itemsBackground,
      body: AspectRatio(
        aspectRatio: 1.5,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 37),
            const Text(
              'Environmental Monitoring',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
              textAlign: TextAlign.center,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _TransformationButtons(
                  controller: _transformationController,
                ),
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
                const SizedBox(width: 20),
                const Text('Scale'),
                Switch(
                  value: _isScaleEnabled,
                  onChanged: (value) {
                    setState(() {
                      _isScaleEnabled = value;
                    });
                  },
                ),
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
                child: _LineChart(
                  data: chartData,
                  isPanEnabled: _isPanEnabled,
                  isScaleEnabled: _isScaleEnabled,
                  transformationController: _transformationController,
                  option: options[selectedIndex],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // Thuật toán chưa tối ưu, (sort, where)
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

    // Xóa dữ liệu cũ và thêm dữ liệu mới
    chartData.clear();
    chartData.addAll(filteredData);

    // Nếu stream không đảm bảo thứ tự, sắp xếp lại
    chartData.sort((a, b) => a.timeline!.compareTo(b.timeline!));
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
            maxScale: (widget.option == "1D") ? 240.0 : ((widget.option == "1M") ? 5760.0 : 5880.0),
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
      } else if (scale < 30) {
        interval = 600; // 10 phút
        formatter = (dt) => '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
      } else if (scale < 240) {
        interval = 120; // 2 phút
        formatter = (dt) => '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
      } else {
        rotateLabel = true;
        interval = 15; // 15s
        formatter = (dt) => '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
      }
    } else if (widget.option == "1M") {
      if (scale < 24) {
        interval = 86400; // 1 ngày
        formatter = (dt) => '${dt.day}/${dt.month}';
      } else if (scale < 144) {
        interval = 3600; // 1 giờ
        formatter = (dt) => '${dt.hour}h';
      } else if (scale < 720) {
        interval = 600; // 10 phút
        formatter = (dt) => '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
      } else if (scale < 5760) {
        interval = 120; // 2 phút
        formatter = (dt) => '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
      } else {
        rotateLabel = true;
        interval = 15; // 15s
        formatter = (dt) => '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
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
      children: [
        Tooltip(
          message: 'Zoom in',
          child: IconButton(
            icon: const Icon(
              Icons.add,
              size: 16,
            ),
            onPressed: _transformationZoomIn,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Tooltip(
              message: 'Move left',
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios,
                  size: 16,
                ),
                onPressed: _transformationMoveLeft,
              ),
            ),
            Tooltip(
              message: 'Reset zoom',
              child: IconButton(
                icon: const Icon(
                  Icons.refresh,
                  size: 16,
                ),
                onPressed: _transformationReset,
              ),
            ),
            Tooltip(
              message: 'Move right',
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                ),
                onPressed: _transformationMoveRight,
              ),
            ),
          ],
        ),
        Tooltip(
          message: 'Zoom out',
          child: IconButton(
            icon: const Icon(
              Icons.minimize,
              size: 16,
            ),
            onPressed: _transformationZoomOut,
          ),
        ),
      ],
    );
  }

  void _transformationReset() {
    controller.value = Matrix4.identity();
  }

  void _transformationZoomIn() {
    controller.value *= Matrix4.diagonal3Values(
      1.1,
      1.1,
      1,
    );
  }

  void _transformationMoveLeft() {
    controller.value *= Matrix4.translationValues(
      20,
      0,
      0,
    );
  }

  void _transformationMoveRight() {
    controller.value *= Matrix4.translationValues(
      -20,
      0,
      0,
    );
  }

  void _transformationZoomOut() {
    controller.value *= Matrix4.diagonal3Values(
      0.9,
      0.9,
      1,
    );
  }
}
