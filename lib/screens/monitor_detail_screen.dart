import 'dart:math' show min, max;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/monitor_group.dart';
import '../config/app_config.dart';

class MonitorDetailScreen extends StatelessWidget {
  final Monitor monitor;

  const MonitorDetailScreen({super.key, required this.monitor});

  List<FlSpot> _getChartData() {
    final now = DateTime.now();
    final last24Hours = now.subtract(const Duration(hours: 24));

    // Group data by 10-minute intervals
    final Map<int, List<MonitorHistoryData>> groupedData = {};

    for (var data in monitor.monitorStatusDashboard.historyData) {
      if (data.timeStamp.isAfter(last24Hours)) {
        // Convert timestamp to 10-minute interval key
        final timeKey =
            (data.timeStamp.hour * 60 + data.timeStamp.minute) ~/ 10;
        groupedData.putIfAbsent(timeKey, () => []).add(data);
      }
    }

    // Convert grouped data to spots
    return groupedData.entries.map((entry) {
      // Calculate average response time for the interval
      final avgResponse =
          entry.value.map((d) => d.responseTime).reduce((a, b) => a + b) /
              entry.value.length;

      // Convert time key back to hours
      final hours = (entry.key * 10) / 60;

      // Check if any request in this interval failed
      final hasFailed = entry.value.any((d) => !d.status);

      return FlSpot(hours, avgResponse);
    }).toList()
      ..sort((a, b) => a.x.compareTo(b.x)); // Ensure spots are sorted by time
  }

  // Add this helper method to get history data for a specific spot
  List<MonitorHistoryData> _getHistoryDataForSpot(FlSpot spot) {
    final timeKey = (spot.x * 60).round() ~/
        10; // Convert hours back to 10-minute interval key
    final startMinute = timeKey * 10;
    final endMinute = startMinute + 10;

    return monitor.monitorStatusDashboard.historyData
        .where((data) => data.timeStamp
            .isAfter(DateTime.now().subtract(const Duration(hours: 24))))
        .where((data) {
      final minutes = data.timeStamp.hour * 60 + data.timeStamp.minute;
      return minutes >= startMinute && minutes < endMinute;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final spots = _getChartData();

    // Calculate maxY rounded to next 50
    final maxResponse = spots.isEmpty
        ? 50.0
        : spots.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    final defaultMaxY = ((maxResponse / 50).ceil() * 50).toDouble();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          monitor.name,
          style: GoogleFonts.robotoMono(fontWeight: FontWeight.bold),
        ),
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
                                color: isDarkMode
                                    ? Colors.white70
                                    : Colors.black87,
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
                            if (value % 50 != 0) {
                              return const SizedBox.shrink();
                            }
                            return Text(
                              value.toInt().toString(),
                              style: GoogleFonts.robotoMono(
                                color: isDarkMode
                                    ? Colors.white70
                                    : Colors.black87,
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
                    minX: 0,
                    maxX: 24,
                    minY: 0,
                    maxY: defaultMaxY,
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
                            final historyData = _getHistoryDataForSpot(spot);
                            final hasFailed = historyData.any((d) => !d.status);

                            if (hasFailed) {
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
                          color:
                              Colors.blue.withOpacity(isDarkMode ? 0.15 : 0.1),
                        ),
                      ),
                    ],
                    lineTouchData: LineTouchData(
                      enabled: true,
                      touchTooltipData: LineTouchTooltipData(
                        tooltipBgColor:
                            isDarkMode ? Colors.grey.shade800 : Colors.white,
                        getTooltipItems: (List<LineBarSpot> touchedSpots) {
                          return touchedSpots.map((LineBarSpot touchedSpot) {
                            final historyData =
                                _getHistoryDataForSpot(touchedSpot);
                            final failedRequests =
                                historyData.where((d) => !d.status).toList();
                            final hour = touchedSpot.x.floor();
                            final minute =
                                ((touchedSpot.x - hour) * 60).round();

                            return LineTooltipItem(
                              'Avg: ${touchedSpot.y.round()}ms\n'
                              '$hour:${minute.toString().padLeft(2, '0')}'
                              '${failedRequests.isNotEmpty ? '\n${failedRequests.length} Failed Checks' : ''}',
                              GoogleFonts.robotoMono(
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            );
                          }).toList();
                        },
                      ),
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
