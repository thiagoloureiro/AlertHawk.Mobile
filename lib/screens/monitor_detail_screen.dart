import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/monitor_group.dart';
import 'package:intl/intl.dart';
import './alerts_screen.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class MonitorDetailScreen extends StatefulWidget {
  final Monitor monitor;

  const MonitorDetailScreen({
    super.key,
    required this.monitor,
  });

  @override
  State<MonitorDetailScreen> createState() => _MonitorDetailScreenState();
}

class _MonitorDetailScreenState extends State<MonitorDetailScreen> {
  late Future<Monitor> _monitorDetails;
  Monitor? _currentMonitor;

  @override
  void initState() {
    super.initState();
    _currentMonitor = widget.monitor;
    _monitorDetails = Future.value(widget.monitor);
  }

  Future<Monitor> _fetchMonitorDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final response = await http.get(
      Uri.parse(
          '${AppConfig.monitoringApiUrl}/api/MonitorGroup/monitorDashboardGroupListByUser/${widget.monitor.monitorEnvironment}'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> groups = json.decode(response.body);
      // Find the monitor in the groups
      for (var group in groups) {
        final monitors = (group['monitors'] as List<dynamic>)
            .map((m) => Monitor.fromJson(m))
            .where((m) => m.id == widget.monitor.id);
        if (monitors.isNotEmpty) {
          return monitors.first;
        }
      }
      throw Exception('Monitor not found');
    } else {
      throw Exception('Failed to load monitor details');
    }
  }

  Future<void> _refreshData() async {
    try {
      final monitor = await _fetchMonitorDetails();
      setState(() {
        _currentMonitor = monitor;
        _monitorDetails = Future.value(monitor);
      });
    } catch (e) {
      setState(() {
        _monitorDetails = Future.error(e);
      });
    }
  }

  List<FlSpot> _getChartData() {
    if (widget.monitor.monitorStatusDashboard.historyData.isEmpty) {
      return [];
    }

    // Find the latest timestamp from the data
    final latestTime = widget.monitor.monitorStatusDashboard.historyData
        .map((d) => d.localTimeStamp)
        .reduce((a, b) => a.isAfter(b) ? a : b);

    // Calculate the time one hour before the latest timestamp
    final oneHourBefore = latestTime.subtract(const Duration(hours: 1));

    // Group data by 1-minute intervals
    final Map<DateTime, List<MonitorHistoryData>> groupedData = {};

    for (var data in widget.monitor.monitorStatusDashboard.historyData) {
      final localTime = data.localTimeStamp;

      if (localTime.isAfter(oneHourBefore)) {
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
      // Check if any data point in this minute had a failed status
      final hasFailed = entry.value.any((d) => !d.status);

      // If failed, set response time to 0, otherwise calculate average
      final avgResponse = hasFailed
          ? 0.0
          : entry.value.map((d) => d.responseTime).reduce((a, b) => a + b) /
              entry.value.length;

      // Calculate minutes from the start and convert to x-axis position (0-60 minutes)
      final minutesFromStart = entry.key.difference(oneHourBefore).inMinutes;
      final x = minutesFromStart / 60;

      return FlSpot(x, avgResponse);
    }).toList()
      ..sort((a, b) => a.x.compareTo(b.x));
  }

  List<MonitorHistoryData> _getHistoryDataForSpot(FlSpot spot) {
    if (widget.monitor.monitorStatusDashboard.historyData.isEmpty) {
      return [];
    }

    final latestTime = widget.monitor.monitorStatusDashboard.historyData
        .map((d) => d.localTimeStamp)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    final oneHourBefore = latestTime.subtract(const Duration(hours: 1));

    // Calculate the target time based on the spot's x value
    final targetTime =
        oneHourBefore.add(Duration(minutes: (spot.x * 60).round()));
    final windowStart = targetTime.subtract(const Duration(seconds: 30));
    final windowEnd = targetTime.add(const Duration(seconds: 30));

    return widget.monitor.monitorStatusDashboard.historyData.where((data) {
      final localTime = data.localTimeStamp;
      return localTime.isAfter(windowStart) && localTime.isBefore(windowEnd);
    }).toList();
  }

