import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/monitor_group.dart';
import 'package:intl/intl.dart';

class MonitorDetailScreen extends StatelessWidget {
  final Monitor monitor;

  const MonitorDetailScreen({super.key, required this.monitor});

  List<FlSpot> _getChartData() {
    final now = DateTime.now();
    final lastHour = now.subtract(const Duration(hours: 1));

    // Group data by 1-minute intervals
    final Map<DateTime, List<MonitorHistoryData>> groupedData = {};

    for (var data in monitor.monitorStatusDashboard.historyData) {
      final localTime = data.localTimeStamp;

      if (localTime.isAfter(lastHour)) {
        // Round to nearest minute
        final roundedTime = DateTime(
          localTime.year,
          localTime.month,
          localTime.day,
          localTime.hour,
          localTime.minute,
        );
        groupedData.putIfAbsent(roundedTime, () => []).add(data);
      }
    }

    // Convert grouped data to spots
    return groupedData.entries.map((entry) {
      final avgResponse =
          entry.value.map((d) => d.responseTime).reduce((a, b) => a + b) /
              entry.value.length;

      // Calculate minutes ago and convert to x-axis position (0-60 minutes)
      final minutesAgo = now.difference(entry.key).inMinutes;
      final x = minutesAgo / 60;

      return FlSpot(1 - x, avgResponse);
    }).toList()
      ..sort((a, b) => a.x.compareTo(b.x))
      ..removeWhere((spot) => spot.x < 0 || spot.x > 1);
  }

  List<MonitorHistoryData> _getHistoryDataForSpot(FlSpot spot) {
    final now = DateTime.now();
    final targetTime =
        now.subtract(Duration(minutes: ((1 - spot.x) * 60).round()));
    final windowStart = targetTime.subtract(const Duration(seconds: 30));
    final windowEnd = targetTime.add(const Duration(seconds: 30));

    return monitor.monitorStatusDashboard.historyData.where((data) {
      final localTime = data.localTimeStamp;
      return localTime.isAfter(windowStart) && localTime.isBefore(windowEnd);
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
                          interval: 0.2,
                          getTitlesWidget: (value, meta) {
                            final now = DateTime.now();
                            final minutesAgo = ((1 - value) * 60).round();
                            final pointTime =
                                now.subtract(Duration(minutes: minutesAgo));

                            return Text(
                              DateFormat('HH:mm').format(pointTime),
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
                    maxX: 1,
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

                            // Calculate actual time for this point
                            final now = DateTime.now();
                            final pointTime = now.subtract(
                                Duration(hours: (24 - touchedSpot.x).round()));

                            return LineTooltipItem(
                              'Avg: ${touchedSpot.y.round()}ms\n'
                              '${DateFormat('HH:mm').format(pointTime)}'
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
