import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/monitor_group.dart';
import 'package:intl/intl.dart';
import './alerts_screen.dart';
import 'dart:convert';
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
  String _selectedPeriod = 'Last Hour';
  bool _isLoadingChart = false;
  Map<String, dynamic>? _k8sData;
  Map<String, dynamic>? _tcpData;

  @override
  void initState() {
    super.initState();
    _currentMonitor = widget.monitor;
    _monitorDetails = _fetchMonitorDetails();
    
    // Fetch specific data based on monitor type
    if (widget.monitor.monitorTypeId == 4) {
      _fetchK8sData(widget.monitor.id);
    } else if (widget.monitor.monitorTypeId == 3) {
      _fetchTcpData(widget.monitor.id);
    }
  }

  Future<void> _fetchTcpData(int monitorId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.get(
        Uri.parse(
            '${AppConfig.monitoringApiUrl}/api/Monitor/getMonitorTcpByMonitorId/$monitorId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _tcpData = data;
          });
        }
      } else {
        throw Exception('Failed to load TCP data');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading TCP data: $e')),
        );
      }
    }
  }

  Future<void> _fetchK8sData(int monitorId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.get(
        Uri.parse(
            '${AppConfig.monitoringApiUrl}/api/Monitor/getMonitorK8sByMonitorId/$monitorId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _k8sData = data;
          });
        }
      } else {
        throw Exception('Failed to load Kubernetes data');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading Kubernetes data: $e')),
        );
      }
    }
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
      // Refresh Kubernetes data if this is a K8s monitor
      if (widget.monitor.monitorTypeId == 4) {
        await _fetchK8sData(widget.monitor.id);
      }
      
      if (_selectedPeriod == 'Last Hour') {
        final monitor = await _fetchMonitorDetails();
        setState(() {
          _monitorDetails = Future.value(monitor);
          _currentMonitor = monitor;
        });
      } else {
        final days = {
              'Last 24 Hours': 1,
              'Last 7 Days': 7,
              'Last 30 Days': 30,
              'Last 3 Months': 90,
              'Last 6 Months': 180,
            }[_selectedPeriod] ??
            1;

        final historyData = await _fetchHistoricalData(days);
        if (mounted) {
          setState(() {
            _currentMonitor?.monitorStatusDashboard.historyData = historyData;
          });
        }
      }
    } catch (e) {
      setState(() {
        _monitorDetails = Future.error(e);
      });
    }
  }

  List<FlSpot> _getChartData() {
    if (_currentMonitor == null ||
        _currentMonitor!.monitorStatusDashboard.historyData.isEmpty) {
      return [];
    }

    if (_selectedPeriod == 'Last Hour') {
      // Hourly data logic
      final latestTime = _currentMonitor!.monitorStatusDashboard.historyData
          .map((d) => d.localTimeStamp)
          .reduce((a, b) => a.isAfter(b) ? a : b);
      final oneHourBefore = latestTime.subtract(const Duration(hours: 1));

      final Map<DateTime, List<MonitorHistoryData>> groupedData = {};

      for (var data in _currentMonitor!.monitorStatusDashboard.historyData) {
        final localTime = data.localTimeStamp;
        if (localTime.isAfter(oneHourBefore)) {
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

      return groupedData.entries.map((entry) {
        final hasFailed = entry.value.any((d) => !d.status);
        final avgResponse = hasFailed
            ? 0.0
            : entry.value.map((d) => d.responseTime).reduce((a, b) => a + b) /
                entry.value.length;
        final minutesFromStart = entry.key.difference(oneHourBefore).inMinutes;
        return FlSpot(minutesFromStart / 60, avgResponse.toDouble());
      }).toList()
        ..sort((a, b) => a.x.compareTo(b.x));
    } else {
      // Historical data logic
      final data = _currentMonitor!.monitorStatusDashboard.historyData;
      final startTime = data.first.localTimeStamp;
      final totalDuration = data.last.localTimeStamp.difference(startTime);

      return data.map((point) {
        final x = point.localTimeStamp.difference(startTime).inMilliseconds /
            totalDuration.inMilliseconds;
        return FlSpot(x, point.status ? point.responseTime.toDouble() : 0.0);
      }).toList()
        ..sort((a, b) => a.x.compareTo(b.x));
    }
  }

  List<MonitorHistoryData> _getHistoryDataForSpot(FlSpot spot) {
    if (_currentMonitor == null ||
        _currentMonitor!.monitorStatusDashboard.historyData.isEmpty) {
      return [];
    }

    final latestTime = _currentMonitor!.monitorStatusDashboard.historyData
        .map((d) => d.localTimeStamp)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    final oneHourBefore = latestTime.subtract(const Duration(hours: 1));

    // Calculate the target time based on the spot's x value
    final targetTime =
        oneHourBefore.add(Duration(minutes: (spot.x * 60).round()));
    final windowStart = targetTime.subtract(const Duration(seconds: 30));
    final windowEnd = targetTime.add(const Duration(seconds: 30));

    return _currentMonitor!.monitorStatusDashboard.historyData.where((data) {
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

  Future<List<MonitorHistoryData>> _fetchHistoricalData(int days) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    // Determine sampling factor based on days
    int samplingFactor = 30; // default
    if (days >= 7) samplingFactor = 60; // 1
    if (days >= 30) samplingFactor = 300; // 1 month
    if (days >= 90) samplingFactor = 1000; // 3 months
    if (days >= 180) samplingFactor = 2000; // 6 months

    final response = await http.get(
      Uri.parse(
        '${AppConfig.monitoringApiUrl}/api/MonitorHistory/MonitorHistoryByIdDays/${widget.monitor.id}/$days/true/$samplingFactor',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      return jsonData.map((data) => MonitorHistoryData.fromJson(data)).toList();
    }
    throw Exception('Failed to load history data');
  }

  @override
  Widget build(BuildContext context) {
    // Calculate maxY with dynamic intervals
    final maxResponse = _getChartData().isEmpty
        ? 50.0
        : _getChartData().map((e) => e.y).reduce((a, b) => a > b ? a : b);

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

    final theme = Theme.of(context);
    final statusColor = widget.monitor.paused
        ? const Color(0xFFF59E0B)
        : widget.monitor.status
            ? const Color(0xFF22C55E)
            : const Color(0xFFEF4444);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: statusColor.withOpacity(0.5),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Text(
                widget.monitor.name,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  letterSpacing: -0.3,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: FutureBuilder<Monitor>(
            future: _monitorDetails,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else if (snapshot.hasData) {
                final monitor = snapshot.data!;
                _currentMonitor = monitor;
                final spots = _getChartData();
                final monitorStatusColor = monitor.paused
                    ? const Color(0xFFF59E0B)
                    : monitor.status
                        ? const Color(0xFF22C55E)
                        : const Color(0xFFEF4444);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status + URL card
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Material(
                        color: theme.colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: monitorStatusColor.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          monitor.paused
                                              ? Icons.pause_circle_rounded
                                              : monitor.status
                                                  ? Icons.check_circle_rounded
                                                  : Icons.cancel_rounded,
                                          color: monitorStatusColor,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          monitor.paused
                                              ? 'Paused'
                                              : monitor.status
                                                  ? 'Online'
                                                  : 'Offline',
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: monitorStatusColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Text(
                                monitor.monitorTypeId == 4
                                    ? 'Cluster'
                                    : monitor.monitorTypeId == 3
                                        ? 'Host'
                                        : 'URL',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 4),
                              SelectableText(
                                monitor.monitorTypeId == 4 && _k8sData != null
                                    ? _k8sData!['clusterName'] ?? monitor.checkTarget
                                    : monitor.monitorTypeId == 3 && _tcpData != null
                                        ? "${_tcpData!['ip']}:${_tcpData!['port']}"
                                        : monitor.checkTarget,
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    // Display TCP-specific information if this is a TCP monitor
                    if (monitor.monitorTypeId == 3 && _tcpData != null) ...[
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Material(
                          color: theme.colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.lan_rounded,
                                      size: 20,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'TCP Connection Details',
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                _buildTcpDetailRow('IP Address', _tcpData!['ip'] ?? 'N/A'),
                                _buildTcpDetailRow('Port', _tcpData!['port']?.toString() ?? 'N/A'),
                                _buildTcpDetailRow('Timeout', '${_tcpData!['timeout'] ?? 'N/A'} seconds'),
                                _buildTcpDetailRow('Retries', _tcpData!['retries']?.toString() ?? 'N/A'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                    
                    // Display Kubernetes node status if this is a K8s monitor
                    if (monitor.monitorTypeId == 4 && _k8sData != null) ...[
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Material(
                          color: theme.colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(16),
                          clipBehavior: Clip.antiAlias,
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: (_k8sData!['monitorK8sNodes'] as List?)?.length ?? 0,
                            separatorBuilder: (context, index) => Divider(
                              height: 1,
                              indent: 16,
                              endIndent: 16,
                              color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                            ),
                            itemBuilder: (context, index) {
                              final node = (_k8sData!['monitorK8sNodes'] as List)[index];
                              final bool isReady = node['ready'] ?? false;
                              final nodeColor = isReady ? const Color(0xFF22C55E) : const Color(0xFFEF4444);

                              return ExpansionTile(
                                tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: nodeColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.dns_rounded, color: nodeColor, size: 20),
                                ),
                                title: Text(
                                  node['nodeName'] ?? 'Unknown Node',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildNodeStatusRow('Ready', node['ready'] ?? false),
                                      _buildNodeStatusRow('Memory Pressure', !(node['memoryPressure'] ?? true)),
                                      _buildNodeStatusRow('Disk Pressure', !(node['diskPressure'] ?? true)),
                                      _buildNodeStatusRow('PID Pressure', !(node['pidPressure'] ?? true)),
                                      _buildNodeStatusRow('Kubelet', !(node['kubeletProblem'] ?? true)),
                                      _buildNodeStatusRow('Container Runtime', !(node['containerRuntimeProblem'] ?? true)),
                                      _buildNodeStatusRow('Kernel Deadlock', !(node['kernelDeadlock'] ?? true)),
                                      _buildNodeStatusRow('Filesystem', !(node['filesystemCorruptionProblem'] ?? true)),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 16),
                    // Chart section - Only show for HTTP monitors (type 1)
                    if (monitor.monitorTypeId == 1) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.show_chart_rounded,
                                  size: 20,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Response Time (ms) · $_selectedPeriod',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Material(
                              color: theme.colorScheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: SizedBox(
                              height: 216,
                              child: _isLoadingChart
                                  ? const Center(
                                      child: CircularProgressIndicator())
                                  : LineChart(
                                      LineChartData(
                                        gridData: FlGridData(
                                          show: true,
                                          drawVerticalLine: true,
                                          horizontalInterval: interval,
                                          verticalInterval: 4,
                                          getDrawingHorizontalLine: (value) {
                                            return FlLine(
                                              color: theme.colorScheme.outlineVariant.withOpacity(0.4),
                                              strokeWidth: 1,
                                            );
                                          },
                                          getDrawingVerticalLine: (value) {
                                            return FlLine(
                                              color: theme.colorScheme.outlineVariant.withOpacity(0.4),
                                              strokeWidth: 1,
                                            );
                                          },
                                        ),
                                        titlesData: FlTitlesData(
                                          show: true,
                                          rightTitles: const AxisTitles(
                                            sideTitles:
                                                SideTitles(showTitles: false),
                                          ),
                                          topTitles: const AxisTitles(
                                            sideTitles:
                                                SideTitles(showTitles: false),
                                          ),
                                          bottomTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              reservedSize: 35,
                                              interval:
                                                  _selectedPeriod == 'Last Hour'
                                                      ? 0.2
                                                      : 0.25,
                                              getTitlesWidget: (value, meta) {
                                                if (_selectedPeriod ==
                                                    'Last Hour') {
                                                  final now = DateTime.now();
                                                  final minutesAgo =
                                                      ((1 - value) * 60).round();
                                                  final pointTime = now.subtract(
                                                      Duration(
                                                          minutes: minutesAgo));
                                                  return Text(
                                                    DateFormat('HH:mm')
                                                        .format(pointTime),
                                                    style: GoogleFonts.inter(
                                                      fontSize: 13,
                                                      color: theme.colorScheme.onSurfaceVariant,
                                                    ),
                                                  );
                                                } else {
                                                  if (_currentMonitor
                                                          ?.monitorStatusDashboard
                                                          .historyData
                                                          .isEmpty ??
                                                      true) {
                                                    return const Text('');
                                                  }
                                                  final data = _currentMonitor!
                                                      .monitorStatusDashboard
                                                      .historyData;
                                                  final startTime =
                                                      data.first.localTimeStamp;
                                                  final endTime =
                                                      data.last.localTimeStamp;
                                                  final pointTime =
                                                      startTime.add(Duration(
                                                    milliseconds: (value *
                                                            endTime
                                                                .difference(
                                                                    startTime)
                                                                .inMilliseconds)
                                                        .round(),
                                                  ));

                                                  // Different format based on period length
                                                  String format =
                                                      _selectedPeriod ==
                                                              'Last 24 Hours'
                                                          ? 'HH:mm'
                                                          : 'MM/dd';
                                                  return Text(
                                                    DateFormat(format)
                                                        .format(pointTime),
                                                    style: GoogleFonts.inter(
                                                      fontSize: 13,
                                                      color: theme.colorScheme.onSurfaceVariant,
                                                    ),
                                                  );
                                                }
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
                                                  style: GoogleFonts.inter(
                                                    fontSize: 13,
                                                    color: theme.colorScheme.onSurfaceVariant,
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                        borderData: FlBorderData(
                                          show: true,
                                          border: Border.all(
                                            color: theme.colorScheme.outlineVariant.withOpacity(0.3),
                                          ),
                                        ),
                                        minX: 0,
                                        maxX: 1,
                                        minY: 0,
                                        maxY: defaultMaxY,
                                        clipData: FlClipData.all(),
                                        lineBarsData: [
                                          LineChartBarData(
                                            spots: spots,
                                            isCurved: true,
                                            color: const Color(0xFF22C55E),
                                            barWidth: 2.5,
                                            isStrokeCapRound: true,
                                            dotData: FlDotData(
                                              show: true,
                                              getDotPainter: (spot, percent,
                                                  barData, index) {
                                                final historyData =
                                                    _getHistoryDataForSpot(spot);
                                                final hasFailed = historyData
                                                    .any((d) => !d.status);

                                                if (hasFailed) {
                                                  return FlDotCirclePainter(
                                                    radius: 3,
                                                    color: const Color(0xFFEF4444),
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
                                              color: const Color(0xFF22C55E).withOpacity(0.12),
                                            ),
                                          ),
                                        ],
                                        lineTouchData: LineTouchData(
                                          enabled: true,
                                          touchTooltipData: LineTouchTooltipData(
                                            getTooltipColor:
                                                (LineBarSpot touchedSpot) =>
                                                    theme.colorScheme.surfaceContainerHighest,
                                            getTooltipItems:
                                                (List<LineBarSpot> touchedSpots) {
                                              return touchedSpots
                                                  .map((LineBarSpot touchedSpot) {
                                                final historyData =
                                                    _getHistoryDataForSpot(
                                                        touchedSpot);
                                                final failedRequests = historyData
                                                    .where((d) => !d.status)
                                                    .toList();

                                                // Calculate actual time for this point
                                                final now = DateTime.now();
                                                final pointTime = now.subtract(
                                                    Duration(
                                                        minutes:
                                                            ((1 - touchedSpot.x) *
                                                                    60)
                                                                .round()));

                                                return LineTooltipItem(
                                                  'Avg: ${touchedSpot.y.round()}ms\n'
                                                  '${DateFormat('HH:mm').format(pointTime)}'
                                                  '${failedRequests.isNotEmpty ? '\n${failedRequests.length} Failed Checks' : ''}',
                                                  GoogleFonts.inter(
                                                    color: theme.colorScheme.onSurface,
                                                  ),
                                                );
                                              }).toList();
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    // Statistics section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.analytics_rounded,
                                size: 20,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Uptime Statistics',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          FilledButton.tonal(
                            onPressed: _openAlerts,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  size: 18,
                                  color: Color(0xFFF59E0B),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Alerts',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      child: Material(
                        color: theme.colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                        child: ListView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          children: [
                            _buildUptimeListTile(
                                'Last Hour',
                                widget
                                    .monitor.monitorStatusDashboard.uptime1Hr),
                            _buildListDivider(theme),
                            _buildUptimeListTile(
                                'Last 24 Hours',
                                widget.monitor.monitorStatusDashboard
                                    .uptime24Hrs),
                            _buildListDivider(theme),
                            _buildUptimeListTile(
                                'Last 7 Days',
                                widget.monitor.monitorStatusDashboard
                                    .uptime7Days),
                            _buildListDivider(theme),
                            _buildUptimeListTile(
                                'Last 30 Days',
                                widget.monitor.monitorStatusDashboard
                                    .uptime30Days),
                            _buildListDivider(theme),
                            _buildUptimeListTile(
                                'Last 3 Months',
                                widget.monitor.monitorStatusDashboard
                                    .uptime3Months),
                            _buildListDivider(theme),
                            _buildUptimeListTile(
                                'Last 6 Months',
                                widget.monitor.monitorStatusDashboard
                                    .uptime6Months),
                            if (widget.monitor.monitorTypeId == 1) ...[
                              _buildListDivider(theme),
                              _buildStatListTile(
                                'SSL Certificate Expiry',
                                '${widget.monitor.monitorStatusDashboard.certExpDays} days',
                                widget.monitor.monitorStatusDashboard.certExpDays,
                              ),
                              _buildListDivider(theme),
                              _buildStatListTile(
                                'Average Response Time',
                                '${widget.monitor.monitorStatusDashboard.responseTime.toStringAsFixed(1)}ms',
                                null,
                              ),
                            ],
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

  Widget _buildListDivider(ThemeData theme) {
    return Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: theme.colorScheme.outlineVariant.withOpacity(0.4),
    );
  }

  Widget _buildUptimeListTile(String period, double uptime) {
    final Map<String, int> periodToDays = {
      'Last 24 Hours': 1,
      'Last 7 Days': 7,
      'Last 30 Days': 30,
      'Last 3 Months': 90,
      'Last 6 Months': 180,
    };

    final formattedUptime = uptime.toStringAsFixed(2);
    final color = uptime >= 99.9
        ? const Color(0xFF22C55E)
        : uptime >= 95
            ? const Color(0xFFF59E0B)
            : const Color(0xFFEF4444);

    final isSelected = _selectedPeriod == period;
    final theme = Theme.of(context);

    return Material(
      color: isSelected
          ? theme.colorScheme.primaryContainer.withOpacity(0.4)
          : Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(
          period,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$formattedUptime%',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: color,
            ),
          ),
        ),
        onTap: () async {
          setState(() {
            _selectedPeriod = period;
            _isLoadingChart = true;
          });

          try {
            if (period == 'Last Hour') {
              await _refreshData();
            } else {
              final days = periodToDays[period] ?? 1;
              final historyData = await _fetchHistoricalData(days);
              if (mounted) {
                setState(() {
                  _currentMonitor?.monitorStatusDashboard.historyData =
                      historyData;
                });
              }
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Failed to load historical data'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          } finally {
            if (mounted) {
              setState(() => _isLoadingChart = false);
            }
          }
        },
      ),
    );
  }

  Widget _buildStatListTile(String title, String value, int? certDays) {
    Color? valueColor;

    if (certDays != null) {
      valueColor = certDays > 30
          ? const Color(0xFF22C55E)
          : certDays >= 10
              ? const Color(0xFFF59E0B)
              : const Color(0xFFEF4444);
    } else if (title == 'Average Response Time') {
      final responseTime = widget.monitor.monitorStatusDashboard.responseTime;
      valueColor = responseTime < 500
          ? const Color(0xFF22C55E)
          : responseTime < 1000
              ? const Color(0xFFF59E0B)
              : const Color(0xFFEF4444);
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
      ),
      trailing: valueColor != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: valueColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                value,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: valueColor,
                ),
              ),
            )
          : Text(
              value,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
    );
  }

  Widget _buildNodeStatusRow(String label, bool isHealthy) {
    final color = isHealthy ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isHealthy ? Icons.check_circle_rounded : Icons.error_rounded,
                color: color,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                isHealthy ? 'Healthy' : 'Issue',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildTcpDetailRow(String label, String value) {
    final theme = Theme.of(context);
    Color? valueColor;
    if (label == 'Last Status') {
      valueColor = value == 'Connected'
          ? const Color(0xFF22C55E)
          : const Color(0xFFEF4444);
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor ?? theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