  void _openAlerts() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AlertsScreen(monitorId: widget.monitor.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final spots = _getChartData();

    // Calculate maxY with dynamic intervals
    final maxResponse = spots.isEmpty
        ? 50.0
        : spots.map((e) => e.y).reduce((a, b) => a > b ? a : b);

    // Calculate interval and max Y value to have at most 12 intervals
    double calculateInterval(double maxValue) {
      // Base intervals to try: 1, 2, 5, 10, 20, 50, 100, 200, 500, 1000...
      double baseInterval = 1;
      while (true) {
        if (maxValue / baseInterval <= 12) return baseInterval;
        if (maxValue / (baseInterval * 2) <= 12) return baseInterval * 2;
        if (maxValue / (baseInterval * 5) <= 12) return baseInterval * 5;
        baseInterval *= 10;
      }
    }

    final interval = calculateInterval(maxResponse);
    final defaultMaxY = (maxResponse / interval).ceil() * interval;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.monitor.name,
          style: GoogleFonts.robotoMono(fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: FutureBuilder<Monitor>(
            future: _monitorDetails,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else if (snapshot.hasData) {
                final monitor = snapshot.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Row(
                        children: [
                          Text(
                            widget.monitor.monitorTcp != null
                                ? 'Host: '
                                : 'URL: ',
                            style: GoogleFonts.robotoMono(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Expanded(
                            child: SelectableText(
                              widget.monitor.checkTarget,
                              style: GoogleFonts.robotoMono(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Response Time (ms) - Last Hour',
                      style: GoogleFonts.robotoMono(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Legend
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
                    // Chart with fixed height
                    SizedBox(
                      height: 216,
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: true,
                            horizontalInterval: interval,
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
                                  final pointTime = now
                                      .subtract(Duration(minutes: minutesAgo));

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
                                interval: interval,
                                reservedSize: 42,
                                getTitlesWidget: (value, meta) {
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
                              color:
                                  isDarkMode ? Colors.white24 : Colors.black12,
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
                              color: Colors.green,
                              barWidth: 2,
                              isStrokeCapRound: true,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (spot, percent, barData, index) {
                                  final historyData =
                                      _getHistoryDataForSpot(spot);
                                  final hasFailed =
                                      historyData.any((d) => !d.status);

                                  if (hasFailed) {
                                    return FlDotCirclePainter(
                                      radius: 3,
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
                                color: Colors.green
                                    .withOpacity(isDarkMode ? 0.15 : 0.1),
                              ),
                            ),
                          ],
                          lineTouchData: LineTouchData(
                            enabled: true,
                            touchTooltipData: LineTouchTooltipData(
                              tooltipBgColor: isDarkMode
                                  ? Colors.grey.shade800
                                  : Colors.white,
                              getTooltipItems:
                                  (List<LineBarSpot> touchedSpots) {
                                return touchedSpots
                                    .map((LineBarSpot touchedSpot) {
                                  final historyData =
                                      _getHistoryDataForSpot(touchedSpot);
                                  final failedRequests = historyData
                                      .where((d) => !d.status)
                                      .toList();

                                  // Calculate actual time for this point
                                  final now = DateTime.now();
                                  final pointTime = now.subtract(Duration(
                                      minutes:
                                          ((1 - touchedSpot.x) * 60).round()));

                                  return LineTooltipItem(
                                    'Avg: ${touchedSpot.y.round()}ms\n'
                                    '${DateFormat('HH:mm').format(pointTime)}'
                                    '${failedRequests.isNotEmpty ? '\n${failedRequests.length} Failed Checks' : ''}',
                                    GoogleFonts.robotoMono(
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  );
                                }).toList();
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Statistics section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Uptime Statistics',
                            style: GoogleFonts.robotoMono(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _openAlerts,
                            icon: const Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.amber,
                            ),
                            label: Text(
                              'Alerts',
                              style: GoogleFonts.robotoMono(
                                color: Colors.red,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Statistics cards with padding at the bottom
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Card(
                        child: ListView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _buildUptimeListTile(
                                'Last Hour',
                                widget
                                    .monitor.monitorStatusDashboard.uptime1Hr),
                            const Divider(height: 1),
                            _buildUptimeListTile(
                                'Last 24 Hours',
                                widget.monitor.monitorStatusDashboard
                                    .uptime24Hrs),
                            const Divider(height: 1),
                            _buildUptimeListTile(
                                'Last 7 Days',
                                widget.monitor.monitorStatusDashboard
                                    .uptime7Days),
                            const Divider(height: 1),
                            _buildUptimeListTile(
                                'Last 30 Days',
                                widget.monitor.monitorStatusDashboard
                                    .uptime30Days),
                            const Divider(height: 1),
                            _buildUptimeListTile(
                                'Last 3 Months',
                                widget.monitor.monitorStatusDashboard
                                    .uptime3Months),
                            const Divider(height: 1),
                            _buildUptimeListTile(
                                'Last 6 Months',
                                widget.monitor.monitorStatusDashboard
                                    .uptime6Months),
                            const Divider(height: 1),
                            _buildStatListTile(
                              'SSL Certificate Expiry',
                              '${widget.monitor.monitorStatusDashboard.certExpDays} days',
                              widget.monitor.monitorStatusDashboard.certExpDays,
                            ),
                            const Divider(height: 1),
                            _buildStatListTile(
                              'Average Response Time',
                              '${widget.monitor.monitorStatusDashboard.responseTime.toStringAsFixed(1)}ms',
                              null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              } else {
                return Text('No data available');
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildUptimeListTile(String period, double uptime) {
    final formattedUptime = uptime.toStringAsFixed(2);
    final color = uptime >= 99.9
        ? Colors.green
        : uptime >= 95
            ? Colors.orange
            : Colors.red;

    return ListTile(
      title: Text(
        period,
        style: GoogleFonts.robotoMono(
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Text(
        '$formattedUptime%',
        style: GoogleFonts.robotoMono(
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
      dense: true,
    );
  }

  Widget _buildStatListTile(String title, String value, int? certDays) {
    Color? valueColor;

    if (certDays != null) {
      // Color coding for SSL certificate expiration
      valueColor = certDays > 30
          ? Colors.green
          : certDays >= 10
              ? Colors.orange
              : Colors.red;
    } else if (title == 'Average Response Time') {
      // Color coding for response time
      final responseTime = widget.monitor.monitorStatusDashboard.responseTime;
      valueColor = responseTime < 500
          ? Colors.green
          : responseTime < 1000
              ? Colors.orange
              : Colors.red;
    }

    return ListTile(
      title: Text(
        title,
        style: GoogleFonts.robotoMono(
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Text(
        value,
        style: GoogleFonts.robotoMono(
          fontWeight: FontWeight.bold,
          color: valueColor,
        ),
      ),
      dense: true,
    );
  }
}
