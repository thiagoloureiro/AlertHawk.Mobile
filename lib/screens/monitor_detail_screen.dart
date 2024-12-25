import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/monitor_group.dart';

class MonitorDetailScreen extends StatefulWidget {
  final Monitor monitor;

  const MonitorDetailScreen({super.key, required this.monitor});

  @override
  State<MonitorDetailScreen> createState() => _MonitorDetailScreenState();
}

class _MonitorDetailScreenState extends State<MonitorDetailScreen> {
  double? minX;
  double? maxX;
  double? minY;
  double? maxY;
  bool isZoomed = false;

  List<FlSpot> _getChartData() {
    final now = DateTime.now();
    final last24Hours = now.subtract(const Duration(hours: 24));

    return widget.monitor.monitorStatusDashboard.historyData
        .where((data) => data.timeStamp.isAfter(last24Hours))
        .map((data) {
      final localTime = data.timeStamp.toLocal();
      final hours = localTime.hour + (localTime.minute / 60.0);
      return FlSpot(hours, data.responseTime.toDouble());
    }).toList();
  }

  void _resetZoom() {
    setState(() {
      minX = null;
      maxX = null;
      minY = null;
      maxY = null;
      isZoomed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final spots = _getChartData();

    // Calculate maxY rounded to next 50
    final maxResponse = spots.isEmpty ? 50.0 : spots.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    final defaultMaxY = ((maxResponse / 50).ceil() * 50).toDouble();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.monitor.name,
          style: GoogleFonts.robotoMono(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (isZoomed)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _resetZoom,
              tooltip: 'Reset zoom',
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Response Time (ms) - Last 24 Hours',
                style: GoogleFonts.robotoMono(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Failed Checks',
                    style: GoogleFonts.robotoMono(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Pinch or select area to zoom',
                    style: GoogleFonts.robotoMono(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.5,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: true,
                      horizontalInterval: 50,
                      verticalInterval: 4,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: isDarkMode
                              ? Colors.grey.shade800
                              : Colors.grey.shade300,
                          strokeWidth: 1,
                        );
                      },
                      getDrawingVerticalLine: (value) {
                        return FlLine(
                          color: isDarkMode
                              ? Colors.grey.shade800
                              : Colors.grey.shade300,
                          strokeWidth: 1,
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: 4,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '${value.toInt()}h',
                              style: GoogleFonts.robotoMono(
                                color: isDarkMode ? Colors.white70 : Colors.black87,
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 50,
                          reservedSize: 42,
                          getTitlesWidget: (value, meta) {
                            // Only show labels for multiples of 50
                            if (value % 50 != 0) {
                              return const SizedBox.shrink();
                            }
                            return Text(
                              value.toInt().toString(),
                              style: GoogleFonts.robotoMono(
                                color: isDarkMode ? Colors.white70 : Colors.black87,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(
                        color: isDarkMode ? Colors.white24 : Colors.black12,
                      ),
                    ),
                    minX: minX ?? 0,
                    maxX: maxX ?? 24,
                    minY: minY ?? 0,
                    maxY: maxY ?? defaultMaxY,
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: Colors.blue,
                        barWidth: 2,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            final historyData = widget.monitor.monitorStatusDashboard.historyData
                                .where((data) => data.timeStamp.isAfter(
                                    DateTime.now().subtract(const Duration(hours: 24))))
                                .toList()[index];
                            
                            if (!historyData.status) {
                              return FlDotCirclePainter(
                                radius: 6,
                                color: Colors.red,
                                strokeWidth: 0,
                              );
                            }
                            
                            return FlDotCirclePainter(
                              radius: 0,
                              color: Colors.transparent,
                              strokeWidth: 0,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.blue.withOpacity(isDarkMode ? 0.15 : 0.1),
                        ),
                      ),
                    ],
                    clipData: FlClipData.all(),
                    lineTouchData: LineTouchData(
                      enabled: true,
                      touchTooltipData: LineTouchTooltipData(
                        tooltipBgColor: isDarkMode 
                            ? Colors.grey.shade800 
                            : Colors.white,
                        getTooltipItems: (List<LineBarSpot> touchedSpots) {
                          return touchedSpots.map((LineBarSpot touchedSpot) {
                            final historyData = widget.monitor.monitorStatusDashboard.historyData
                                .where((data) => data.timeStamp.isAfter(
                                    DateTime.now().subtract(const Duration(hours: 24))))
                                .toList()[touchedSpot.spotIndex];
                            
                            return LineTooltipItem(
                              '${historyData.responseTime}ms\n'
                              '${historyData.timeStamp.toLocal().hour}:'
                              '${historyData.timeStamp.toLocal().minute.toString().padLeft(2, '0')}',
                              GoogleFonts.robotoMono(
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            );
                          }).toList();
                        },
                      ),
                      handleBuiltInTouches: true,
                      touchSpotThreshold: 10,
                    ),
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