import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../widgets/theme_selector_modal.dart';
import '../services/metrics_service.dart';
import '../models/volume_metric.dart';

class VolumeMetricsScreen extends StatefulWidget {
  const VolumeMetricsScreen({super.key});

  @override
  State<VolumeMetricsScreen> createState() => _VolumeMetricsScreenState();
}

class _VolumeMetricsScreenState extends State<VolumeMetricsScreen> {
  List<String> _clusters = [];
  String? _selectedCluster;
  List<String> _namespaces = [];
  String? _selectedNamespace;
  List<VolumeMetric> _metrics = [];
  bool _isLoadingClusters = false;
  bool _isLoadingMetrics = false;
  String? _errorMessage;
  int _selectedMinutes = 60;

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
        _errorMessage = 'Failed to load clusters: ${e.toString()}';
        _isLoadingClusters = false;
      });
    }
  }

  Future<void> _loadMetrics() async {
    if (_selectedCluster == null) return;

    setState(() {
      _isLoadingMetrics = true;
      _errorMessage = null;
      _namespaces = [];
      _selectedNamespace = null;
    });

    try {
      final metrics = await MetricsService.getPvcMetrics(
        clusterName: _selectedCluster!,
        minutes: _selectedMinutes,
      );
      final namespaces =
          metrics.map((m) => m.namespace).toSet().toList()..sort();
      setState(() {
        _metrics = metrics;
        _namespaces = namespaces;
        if (namespaces.isNotEmpty && _selectedNamespace == null) {
          _selectedNamespace = namespaces.first;
        }
        _isLoadingMetrics = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load volume metrics: ${e.toString()}';
        _isLoadingMetrics = false;
      });
    }
  }

  List<VolumeMetric> get _filteredMetrics {
    if (_selectedNamespace == null) return _metrics;
    return _metrics.where((m) => m.namespace == _selectedNamespace).toList();
  }

  /// One row per PVC: the latest sample only.
  List<VolumeMetric> get _latestMetrics {
    if (_filteredMetrics.isEmpty) return [];
    final Map<String, VolumeMetric> latestByPvc = {};
    for (final m in _filteredMetrics) {
      final existing = latestByPvc[m.pvcName];
      if (existing == null || m.timestamp.isAfter(existing.timestamp)) {
        latestByPvc[m.pvcName] = m;
      }
    }
    final result = latestByPvc.values.toList();
    result.sort((a, b) => a.pvcName.compareTo(b.pvcName));
    return result;
  }

  int get _totalCapacityBytes =>
      _latestMetrics.fold(0, (sum, m) => sum + m.capacityBytes);
  int get _totalUsedBytes =>
      _latestMetrics.fold(0, (sum, m) => sum + m.usedBytes);
  int get _totalAvailableBytes =>
      _latestMetrics.fold(0, (sum, m) => sum + m.availableBytes);

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  List<String> _getVolumeKeys() {
    final Set<String> keys = {};
    for (var m in _filteredMetrics) {
      keys.add(m.pvcName);
    }
    return keys.toList()..sort();
  }

  List<DateTime> _getAllUniqueTimestamps() {
    final Set<DateTime> timestamps = {};
    for (var m in _filteredMetrics) {
      final localTimestamp = m.timestamp.toLocal();
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

  List<FlSpot> _getUsageChartDataForVolume(String pvcName) {
    if (_filteredMetrics.isEmpty) return [];

    final volumeMetrics =
        _filteredMetrics.where((m) => m.pvcName == pvcName).toList();
    final Map<DateTime, double> aggregated = {};
    for (var m in volumeMetrics) {
      final localTimestamp = m.timestamp.toLocal();
      final key = DateTime(
        localTimestamp.year,
        localTimestamp.month,
        localTimestamp.day,
        localTimestamp.hour,
        localTimestamp.minute,
      );
      if (!aggregated.containsKey(key)) {
        aggregated[key] = m.usagePercent;
      } else {
        aggregated[key] = aggregated[key]! > m.usagePercent
            ? aggregated[key]!
            : m.usagePercent;
      }
    }

    final allTimestamps = _getAllUniqueTimestamps();
    final spots = allTimestamps.asMap().entries.map((entry) {
      final timestamp = entry.value;
      final percent = aggregated[timestamp];
      if (percent == null) return null;
      return FlSpot(entry.key.toDouble(), percent);
    }).where((spot) => spot != null).cast<FlSpot>().toList();

    // Cap chart points for smooth rendering (avoids lag with 100+ points).
    const maxSpots = 80;
    if (spots.length <= maxSpots) return spots;
    final step = (spots.length / maxSpots).ceil().clamp(1, spots.length);
    final count = (spots.length / step).ceil().clamp(1, maxSpots);
    return List.generate(count, (i) => spots[i * step]);
  }

  static const List<Color> _volumeColors = [
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

  Color _getVolumeColor(int index) {
    return _volumeColors[index % _volumeColors.length];
  }

  // Fixed column widths: Timestamp, Pod, PVC Name, Volume, Used, Available, Capacity, Usage %
  static const List<double> _columnWidths = [90, 120, 160, 100, 72, 72, 72, 58];

  Widget _tableCell(String text, {bool bold = false, bool isDarkMode = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          color: color ?? (isDarkMode ? Colors.grey.shade300 : Colors.black87),
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildTableHeader(bool isDarkMode) {
    final labels = [
      'Timestamp', 'Pod', 'PVC Name', 'Volume',
      'Used', 'Available', 'Capacity', 'Usage %',
    ];
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(8, (i) => SizedBox(
          width: _columnWidths[i],
          child: _tableCell(labels[i], bold: true, isDarkMode: isDarkMode),
        )),
      ),
    );
  }

  Widget _buildDataRow(VolumeMetric m, bool isDarkMode) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: _columnWidths[0], child: _tableCell(DateFormat('MM/dd HH:mm').format(m.timestamp.toLocal()), isDarkMode: isDarkMode)),
        SizedBox(width: _columnWidths[1], child: _tableCell(m.pod, isDarkMode: isDarkMode)),
        SizedBox(width: _columnWidths[2], child: _tableCell(m.pvcName, isDarkMode: isDarkMode)),
        SizedBox(width: _columnWidths[3], child: _tableCell(m.volumeName, isDarkMode: isDarkMode)),
        SizedBox(width: _columnWidths[4], child: _tableCell(_formatBytes(m.usedBytes), isDarkMode: isDarkMode)),
        SizedBox(width: _columnWidths[5], child: _tableCell(_formatBytes(m.availableBytes), isDarkMode: isDarkMode)),
        SizedBox(width: _columnWidths[6], child: _tableCell(_formatBytes(m.capacityBytes), isDarkMode: isDarkMode)),
        SizedBox(
          width: _columnWidths[7],
          child: _tableCell(
            '${m.usagePercent.toStringAsFixed(1)}%',
            isDarkMode: isDarkMode,
            color: m.usagePercent > 80 ? Colors.red : m.usagePercent > 60 ? Colors.orange : null,
          ),
        ),
      ],
    );
  }

  Widget _buildUsageChart(bool isDarkMode) {
    final volumeKeys = _getVolumeKeys();
    if (volumeKeys.isEmpty || _filteredMetrics.isEmpty) {
      return Center(
        child: Text(
          'No data available',
          style: GoogleFonts.inter(),
        ),
      );
    }

    double maxPercent = 100;
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
                      style: GoogleFonts.inter(
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
              reservedSize: 40,
              interval: 20,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toStringAsFixed(0)}%',
                  style: GoogleFonts.inter(
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
        maxY: maxPercent,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((LineBarSpot touchedSpot) {
                final volumeIndex = touchedSpot.barIndex;
                final volumeKey = volumeKeys[volumeIndex];
                final color = _getVolumeColor(volumeIndex);
                return LineTooltipItem(
                  '$volumeKey: ${touchedSpot.y.toStringAsFixed(1)}%',
                  GoogleFonts.inter(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: volumeKeys.asMap().entries.map((entry) {
          final pvcName = entry.value;
          final color = _getVolumeColor(entry.key);
          final data = _getUsageChartDataForVolume(pvcName);
          return LineChartBarData(
            spots: data,
            isCurved: true,
            color: color,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Volume Metrics',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            tooltip: 'Select theme',
            icon: const Icon(Icons.palette_outlined),
            onPressed: () => showThemeSelectorModal(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadClusters();
          if (_selectedCluster != null) await _loadMetrics();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Cluster',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _isLoadingClusters
                            ? const Center(child: CircularProgressIndicator())
                            : DropdownButtonFormField<String>(
                                initialValue: _selectedCluster,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                style: GoogleFonts.inter(
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                                dropdownColor: isDarkMode
                                    ? Theme.of(context).colorScheme.surface
                                    : Colors.white,
                                items: _clusters.map((cluster) {
                                  return DropdownMenuItem<String>(
                                    value: cluster,
                                    child: Text(
                                      cluster,
                                      style: GoogleFonts.inter(
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
                        Text(
                          'Select Namespace',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _isLoadingMetrics
                            ? const Center(child: CircularProgressIndicator())
                            : DropdownButtonFormField<String>(
                                initialValue: _selectedNamespace,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                style: GoogleFonts.inter(
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                                dropdownColor: isDarkMode
                                    ? Theme.of(context).colorScheme.surface
                                    : Colors.white,
                                items: _namespaces.map((namespace) {
                                  return DropdownMenuItem<String>(
                                    value: namespace,
                                    child: Text(
                                      namespace,
                                      style: GoogleFonts.inter(
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
                                },
                              ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Text(
                              'Time Range:',
                              style: GoogleFonts.inter(),
                            ),
                            const SizedBox(width: 8),
                            DropdownButton<int>(
                              value: _selectedMinutes,
                              style: GoogleFonts.inter(
                                color: isDarkMode
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                              dropdownColor: isDarkMode
                                  ? Theme.of(context).colorScheme.surface
                                  : Colors.white,
                              items: [
                                5,
                                10,
                                30,
                                60,
                                360,
                                720,
                                1440,
                                4320,
                              ].map((minutes) {
                                final label = minutes < 60
                                    ? '${minutes}m'
                                    : minutes >= 1440
                                        ? '${minutes ~/ 1440}d'
                                        : '${minutes ~/ 60}h';
                                return DropdownMenuItem<int>(
                                  value: minutes,
                                  child: Text(
                                    label,
                                    style: GoogleFonts.inter(
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
                                    _selectedMinutes = value;
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
                        style: GoogleFonts.inter(color: Colors.red.shade900),
                      ),
                    ),
                  ),
                ],
                if (_isLoadingMetrics) ...[
                  const SizedBox(height: 16),
                  const Center(child: CircularProgressIndicator()),
                ],
                if (!_isLoadingMetrics && _filteredMetrics.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Volume Usage (%)',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 250,
                            child: _buildUsageChart(isDarkMode),
                          ),
                          const SizedBox(height: 8),
                          Builder(
                            builder: (context) {
                              final volumeKeys = _getVolumeKeys();
                              return Wrap(
                                spacing: 12,
                                runSpacing: 8,
                                children: volumeKeys.asMap().entries.map((entry) {
                                  final color = _getVolumeColor(entry.key);
                                  return Row(
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
                                          entry.value,
                                          style: GoogleFonts.inter(fontSize: 10),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
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
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Volume Details',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Total: ${_formatBytes(_totalCapacityBytes)}',
                                  style: GoogleFonts.inter(fontSize: 12),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'Used: ${_formatBytes(_totalUsedBytes)}',
                                  style: GoogleFonts.inter(fontSize: 12),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'Left: ${_formatBytes(_totalAvailableBytes)}',
                                  style: GoogleFonts.inter(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildTableHeader(isDarkMode),
                                ..._latestMetrics.map((m) => _buildDataRow(m, isDarkMode)),
                              ],
                            ),
                          ),
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
