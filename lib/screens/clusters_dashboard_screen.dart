import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/cluster_node_metric.dart';
import '../services/metrics_service.dart';
import '../widgets/theme_selector_modal.dart';
import 'cluster_detail_screen.dart';

class ClustersDashboardScreen extends StatefulWidget {
  const ClustersDashboardScreen({super.key});

  @override
  State<ClustersDashboardScreen> createState() => _ClustersDashboardScreenState();
}

class _ClustersDashboardScreenState extends State<ClustersDashboardScreen> {
  late Future<List<ClusterNodeMetric>> _nodesFuture;
  int _minutes = 1;
  /// All = null, or "PROD" / "TEST"
  String? _envFilter;

  @override
  void initState() {
    super.initState();
    _nodesFuture = MetricsService.getClusterDashboardNodes(minutes: _minutes);
  }

  void _refresh() {
    setState(() {
      _nodesFuture = MetricsService.getClusterDashboardNodes(minutes: _minutes);
    });
  }

  /// Group nodes by cluster (name + environment). Returns map keyed by "name|env".
  Map<String, List<ClusterNodeMetric>> _groupByCluster(List<ClusterNodeMetric> nodes) {
    final map = <String, List<ClusterNodeMetric>>{};
    for (final n in nodes) {
      final key = '${n.clusterName}|${n.clusterEnvironment}';
      map.putIfAbsent(key, () => []).add(n);
    }
    return map;
  }

  List<String> _filterClusterKeys(Map<String, List<ClusterNodeMetric>> byCluster, String? envFilter) {
    var keys = byCluster.keys.toList()..sort();
    if (envFilter == null || envFilter.isEmpty) return keys;
    final envUpper = envFilter.toUpperCase();
    return keys.where((key) {
      final nodes = byCluster[key]!;
      return nodes.first.clusterEnvironment.toUpperCase() == envUpper;
    }).toList();
  }

