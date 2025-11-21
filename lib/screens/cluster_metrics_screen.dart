import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/metrics_service.dart';
import '../models/node_metric.dart';
import 'package:intl/intl.dart';

class ClusterMetricsScreen extends StatefulWidget {
  const ClusterMetricsScreen({super.key});

  @override
  State<ClusterMetricsScreen> createState() => _ClusterMetricsScreenState();
}

class _ClusterMetricsScreenState extends State<ClusterMetricsScreen> {
  List<String> _clusters = [];
  String? _selectedCluster;
  List<NodeMetric> _metrics = [];
  bool _isLoadingClusters = false;
  bool _isLoadingMetrics = false;
  String? _errorMessage;
  int _selectedHours = 24;

  @override
  void initState() {
    super.initState();
    _loadClusters();
  }

  Future<void> _loadClusters() async {
    setState(() {
      _isLoadingClusters = true;
      _errorMessage = null;
    });

    try {
      final clusters = await MetricsService.getClusters();

      setState(() {
        _clusters = clusters;
        if (clusters.isNotEmpty && _selectedCluster == null) {
          _selectedCluster = clusters.first;
          _loadMetrics();
        }
        _isLoadingClusters = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = ' ${e.toString()}';
        _isLoadingClusters = false;
      });
    }
  }

  Future<void> _loadMetrics() async {
    if (_selectedCluster == null) return;

    setState(() {
      _isLoadingMetrics = true;
      _errorMessage = null;
    });

    try {
      final metrics = await MetricsService.getNodeMetrics(
        clusterName: _selectedCluster!,
        hours: _selectedHours,
        limit: 100,
      );
      setState(() {
        _metrics = metrics;
        _isLoadingMetrics = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load metrics: ${e.toString()}';
        _isLoadingMetrics = false;
      });
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  List<FlSpot> _getCpuChartData() {
    if (_metrics.isEmpty) return [];

    final sortedMetrics = List<NodeMetric>.from(_metrics)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return sortedMetrics.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final metric = entry.value;
      return FlSpot(index, metric.cpuUsagePercent);
    }).toList();
  }

