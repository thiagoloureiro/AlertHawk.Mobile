class NodeMetric {
  final DateTime timestamp;
  final String clusterName;
  final String nodeName;
  final double cpuUsageCores;
  final double cpuCapacityCores;
  final int memoryUsageBytes;
  final int memoryCapacityBytes;

  NodeMetric({
    required this.timestamp,
    required this.clusterName,
    required this.nodeName,
    required this.cpuUsageCores,
    required this.cpuCapacityCores,
    required this.memoryUsageBytes,
    required this.memoryCapacityBytes,
  });

  factory NodeMetric.fromJson(Map<String, dynamic> json) {
    return NodeMetric(
      timestamp: DateTime.parse(json['timestamp'] as String),
      clusterName: json['clusterName'] as String,
      nodeName: json['nodeName'] as String,
      cpuUsageCores: (json['cpuUsageCores'] as num).toDouble(),
      cpuCapacityCores: (json['cpuCapacityCores'] as num).toDouble(),
      memoryUsageBytes: json['memoryUsageBytes'] as int,
      memoryCapacityBytes: json['memoryCapacityBytes'] as int,
    );
  }

  double get cpuUsagePercent => (cpuUsageCores / cpuCapacityCores) * 100;
  double get memoryUsagePercent =>
      (memoryUsageBytes / memoryCapacityBytes) * 100;
}