  Widget _buildFilterBar(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Text(
            'Environment',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Row(
            children: [
              _envChip('All', _envFilter == null),
              const SizedBox(width: 8),
              _envChip('PROD', _envFilter == 'PROD'),
              const SizedBox(width: 8),
              _envChip('TEST', _envFilter == 'TEST'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _envChip(String label, bool selected) {
    return FilterChip(
      label: Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: selected ? FontWeight.w600 : FontWeight.w500)),
      selected: selected,
      onSelected: (v) {
        setState(() {
          _envFilter = label == 'All' ? null : label;
        });
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Clusters Dashboard',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            letterSpacing: -0.3,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refresh,
            tooltip: 'Refresh',
          ),
          IconButton(
            tooltip: 'Select theme',
            icon: const Icon(Icons.palette_outlined),
            onPressed: () => showThemeSelectorModal(context),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildFilterBar(theme),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _refresh(),
              child: FutureBuilder<List<ClusterNodeMetric>>(
          future: _nodesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              final errMsg = snapshot.error?.toString() ?? 'Unknown error';
              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_off_rounded,
                        size: 56,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load clusters',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        errMsg,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      FilledButton.tonal(
                        onPressed: _refresh,
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.refresh_rounded, size: 18),
                            SizedBox(width: 8),
                            Text('Retry'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            final nodes = snapshot.data ?? [];
            if (nodes.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.dns_rounded,
                      size: 56,
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No cluster data',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            }

            final byCluster = _groupByCluster(nodes);
            final clusterKeys = _filterClusterKeys(byCluster, _envFilter);

            if (clusterKeys.isEmpty) {
              return Center(
                child: Text(
                  'No clusters for this filter',
                  style: GoogleFonts.inter(color: theme.colorScheme.onSurfaceVariant),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: clusterKeys.length,
              itemBuilder: (context, index) {
                final key = clusterKeys[index];
                final clusterNodes = byCluster[key]!;
                return InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ClusterDetailScreen(
                          clusterName: clusterNodes.first.clusterName,
                          clusterEnvironment: clusterNodes.first.clusterEnvironment,
                          nodes: clusterNodes,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: _ClusterCard(
                    clusterName: clusterNodes.first.clusterName,
                    clusterEnvironment: clusterNodes.first.clusterEnvironment,
                    nodes: clusterNodes,
                  ),
                );
              },
            );
          },
        ),
      ),
    ),
    ],
    ),
    );
  }
}

class _ClusterCard extends StatelessWidget {
  final String clusterName;
  final String clusterEnvironment;
  final List<ClusterNodeMetric> nodes;

  const _ClusterCard({
    required this.clusterName,
    required this.clusterEnvironment,
    required this.nodes,
  });

  bool get isClusterReady => nodes.every((n) => n.isReady);
  int get readyCount => nodes.where((n) => n.isReady).length;
  double get aggregateCpuPercent {
    double used = 0, cap = 0;
    for (final n in nodes) {
      used += n.cpuUsageCores;
      cap += n.cpuCapacityCores;
    }
    return cap > 0 ? (used / cap) * 100 : 0;
  }

  double get aggregateMemoryPercent {
    int used = 0, cap = 0;
    for (final n in nodes) {
      used += n.memoryUsageBytes;
      cap += n.memoryCapacityBytes;
    }
    return cap > 0 ? (used / cap) * 100 : 0;
  }

  DateTime? get lastUpdate {
    if (nodes.isEmpty) return null;
    return nodes.map((n) => n.timestamp).reduce((a, b) => a.isAfter(b) ? a : b);
  }

  String get lastUpdateLabel {
    final t = lastUpdate;
    if (t == null) return 'Unknown';
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
    final statusColor = isClusterReady ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
    final k8sVersion = nodes.first.kubernetesVersion;
    final cloudProvider = nodes.first.cloudProvider;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: statusColor.withOpacity(0.6),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.account_tree_rounded,
                      size: 22,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        clusterName,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 17,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: clusterEnvironment.toUpperCase() == 'TEST'
                            ? const Color(0xFF22C55E).withOpacity(0.2)
                            : clusterEnvironment.toUpperCase() == 'PROD'
                                ? const Color(0xFFEF4444).withOpacity(0.2)
                                : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        clusterEnvironment.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: clusterEnvironment.toUpperCase() == 'TEST'
                              ? const Color(0xFF22C55E)
                              : clusterEnvironment.toUpperCase() == 'PROD'
                                  ? const Color(0xFFEF4444)
                                  : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      isClusterReady ? Icons.check_circle_rounded : Icons.cancel_rounded,
                      size: 18,
                      color: statusColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isClusterReady ? 'OK' : 'Issue',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: statusColor,
                      ),
                    ),
                    if (k8sVersion != null && k8sVersion.isNotEmpty) ...[
                      const SizedBox(width: 16),
                      Icon(Icons.code_rounded, size: 16, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        k8sVersion,
                        style: GoogleFonts.inter(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                    if (cloudProvider != null && cloudProvider.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Icon(Icons.cloud_rounded, size: 16, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        cloudProvider,
                        style: GoogleFonts.inter(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: 14, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      'Last update: $lastUpdateLabel',
                      style: GoogleFonts.inter(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _SummaryCell(
                      icon: Icons.dns_rounded,
                      label: 'Nodes',
                      value: '$readyCount / ${nodes.length}',
                      theme: theme,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _SummaryCell(
                        icon: Icons.memory_rounded,
                        label: 'CPU',
                        value: '${aggregateCpuPercent.toStringAsFixed(0)}%',
                        percent: aggregateCpuPercent,
                        theme: theme,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _SummaryCell(
                        icon: Icons.storage_rounded,
                        label: 'RAM',
                        value: '${aggregateMemoryPercent.toStringAsFixed(0)}%',
                        percent: aggregateMemoryPercent,
                        theme: theme,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...nodes.map((node) {
                  final nodeColor = node.isReady ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
                  return Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            node.nodeName,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.memory_rounded, size: 14, color: nodeColor),
                              const SizedBox(width: 4),
                              Text(
                                '${node.cpuUsagePercent.toStringAsFixed(0)}%',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: nodeColor,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: node.cpuUsagePercent / 100,
                                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                                    valueColor: AlwaysStoppedAnimation<Color>(nodeColor),
                                    minHeight: 6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.storage_rounded, size: 14, color: nodeColor),
                              const SizedBox(width: 4),
                              Text(
                                '${node.memoryUsagePercent.toStringAsFixed(0)}%',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: nodeColor,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: node.memoryUsagePercent / 100,
                                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                                    valueColor: AlwaysStoppedAnimation<Color>(nodeColor),
                                    minHeight: 6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          node.isReady ? Icons.check_circle_rounded : Icons.cancel_rounded,
                          size: 18,
                          color: nodeColor,
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryCell extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final double? percent;
  final ThemeData theme;

  const _SummaryCell({
    required this.icon,
    required this.label,
    required this.value,
    this.percent,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final color = const Color(0xFF22C55E);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (percent != null) ...[
          Row(
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (percent! / 100).clamp(0.0, 1.0),
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 6,
                  ),
                ),
              ),
            ],
          ),
        ] else
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
      ],
    );
  }
}
