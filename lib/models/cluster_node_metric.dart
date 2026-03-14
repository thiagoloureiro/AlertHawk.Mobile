/// Single node metrics from the cluster dashboard API (/metrics/api/Metrics/node).
/// Response is one object per node; group by clusterName to build cluster cards.
class ClusterNodeMetric {
  final DateTime timestamp;
  final String clusterName;
  final String clusterEnvironment;
  final String nodeName;
  final double cpuUsageCores;
  final double cpuCapacityCores;
  final int memoryUsageBytes;
  final int memoryCapacityBytes;
  final String? kubernetesVersion;
  final String? cloudProvider;
  final bool isReady;
  final bool hasMemoryPressure;
  final bool hasDiskPressure;
  final bool hasPidPressure;
  final String? architecture;
  final String? operatingSystem;
  final String? region;
  final String? instanceType;

  const ClusterNodeMetric({
    required this.timestamp,
    required this.clusterName,
    required this.clusterEnvironment,
    required this.nodeName,
    required this.cpuUsageCores,
    required this.cpuCapacityCores,
    required this.memoryUsageBytes,
    required this.memoryCapacityBytes,
    this.kubernetesVersion,
    this.cloudProvider,
    this.isReady = true,
    this.hasMemoryPressure = false,
    this.hasDiskPressure = false,
    this.hasPidPressure = false,
    this.architecture,
    this.operatingSystem,
    this.region,
    this.instanceType,
  });

  double get cpuUsagePercent =>
      cpuCapacityCores > 0 ? (cpuUsageCores / cpuCapacityCores) * 100 : 0;

  double get memoryUsagePercent => memoryCapacityBytes > 0
      ? (memoryUsageBytes / memoryCapacityBytes) * 100
      : 0;

  factory ClusterNodeMetric.fromJson(Map<String, dynamic> json) {
    return ClusterNodeMetric(
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
      clusterName: (json['clusterName'] as String?) ?? '',
      clusterEnvironment: (json['clusterEnvironment'] as String?) ?? 'PROD',
      nodeName: (json['nodeName'] as String?) ?? '',
      cpuUsageCores: ((json['cpuUsageCores'] as num?) ?? 0).toDouble(),
      cpuCapacityCores: ((json['cpuCapacityCores'] as num?) ?? 0).toDouble(),
      memoryUsageBytes: ((json['memoryUsageBytes'] as num?) ?? 0).toInt(),
      memoryCapacityBytes: ((json['memoryCapacityBytes'] as num?) ?? 0).toInt(),
      kubernetesVersion: json['kubernetesVersion'] as String?,
      cloudProvider: json['cloudProvider'] as String?,
      isReady: json['isReady'] as bool? ?? true,
      hasMemoryPressure: json['hasMemoryPressure'] as bool? ?? false,
      hasDiskPressure: json['hasDiskPressure'] as bool? ?? false,
      hasPidPressure: json['hasPidPressure'] as bool? ?? false,
      architecture: json['architecture'] as String?,
      operatingSystem: json['operatingSystem'] as String?,
      region: json['region'] as String?,
      instanceType: json['instanceType'] as String?,
    );
  }
}
