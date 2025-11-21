class PodMetric {
  final DateTime timestamp;
  final String clusterName;
  final String namespace;
  final String pod;
  final String container;
  final double cpuUsageCores;
  final double? cpuLimitCores;
  final int memoryUsageBytes;

  PodMetric({
    required this.timestamp,
    required this.clusterName,
    required this.namespace,
    required this.pod,
    required this.container,
    required this.cpuUsageCores,
    this.cpuLimitCores,
    required this.memoryUsageBytes,
  });

  factory PodMetric.fromJson(Map<String, dynamic> json) {
    return PodMetric(
      timestamp: DateTime.parse(json['timestamp'] as String),
      clusterName: json['clusterName'] as String,
      namespace: json['namespace'] as String,
      pod: json['pod'] as String,
      container: json['container'] as String,
      cpuUsageCores: (json['cpuUsageCores'] as num).toDouble(),
      cpuLimitCores: json['cpuLimitCores'] != null
          ? (json['cpuLimitCores'] as num).toDouble()
          : null,
      memoryUsageBytes: json['memoryUsageBytes'] as int,
    );
  }
}

