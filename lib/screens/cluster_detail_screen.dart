import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/cluster_node_metric.dart';
import '../services/metrics_service.dart';

class ClusterDetailScreen extends StatefulWidget {
  final String clusterName;
  final String clusterEnvironment;
  final List<ClusterNodeMetric> nodes;

  const ClusterDetailScreen({
    super.key,
    required this.clusterName,
    required this.clusterEnvironment,
    required this.nodes,
  });

  @override
  State<ClusterDetailScreen> createState() => _ClusterDetailScreenState();
}

class _ClusterDetailScreenState extends State<ClusterDetailScreen> {
  late List<ClusterNodeMetric> _nodes;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _nodes = List.from(widget.nodes);
  }

  Future<void> _refresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      final all = await MetricsService.getClusterDashboardNodes(minutes: 1);
      final filtered = all.where((n) =>
          n.clusterName == widget.clusterName &&
          n.clusterEnvironment.toUpperCase() == widget.clusterEnvironment.toUpperCase()).toList();
      if (mounted) {
        setState(() {
          _nodes = filtered;
          _isRefreshing = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  bool get _isClusterReady => _nodes.every((n) => n.isReady);
  int get _readyCount => _nodes.where((n) => n.isReady).length;
  double get _aggregateCpuPercent {
    double used = 0, cap = 0;
    for (final n in _nodes) {
      used += n.cpuUsageCores;
      cap += n.cpuCapacityCores;
    }
    return cap > 0 ? (used / cap) * 100 : 0;
  }
  double get _aggregateMemoryPercent {
    int used = 0, cap = 0;
    for (final n in _nodes) {
      used += n.memoryUsageBytes;
      cap += n.memoryCapacityBytes;
    }
    return cap > 0 ? (used / cap) * 100 : 0;
  }
  String get _lastUpdateLabel {
    if (_nodes.isEmpty) return 'Unknown';
    final t = _nodes.map((n) => n.timestamp).reduce((a, b) => a.isAfter(b) ? a : b);
    final now = DateTime.now();
    final diff = now.difference(t);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} h ago';
    return '${diff.inDays} d ago';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _isClusterReady ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
    final k8sVersion = _nodes.isNotEmpty ? _nodes.first.kubernetesVersion : null;
    final cloudProvider = _nodes.isNotEmpty ? _nodes.first.cloudProvider : null;
    final isProd = widget.clusterEnvironment.toUpperCase() == 'PROD';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(
              child: Text(
                widget.clusterName,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  letterSpacing: -0.3,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isProd
                    ? const Color(0xFFEF4444).withOpacity(0.2)
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.clusterEnvironment.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isProd ? const Color(0xFFEF4444) : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: _isRefreshing
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.onSurface,
                    ),
                  )
                : const Icon(Icons.refresh_rounded),
            onPressed: _isRefreshing ? null : _refresh,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status row
              Material(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isClusterReady ? Icons.check_circle_rounded : Icons.cancel_rounded,
                            size: 24,
                            color: statusColor,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _isClusterReady ? 'OK' : 'Issue',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                      if (k8sVersion != null && k8sVersion.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _detailRow(Icons.code_rounded, 'Kubernetes', k8sVersion, theme),
                      ],
                      if (cloudProvider != null && cloudProvider.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _detailRow(Icons.cloud_rounded, 'Cloud', cloudProvider, theme),
                      ],
                      const SizedBox(height: 12),
                      _detailRow(Icons.schedule_rounded, 'Last update', _lastUpdateLabel, theme),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Summary: Nodes, CPU, RAM
              Text(
                'Summary',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Material(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildSummaryColumn(
                          theme,
                          Icons.dns_rounded,
                          'Nodes',
                          '$_readyCount / ${_nodes.length}',
                          null,
                        ),
                      ),
                      Expanded(
                        child: _buildSummaryColumn(
                          theme,
                          Icons.memory_rounded,
                          'CPU',
                          '${_aggregateCpuPercent.toStringAsFixed(1)}%',
                          _aggregateCpuPercent,
                        ),
                      ),
                      Expanded(
                        child: _buildSummaryColumn(
                          theme,
                          Icons.storage_rounded,
                          'RAM',
                          '${_aggregateMemoryPercent.toStringAsFixed(1)}%',
                          _aggregateMemoryPercent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Nodes
              Text(
                'Nodes',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ..._nodes.map((node) {
                final nodeColor = node.isReady ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Material(
                    color: theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.dns_rounded, size: 20, color: nodeColor),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  node.nodeName,
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(
                                node.isReady ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                size: 22,
                                color: nodeColor,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _nodeMetricRow(theme, 'CPU', '${node.cpuUsagePercent.toStringAsFixed(1)}%', node.cpuUsagePercent, nodeColor),
                          const SizedBox(height: 8),
                          _nodeMetricRow(theme, 'RAM', '${node.memoryUsagePercent.toStringAsFixed(1)}%', node.memoryUsagePercent, nodeColor),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, ThemeData theme) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryColumn(ThemeData theme, IconData icon, String label, String value, double? percent) {
    final color = const Color(0xFF22C55E);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        if (percent != null) ...[
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (percent / 100).clamp(0.0, 1.0),
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ],
      ],
    );
  }

  Widget _nodeMetricRow(ThemeData theme, String label, String value, double percent, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 40,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (percent / 100).clamp(0.0, 1.0),
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ),
      ],
    );
  }
}
