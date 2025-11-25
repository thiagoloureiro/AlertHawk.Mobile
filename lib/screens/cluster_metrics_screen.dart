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
  int _selectedHours = 1;

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

  // Get unique node names
  List<String> _getNodeNames() {
    final Set<String> nodeNames = {};
    for (var metric in _metrics) {
      nodeNames.add(metric.nodeName);
    }
    return nodeNames.toList()..sort();
  }

  // Get CPU chart data for a specific node
  List<FlSpot> _getCpuChartDataForNode(String nodeName) {
    if (_metrics.isEmpty) return [];

    // Filter metrics for this node
    final nodeMetrics = _metrics
        .where((m) => m.nodeName == nodeName)
        .toList();

    // Group by timestamp (minute level) - convert to local timezone
    final Map<DateTime, double> aggregated = {};
    for (var metric in nodeMetrics) {
      final localTimestamp = metric.timestamp.toLocal();
      final key = DateTime(
        localTimestamp.year,
        localTimestamp.month,
        localTimestamp.day,
        localTimestamp.hour,
        localTimestamp.minute,
      );
      // For same timestamp, take the latest value
      if (!aggregated.containsKey(key)) {
        aggregated[key] = metric.cpuUsagePercent;
      } else {
        aggregated[key] = aggregated[key]! > metric.cpuUsagePercent
            ? aggregated[key]!
            : metric.cpuUsagePercent;
      }
    }

    // Get all unique timestamps for x-axis alignment
    final allTimestamps = _getAllUniqueTimestamps();

    return allTimestamps.asMap().entries
        .map((entry) {
          final timestamp = entry.value;
          final cpuPercent = aggregated[timestamp];
          if (cpuPercent == null || cpuPercent == 0.0) return null;
          return FlSpot(entry.key.toDouble(), cpuPercent);
        })
        .where((spot) => spot != null)
        .cast<FlSpot>()
        .toList();
  }

  // Get Memory chart data for a specific node
  List<FlSpot> _getMemoryChartDataForNode(String nodeName) {
    if (_metrics.isEmpty) return [];

    // Filter metrics for this node
    final nodeMetrics = _metrics
        .where((m) => m.nodeName == nodeName)
        .toList();

    // Group by timestamp (minute level) - convert to local timezone
    final Map<DateTime, double> aggregated = {};
    for (var metric in nodeMetrics) {
      final localTimestamp = metric.timestamp.toLocal();
      final key = DateTime(
        localTimestamp.year,
        localTimestamp.month,
        localTimestamp.day,
        localTimestamp.hour,
        localTimestamp.minute,
      );
      // For same timestamp, take the latest value
      if (!aggregated.containsKey(key)) {
        aggregated[key] = metric.memoryUsagePercent;
      } else {
        aggregated[key] = aggregated[key]! > metric.memoryUsagePercent
            ? aggregated[key]!
            : metric.memoryUsagePercent;
      }
    }

    // Get all unique timestamps for x-axis alignment
    final allTimestamps = _getAllUniqueTimestamps();

    return allTimestamps.asMap().entries
        .map((entry) {
          final timestamp = entry.value;
          final memoryPercent = aggregated[timestamp];
          if (memoryPercent == null || memoryPercent == 0.0) return null;
          return FlSpot(entry.key.toDouble(), memoryPercent);
        })
        .where((spot) => spot != null)
        .cast<FlSpot>()
        .toList();
  }

  // Get all unique timestamps (minute level) for x-axis alignment - convert to local timezone
  List<DateTime> _getAllUniqueTimestamps() {
    final Set<DateTime> timestamps = {};
    for (var metric in _metrics) {
      final localTimestamp = metric.timestamp.toLocal();
      final key = DateTime(
        localTimestamp.year,
        localTimestamp.month,
        localTimestamp.day,
        localTimestamp.hour,
        localTimestamp.minute,
      );
      timestamps.add(key);
    }
    final sorted = timestamps.toList()..sort();
    return sorted;
  }

  // Color palette for different nodes
  static const List<Color> _nodeColors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.teal,
    Colors.pink,
    Colors.amber,
    Colors.cyan,
    Colors.indigo,
  ];

  Color _getNodeColor(int index) {
    return _nodeColors[index % _nodeColors.length];
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
                            child: _buildCpuChart(isDarkMode),
                          ),
                          const SizedBox(height: 8),
                          // Legend with multiple rows
                          Builder(
                            builder: (context) {
                              final nodeNames = _getNodeNames();
                              // Calculate items per row to ensure at least 4 rows
                              final itemsPerRow = (nodeNames.length / 4).ceil();
                              final screenWidth = MediaQuery.of(context).size.width;
                              final availableWidth = screenWidth - 64; // Account for padding
                              final itemWidth = (availableWidth / itemsPerRow).clamp(120.0, 200.0);
                              
                              return Wrap(
                                spacing: 12,
                                runSpacing: 8,
                                children: nodeNames.asMap().entries.map((entry) {
                                  final nodeName = entry.value;
                                  final color = _getNodeColor(entry.key);
                                  return SizedBox(
                                    width: itemWidth,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: color,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            nodeName,
                                            style: GoogleFonts.robotoMono(
                                              fontSize: 10,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              );
                            },
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
                            child: _buildMemoryChart(isDarkMode),
                          ),
                          const SizedBox(height: 8),
                          // Legend with multiple rows
                          Builder(
                            builder: (context) {
                              final nodeNames = _getNodeNames();
                              // Calculate items per row to ensure at least 4 rows
                              final itemsPerRow = (nodeNames.length / 4).ceil();
                              final screenWidth = MediaQuery.of(context).size.width;
                              final availableWidth = screenWidth - 64; // Account for padding
                              final itemWidth = (availableWidth / itemsPerRow).clamp(120.0, 200.0);
                              
                              return Wrap(
                                spacing: 12,
                                runSpacing: 8,
                                children: nodeNames.asMap().entries.map((entry) {
                                  final nodeName = entry.value;
                                  final color = _getNodeColor(entry.key);
                                  return SizedBox(
                                    width: itemWidth,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: color,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            nodeName,
                                            style: GoogleFonts.robotoMono(
                                              fontSize: 10,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              );
                            },
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

  Widget _buildCpuChart(bool isDarkMode) {
    final nodeNames = _getNodeNames();
    if (nodeNames.isEmpty || _metrics.isEmpty) {
      return Center(
        child: Text(
          'No data available',
          style: GoogleFonts.robotoMono(),
        ),
      );
    }

    final allTimestamps = _getAllUniqueTimestamps();
    final dataLength = allTimestamps.length;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 20,
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
              interval: dataLength > 10 ? dataLength / 5 : 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < allTimestamps.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('HH:mm').format(allTimestamps[index]),
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
              interval: 20,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toStringAsFixed(2)}%',
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
        maxX: dataLength > 0 ? (dataLength - 1).toDouble() : 1,
        minY: 0,
        maxY: 100,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((LineBarSpot touchedSpot) {
                final nodeIndex = touchedSpot.barIndex;
                final nodeName = nodeNames[nodeIndex];
                final nodeColor = _getNodeColor(nodeIndex);
                return LineTooltipItem(
                  '$nodeName: ${touchedSpot.y.toStringAsFixed(2)}%',
                  GoogleFonts.robotoMono(
                    fontSize: 12,
                    color: nodeColor,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: nodeNames.asMap().entries.map((entry) {
          final nodeName = entry.value;
          final color = _getNodeColor(entry.key);
          final data = _getCpuChartDataForNode(nodeName);
          return LineChartBarData(
            spots: data,
            isCurved: true,
            color: color,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: false,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMemoryChart(bool isDarkMode) {
    final nodeNames = _getNodeNames();
    if (nodeNames.isEmpty || _metrics.isEmpty) {
      return Center(
        child: Text(
          'No data available',
          style: GoogleFonts.robotoMono(),
        ),
      );
    }

    final allTimestamps = _getAllUniqueTimestamps();
    final dataLength = allTimestamps.length;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 20,
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
              interval: dataLength > 10 ? dataLength / 5 : 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < allTimestamps.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('HH:mm').format(allTimestamps[index]),
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
              interval: 20,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toStringAsFixed(2)}%',
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
        maxX: dataLength > 0 ? (dataLength - 1).toDouble() : 1,
        minY: 0,
        maxY: 100,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((LineBarSpot touchedSpot) {
                final nodeIndex = touchedSpot.barIndex;
                final nodeName = nodeNames[nodeIndex];
                final nodeColor = _getNodeColor(nodeIndex);
                return LineTooltipItem(
                  '$nodeName: ${touchedSpot.y.toStringAsFixed(2)}%',
                  GoogleFonts.robotoMono(
                    fontSize: 12,
                    color: nodeColor,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: nodeNames.asMap().entries.map((entry) {
          final nodeName = entry.value;
          final color = _getNodeColor(entry.key);
          final data = _getMemoryChartDataForNode(nodeName);
          return LineChartBarData(
            spots: data,
            isCurved: true,
            color: color,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: false,
            ),
          );
        }).toList(),
      ),
    );
  }
}
