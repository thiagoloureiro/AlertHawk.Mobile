import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/metrics_service.dart';
import '../models/pod_metric.dart';
import 'package:intl/intl.dart';

class ApplicationMetricsScreen extends StatefulWidget {
  const ApplicationMetricsScreen({super.key});

  @override
  State<ApplicationMetricsScreen> createState() =>
      _ApplicationMetricsScreenState();
}

class _ApplicationMetricsScreenState extends State<ApplicationMetricsScreen> {
  List<String> _clusters = [];
  String? _selectedCluster;
  List<String> _namespaces = [];
  String? _selectedNamespace;
  List<PodMetric> _metrics = [];
  bool _isLoadingClusters = false;
  bool _isLoadingNamespaces = false;
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
          _loadNamespaces();
        }
        _isLoadingClusters = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load clusters: ${e.toString()}';
        _isLoadingClusters = false;
      });
    }
  }

  Future<void> _loadNamespaces() async {
    if (_selectedCluster == null) return;

    setState(() {
      _isLoadingNamespaces = true;
      _errorMessage = null;
      _selectedNamespace = null;
      _metrics = [];
    });

    try {
      final namespaces = await MetricsService.getNamespaces(
        clusterName: _selectedCluster!,
      );
      setState(() {
        _namespaces = namespaces;
        if (namespaces.isNotEmpty && _selectedNamespace == null) {
          _selectedNamespace = namespaces.first;
          _loadMetrics();
        }
        _isLoadingNamespaces = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load namespaces: ${e.toString()}';
        _isLoadingNamespaces = false;
      });
    }
  }

  Future<void> _loadMetrics() async {
    if (_selectedCluster == null || _selectedNamespace == null) return;

    setState(() {
      _isLoadingMetrics = true;
      _errorMessage = null;
    });

    try {
      final metrics = await MetricsService.getNamespaceMetrics(
        clusterName: _selectedCluster!,
        namespace: _selectedNamespace!,
        hours: _selectedHours,
        limit: 1000,
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

  void _showPodDetailsDialog(
    BuildContext context,
    String podKey,
    List<PodMetric> podMetrics,
    Color podColor,
    bool isDarkMode,
  ) {
    if (podMetrics.isEmpty) return;

    // Get the latest metric
    final latestMetric = podMetrics.reduce((a, b) =>
        a.timestamp.isAfter(b.timestamp) ? a : b);

    // Calculate statistics
    final sortedMetrics = List<PodMetric>.from(podMetrics)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final minCpu = podMetrics
        .map((m) => m.cpuUsageCores)
        .reduce((a, b) => a < b ? a : b);
    final maxCpu = podMetrics
        .map((m) => m.cpuUsageCores)
        .reduce((a, b) => a > b ? a : b);
    final avgCpu = podMetrics
            .map((m) => m.cpuUsageCores)
            .reduce((a, b) => a + b) /
        podMetrics.length;

    final minMemory = podMetrics
        .map((m) => m.memoryUsageBytes)
        .reduce((a, b) => a < b ? a : b);
    final maxMemory = podMetrics
        .map((m) => m.memoryUsageBytes)
        .reduce((a, b) => a > b ? a : b);
    final avgMemory = (podMetrics
                .map((m) => m.memoryUsageBytes)
                .reduce((a, b) => a + b) /
            podMetrics.length)
        .round();

    final cpuPercent = latestMetric.cpuLimitCores != null
        ? (latestMetric.cpuUsageCores / latestMetric.cpuLimitCores!) * 100
        : null;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: podColor.withOpacity(0.2),
                    border: Border(
                      bottom: BorderSide(
                        color: isDarkMode
                            ? Colors.grey.shade700
                            : Colors.grey.shade300,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: podColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              podKey,
                              style: GoogleFonts.robotoMono(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Cluster: ${latestMetric.clusterName} | Namespace: ${latestMetric.namespace}',
                              style: GoogleFonts.robotoMono(
                                fontSize: 11,
                                color: isDarkMode
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Current Metrics
                        Text(
                          'Current Metrics',
                          style: GoogleFonts.robotoMono(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildMetricRow(
                          'CPU Usage',
                          '${latestMetric.cpuUsageCores.toStringAsFixed(4)} cores',
                          cpuPercent != null ? '${cpuPercent.toStringAsFixed(1)}%' : 'N/A',
                          latestMetric.cpuLimitCores != null
                              ? (latestMetric.cpuUsageCores /
                                  latestMetric.cpuLimitCores!)
                              : null,
                          isDarkMode,
                        ),
                        const SizedBox(height: 12),
                        _buildMetricRow(
                          'Memory Usage',
                          _formatBytes(latestMetric.memoryUsageBytes),
                          null,
                          null,
                          isDarkMode,
                        ),
                        const SizedBox(height: 24),
                        // Statistics
                        Text(
                          'Statistics (${podMetrics.length} data points)',
                          style: GoogleFonts.robotoMono(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildStatRow('CPU - Min', '${minCpu.toStringAsFixed(4)} cores', isDarkMode),
                        _buildStatRow('CPU - Max', '${maxCpu.toStringAsFixed(4)} cores', isDarkMode),
                        _buildStatRow('CPU - Avg', '${avgCpu.toStringAsFixed(4)} cores', isDarkMode),
                        const SizedBox(height: 12),
                        _buildStatRow('Memory - Min', _formatBytes(minMemory), isDarkMode),
                        _buildStatRow('Memory - Max', _formatBytes(maxMemory), isDarkMode),
                        _buildStatRow('Memory - Avg', _formatBytes(avgMemory), isDarkMode),
                        const SizedBox(height: 24),
                        // Time Range
                        Text(
                          'Time Range',
                          style: GoogleFonts.robotoMono(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildStatRow(
                          'First Record',
                          DateFormat('yyyy-MM-dd HH:mm:ss')
                              .format(sortedMetrics.first.timestamp),
                          isDarkMode,
                        ),
                        _buildStatRow(
                          'Last Record',
                          DateFormat('yyyy-MM-dd HH:mm:ss')
                              .format(sortedMetrics.last.timestamp),
                          isDarkMode,
                        ),
                        if (latestMetric.cpuLimitCores != null) ...[
                          const SizedBox(height: 24),
                          Text(
                            'Limits',
                            style: GoogleFonts.robotoMono(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildStatRow(
                            'CPU Limit',
                            '${latestMetric.cpuLimitCores!.toStringAsFixed(2)} cores',
                            isDarkMode,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricRow(
    String label,
    String value,
    String? percentage,
    double? progressValue,
    bool isDarkMode,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.robotoMono(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Row(
              children: [
                Text(
                  value,
                  style: GoogleFonts.robotoMono(
                    fontSize: 12,
                  ),
                ),
                if (percentage != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    percentage,
                    style: GoogleFonts.robotoMono(
                      fontSize: 11,
                      color: progressValue != null && progressValue > 0.8
                          ? Colors.red
                          : progressValue != null && progressValue > 0.6
                              ? Colors.orange
                              : isDarkMode
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        if (progressValue != null) ...[
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progressValue,
              minHeight: 6,
              backgroundColor: isDarkMode
                  ? Colors.grey.shade800
                  : Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(
                progressValue > 0.8
                    ? Colors.red
                    : progressValue > 0.6
                        ? Colors.orange
                        : Colors.blue,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatRow(String label, String value, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.robotoMono(
              fontSize: 11,
              color: isDarkMode
                  ? Colors.grey.shade400
                  : Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.robotoMono(
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // Get unique pod/container combinations
  List<String> _getPodKeys() {
    final Set<String> podKeys = {};
    for (var metric in _metrics) {
      podKeys.add('${metric.pod}/${metric.container}');
    }
    return podKeys.toList()..sort();
  }

  // Get CPU chart data for a specific pod/container
  List<FlSpot> _getCpuChartDataForPod(String podKey) {
    if (_metrics.isEmpty) return [];

    // Filter metrics for this pod/container
    final podMetrics = _metrics.where((m) => '${m.pod}/${m.container}' == podKey).toList();
    
    // Group by timestamp (minute level)
    final Map<DateTime, double> aggregated = {};
    for (var metric in podMetrics) {
      final key = DateTime(
        metric.timestamp.year,
        metric.timestamp.month,
        metric.timestamp.day,
        metric.timestamp.hour,
        metric.timestamp.minute,
      );
      // For same timestamp, take the latest value (or average if multiple)
      if (!aggregated.containsKey(key)) {
        aggregated[key] = metric.cpuUsageCores;
      } else {
        // If multiple metrics at same minute, take the max (or could average)
        aggregated[key] = aggregated[key]! > metric.cpuUsageCores 
            ? aggregated[key]! 
            : metric.cpuUsageCores;
      }
    }

    final sortedEntries = aggregated.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    // Get all unique timestamps for x-axis alignment
    final allTimestamps = _getAllUniqueTimestamps();
    
    return allTimestamps.asMap().entries.map((entry) {
      final timestamp = entry.value;
      final cpuValue = aggregated[timestamp] ?? 0.0;
      return FlSpot(entry.key.toDouble(), cpuValue);
    }).toList();
  }

  // Get Memory chart data for a specific pod/container
  List<FlSpot> _getMemoryChartDataForPod(String podKey) {
    if (_metrics.isEmpty) return [];

    // Filter metrics for this pod/container
    final podMetrics = _metrics.where((m) => '${m.pod}/${m.container}' == podKey).toList();
    
    // Group by timestamp (minute level)
    final Map<DateTime, int> aggregated = {};
    for (var metric in podMetrics) {
      final key = DateTime(
        metric.timestamp.year,
        metric.timestamp.month,
        metric.timestamp.day,
        metric.timestamp.hour,
        metric.timestamp.minute,
      );
      // For same timestamp, take the latest value
      if (!aggregated.containsKey(key)) {
        aggregated[key] = metric.memoryUsageBytes;
      } else {
        aggregated[key] = aggregated[key]! > metric.memoryUsageBytes 
            ? aggregated[key]! 
            : metric.memoryUsageBytes;
      }
    }

    final sortedEntries = aggregated.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    // Get all unique timestamps for x-axis alignment
    final allTimestamps = _getAllUniqueTimestamps();
    
    return allTimestamps.asMap().entries.map((entry) {
      final timestamp = entry.value;
      final memoryBytes = aggregated[timestamp] ?? 0;
      final memoryMB = memoryBytes / (1024 * 1024);
      return FlSpot(entry.key.toDouble(), memoryMB);
    }).toList();
  }

  // Get all unique timestamps (minute level) for x-axis alignment
  List<DateTime> _getAllUniqueTimestamps() {
    final Set<DateTime> timestamps = {};
    for (var metric in _metrics) {
      final key = DateTime(
        metric.timestamp.year,
        metric.timestamp.month,
        metric.timestamp.day,
        metric.timestamp.hour,
        metric.timestamp.minute,
      );
      timestamps.add(key);
    }
    final sorted = timestamps.toList()..sort();
    return sorted;
  }

  // Group metrics by pod/container
  Map<String, List<PodMetric>> _groupByPod() {
    final Map<String, List<PodMetric>> grouped = {};
    for (var metric in _metrics) {
      final key = '${metric.pod}/${metric.container}';
      grouped.putIfAbsent(key, () => []).add(metric);
    }
    return grouped;
  }


  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Application Metrics',
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
            await _loadNamespaces();
            if (_selectedNamespace != null) {
              await _loadMetrics();
            }
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Cluster and Namespace selectors
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
                                  _loadNamespaces();
                                },
                              ),
                        const SizedBox(height: 16),
                        Text(
                          'Select Namespace',
                          style: GoogleFonts.robotoMono(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _isLoadingNamespaces
                            ? const Center(child: CircularProgressIndicator())
                            : DropdownButtonFormField<String>(
                                value: _selectedNamespace,
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
                                items: _namespaces.map((namespace) {
                                  return DropdownMenuItem<String>(
                                    value: namespace,
                                    child: Text(
                                      namespace,
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
                                    _selectedNamespace = value;
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
                            'CPU Usage (cores)',
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
                              final podKeys = _getPodKeys();
                              // Calculate items per row to ensure at least 4 rows
                              final itemsPerRow = (podKeys.length / 4).ceil();
                              final screenWidth = MediaQuery.of(context).size.width;
                              final availableWidth = screenWidth - 64; // Account for padding
                              final itemWidth = (availableWidth / itemsPerRow).clamp(120.0, 200.0);
                              
                              return Wrap(
                                spacing: 12,
                                runSpacing: 8,
                                children: podKeys.asMap().entries.map((entry) {
                                  final podKey = entry.value;
                                  final color = _getPodColor(entry.key);
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
                                            podKey,
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
                            'Memory Usage',
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
                              final podKeys = _getPodKeys();
                              // Calculate items per row to ensure at least 4 rows
                              final itemsPerRow = (podKeys.length / 4).ceil();
                              final screenWidth = MediaQuery.of(context).size.width;
                              final availableWidth = screenWidth - 64; // Account for padding
                              final itemWidth = (availableWidth / itemsPerRow).clamp(120.0, 200.0);
                              
                              return Wrap(
                                spacing: 12,
                                runSpacing: 8,
                                children: podKeys.asMap().entries.map((entry) {
                                  final podKey = entry.value;
                                  final color = _getPodColor(entry.key);
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
                                            podKey,
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
                  // Pod Summary Table
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pod Summary',
                            style: GoogleFonts.robotoMono(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Table Header
                          Container(
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    'Pod/Container',
                                    style: GoogleFonts.robotoMono(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'CPU',
                                    style: GoogleFonts.robotoMono(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'Memory',
                                    style: GoogleFonts.robotoMono(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Table Rows
                          ..._groupByPod().entries.map((entry) {
                            final podKey = entry.key;
                            final podMetrics = entry.value;
                            if (podMetrics.isEmpty) return const SizedBox();

                            // Get the latest metric for this pod
                            final latestMetric = podMetrics.reduce((a, b) =>
                                a.timestamp.isAfter(b.timestamp) ? a : b);

                            // Get pod index for color
                            final podKeys = _getPodKeys();
                            final podIndex = podKeys.indexOf(podKey);
                            final podColor = _getPodColor(podIndex);

                            final cpuPercent = latestMetric.cpuLimitCores != null
                                ? (latestMetric.cpuUsageCores /
                                    latestMetric.cpuLimitCores!) *
                                    100
                                : null;

                            return InkWell(
                              onTap: () => _showPodDetailsDialog(
                                context,
                                podKey,
                                podMetrics,
                                podColor,
                                isDarkMode,
                              ),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 4),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: isDarkMode
                                          ? Colors.grey.shade700
                                          : Colors.grey.shade300,
                                      width: 1,
                                    ),
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                child: Row(
                                children: [
                                  // Pod/Container name with color indicator
                                  Expanded(
                                    flex: 3,
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: podColor,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            podKey,
                                            style: GoogleFonts.robotoMono(
                                              fontSize: 11,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // CPU Usage
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${latestMetric.cpuUsageCores.toStringAsFixed(4)} cores',
                                          style: GoogleFonts.robotoMono(
                                            fontSize: 11,
                                          ),
                                        ),
                                        if (latestMetric.cpuLimitCores != null)
                                          Text(
                                            '${cpuPercent!.toStringAsFixed(1)}%',
                                            style: GoogleFonts.robotoMono(
                                              fontSize: 10,
                                              color: cpuPercent > 80
                                                  ? Colors.red
                                                  : cpuPercent > 60
                                                      ? Colors.orange
                                                      : isDarkMode
                                                          ? Colors.grey.shade400
                                                          : Colors.grey.shade600,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  // Memory Usage
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      _formatBytes(latestMetric.memoryUsageBytes),
                                      style: GoogleFonts.robotoMono(
                                        fontSize: 11,
                                      ),
                                    ),
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

  // Color palette for different pods
  static const List<Color> _podColors = [
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

  Color _getPodColor(int index) {
    return _podColors[index % _podColors.length];
  }

  Widget _buildCpuChart(bool isDarkMode) {
    final podKeys = _getPodKeys();
    if (podKeys.isEmpty || _metrics.isEmpty) {
      return Center(
        child: Text(
          'No data available',
          style: GoogleFonts.robotoMono(),
        ),
      );
    }

    // Get all data points to find max
    double maxCpu = 0;
    for (var podKey in podKeys) {
      final data = _getCpuChartDataForPod(podKey);
      if (data.isNotEmpty) {
        final podMax = data.map((e) => e.y).reduce((a, b) => a > b ? a : b);
        if (podMax > maxCpu) maxCpu = podMax;
      }
    }

    final allTimestamps = _getAllUniqueTimestamps();
    final dataLength = allTimestamps.length;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: maxCpu > 0 ? maxCpu / 5 : 1,
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
              interval: maxCpu > 0 ? maxCpu / 5 : 1,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(3),
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
        maxY: maxCpu > 0 ? maxCpu * 1.1 : 1,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((LineBarSpot touchedSpot) {
                final podIndex = touchedSpot.barIndex;
                final podKey = podKeys[podIndex];
                final podColor = _getPodColor(podIndex);
                return LineTooltipItem(
                  '$podKey: ${touchedSpot.y.toStringAsFixed(2)}',
                  GoogleFonts.robotoMono(
                    fontSize: 12,
                    color: podColor,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: podKeys.asMap().entries.map((entry) {
          final podKey = entry.value;
          final color = _getPodColor(entry.key);
          final data = _getCpuChartDataForPod(podKey);
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
    final podKeys = _getPodKeys();
    if (podKeys.isEmpty || _metrics.isEmpty) {
      return Center(
        child: Text(
          'No data available',
          style: GoogleFonts.robotoMono(),
        ),
      );
    }

    // Get all data points to find max
    double maxMemoryMB = 0;
    for (var podKey in podKeys) {
      final data = _getMemoryChartDataForPod(podKey);
      if (data.isNotEmpty) {
        final podMax = data.map((e) => e.y).reduce((a, b) => a > b ? a : b);
        if (podMax > maxMemoryMB) maxMemoryMB = podMax;
      }
    }

    final allTimestamps = _getAllUniqueTimestamps();
    final dataLength = allTimestamps.length;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: maxMemoryMB > 0 ? maxMemoryMB / 5 : 100,
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
              interval: maxMemoryMB > 0 ? maxMemoryMB / 5 : 100,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toStringAsFixed(0)} MB',
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
        maxY: maxMemoryMB > 0 ? maxMemoryMB * 1.1 : 100,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((LineBarSpot touchedSpot) {
                final podIndex = touchedSpot.barIndex;
                final podKey = podKeys[podIndex];
                final podColor = _getPodColor(podIndex);
                return LineTooltipItem(
                  '$podKey: ${touchedSpot.y.toStringAsFixed(2)} MB',
                  GoogleFonts.robotoMono(
                    fontSize: 12,
                    color: podColor,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: podKeys.asMap().entries.map((entry) {
          final podKey = entry.value;
          final color = _getPodColor(entry.key);
          final data = _getMemoryChartDataForPod(podKey);
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