  List<FlSpot> _getMemoryChartData() {
    if (_metrics.isEmpty) return [];

    final sortedMetrics = List<NodeMetric>.from(_metrics)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return sortedMetrics.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final metric = entry.value;
      return FlSpot(index, metric.memoryUsagePercent);
    }).toList();
  }

  List<String> _getTimeLabels() {
    if (_metrics.isEmpty) return [];

    final sortedMetrics = List<NodeMetric>.from(_metrics)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return sortedMetrics.map((metric) {
      return DateFormat('HH:mm').format(metric.timestamp);
    }).toList();
  }

  Map<String, List<NodeMetric>> _groupByNode() {
    final Map<String, List<NodeMetric>> grouped = {};
    for (var metric in _metrics) {
      grouped.putIfAbsent(metric.nodeName, () => []).add(metric);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Cluster Metrics',
          style: GoogleFonts.robotoMono(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Consumer<ThemeProvider>(
              builder: (context, themeProvider, _) => Icon(
                themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              ),
            ),
            onPressed: () {
              Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadClusters();
          if (_selectedCluster != null) {
            await _loadMetrics();
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Cluster selector
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Cluster',
                          style: GoogleFonts.robotoMono(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _isLoadingClusters
                            ? const Center(child: CircularProgressIndicator())
                            : DropdownButtonFormField<String>(
                                value: _selectedCluster,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                style: GoogleFonts.robotoMono(
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                                dropdownColor: isDarkMode
                                    ? Colors.grey[800]
                                    : Colors.white,
                                items: _clusters.map((cluster) {
                                  return DropdownMenuItem<String>(
                                    value: cluster,
                                    child: Text(
                                      cluster,
                                      style: GoogleFonts.robotoMono(
                                        color: isDarkMode
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedCluster = value;
                                  });
                                  _loadMetrics();
                                },
                              ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Text(
                              'Time Range:',
                              style: GoogleFonts.robotoMono(),
                            ),
                            const SizedBox(width: 8),
                            DropdownButton<int>(
                              value: _selectedHours,
                              style: GoogleFonts.robotoMono(
                                color: isDarkMode
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                              dropdownColor: isDarkMode
                                  ? Colors.grey[800]
                                  : Colors.white,
                              items: [1, 6, 12, 24, 48, 72].map((hours) {
                                return DropdownMenuItem<int>(
                                  value: hours,
                                  child: Text(
                                    '$hours hours',
                                    style: GoogleFonts.robotoMono(
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedHours = value;
                                  });
                                  _loadMetrics();
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Card(
                    color: Colors.red.shade100,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        _errorMessage!,
                        style:
                            GoogleFonts.robotoMono(color: Colors.red.shade900),
                      ),
                    ),
                  ),
                ],
                if (_isLoadingMetrics) ...[
                  const SizedBox(height: 16),
                  const Center(child: CircularProgressIndicator()),
                ],
                if (!_isLoadingMetrics && _metrics.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  // CPU Usage Chart
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CPU Usage (%)',
                            style: GoogleFonts.robotoMono(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 250,
                            child: LineChart(
                              LineChartData(
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: true,
                                  horizontalInterval: 25,
                                  getDrawingHorizontalLine: (value) {
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
                                      interval: _metrics.length > 10
                                          ? _metrics.length / 5
                                          : 1,
                                      getTitlesWidget: (value, meta) {
                                        final index = value.toInt();
                                        if (index >= 0 &&
                                            index < _metrics.length) {
                                          final sortedMetrics =
                                              List<NodeMetric>.from(_metrics)
                                                ..sort((a, b) => a.timestamp
                                                    .compareTo(b.timestamp));
                                          return Padding(
                                            padding:
                                                const EdgeInsets.only(top: 8.0),
                                            child: Text(
                                              DateFormat('HH:mm').format(
                                                  sortedMetrics[index]
                                                      .timestamp),
                                              style: GoogleFonts.robotoMono(
                                                fontSize: 10,
                                                color: isDarkMode
                                                    ? Colors.grey.shade400
                                                    : Colors.grey.shade700,
                                              ),
                                            ),
                                          );
                                        }
                                        return const Text('');
                                      },
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 50,
                                      interval: 25,
                                      getTitlesWidget: (value, meta) {
                                        return Text(
                                          '${value.toInt()}%',
                                          style: GoogleFonts.robotoMono(
                                            fontSize: 10,
                                            color: isDarkMode
                                                ? Colors.grey.shade400
                                                : Colors.grey.shade700,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                borderData: FlBorderData(
                                  show: true,
                                  border: Border.all(
                                    color: isDarkMode
                                        ? Colors.grey.shade800
                                        : Colors.grey.shade300,
                                  ),
                                ),
                                minX: 0,
                                maxX: _metrics.length > 0
                                    ? (_metrics.length - 1).toDouble()
                                    : 1,
                                minY: 0,
                                maxY: 100,
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: _getCpuChartData(),
                                    isCurved: true,
                                    color: Colors.blue,
                                    barWidth: 2,
                                    isStrokeCapRound: true,
                                    dotData: const FlDotData(show: false),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      color: Colors.blue.withOpacity(0.1),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Memory Usage Chart
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Memory Usage (%)',
                            style: GoogleFonts.robotoMono(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 250,
                            child: LineChart(
                              LineChartData(
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: true,
                                  horizontalInterval: 25,
                                  getDrawingHorizontalLine: (value) {
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
                                      interval: _metrics.length > 10
                                          ? _metrics.length / 5
                                          : 1,
                                      getTitlesWidget: (value, meta) {
                                        final index = value.toInt();
                                        if (index >= 0 &&
                                            index < _metrics.length) {
                                          final sortedMetrics =
                                              List<NodeMetric>.from(_metrics)
                                                ..sort((a, b) => a.timestamp
                                                    .compareTo(b.timestamp));
                                          return Padding(
                                            padding:
                                                const EdgeInsets.only(top: 8.0),
                                            child: Text(
                                              DateFormat('HH:mm').format(
                                                  sortedMetrics[index]
                                                      .timestamp),
                                              style: GoogleFonts.robotoMono(
                                                fontSize: 10,
                                                color: isDarkMode
                                                    ? Colors.grey.shade400
                                                    : Colors.grey.shade700,
                                              ),
                                            ),
                                          );
                                        }
                                        return const Text('');
                                      },
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 50,
                                      interval: 25,
                                      getTitlesWidget: (value, meta) {
                                        return Text(
                                          '${value.toInt()}%',
                                          style: GoogleFonts.robotoMono(
                                            fontSize: 10,
                                            color: isDarkMode
                                                ? Colors.grey.shade400
                                                : Colors.grey.shade700,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                borderData: FlBorderData(
                                  show: true,
                                  border: Border.all(
                                    color: isDarkMode
                                        ? Colors.grey.shade800
                                        : Colors.grey.shade300,
                                  ),
                                ),
                                minX: 0,
                                maxX: _metrics.length > 0
                                    ? (_metrics.length - 1).toDouble()
                                    : 1,
                                minY: 0,
                                maxY: 100,
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: _getMemoryChartData(),
                                    isCurved: true,
                                    color: Colors.green,
                                    barWidth: 2,
                                    isStrokeCapRound: true,
                                    dotData: const FlDotData(show: false),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      color: Colors.green.withOpacity(0.1),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Node Summary
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Node Summary',
                            style: GoogleFonts.robotoMono(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ..._groupByNode().entries.map((entry) {
                            final nodeName = entry.key;
                            final nodeMetrics = entry.value;
                            if (nodeMetrics.isEmpty) return const SizedBox();

                            final latestMetric = nodeMetrics.reduce((a, b) =>
                                a.timestamp.isAfter(b.timestamp) ? a : b);

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      nodeName,
                                      style: GoogleFonts.robotoMono(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    // CPU Usage with progress bar
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'CPU',
                                              style: GoogleFonts.robotoMono(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Text(
                                              '${latestMetric.cpuUsageCores.toStringAsFixed(2)} / ${latestMetric.cpuCapacityCores.toStringAsFixed(0)} cores (${latestMetric.cpuUsagePercent.toStringAsFixed(1)}%)',
                                              style: GoogleFonts.robotoMono(
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value: latestMetric
                                                    .cpuUsagePercent /
                                                100,
                                            minHeight: 8,
                                            backgroundColor: isDarkMode
                                                ? Colors.grey.shade800
                                                : Colors.grey.shade300,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              latestMetric.cpuUsagePercent > 80
                                                  ? Colors.red
                                                  : latestMetric
                                                              .cpuUsagePercent >
                                                          60
                                                      ? Colors.orange
                                                      : Colors.blue,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    // Memory Usage with progress bar
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Memory',
                                              style: GoogleFonts.robotoMono(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Text(
                                              '${_formatBytes(latestMetric.memoryUsageBytes)} / ${_formatBytes(latestMetric.memoryCapacityBytes)} (${latestMetric.memoryUsagePercent.toStringAsFixed(1)}%)',
                                              style: GoogleFonts.robotoMono(
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value: latestMetric
                                                    .memoryUsagePercent /
                                                100,
                                            minHeight: 8,
                                            backgroundColor: isDarkMode
                                                ? Colors.grey.shade800
                                                : Colors.grey.shade300,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              latestMetric.memoryUsagePercent >
                                                      80
                                                  ? Colors.red
                                                  : latestMetric
                                                              .memoryUsagePercent >
                                                          60
                                                      ? Colors.orange
                                                      : Colors.green,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
