class VolumeMetric {
  final DateTime timestamp;
  final String clusterName;
  final String namespace;
  final String pod;
  final String pvcNamespace;
  final String pvcName;
  final String volumeName;
  final int usedBytes;
  final int availableBytes;
  final int capacityBytes;

  VolumeMetric({
    required this.timestamp,
    required this.clusterName,
    required this.namespace,
    required this.pod,
    required this.pvcNamespace,
    required this.pvcName,
    required this.volumeName,
    required this.usedBytes,
    required this.availableBytes,
    required this.capacityBytes,
  });

  factory VolumeMetric.fromJson(Map<String, dynamic> json) {
    return VolumeMetric(
      timestamp: DateTime.parse(json['timestamp'] as String),
      clusterName: json['clusterName'] as String,
      namespace: json['namespace'] as String,
      pod: json['pod'] as String,
      pvcNamespace: json['pvcNamespace'] as String,
      pvcName: json['pvcName'] as String,
      volumeName: json['volumeName'] as String,
      usedBytes: (json['usedBytes'] as num).toInt(),
      availableBytes: (json['availableBytes'] as num).toInt(),
      capacityBytes: (json['capacityBytes'] as num).toInt(),
    );
  }

  double get usagePercent =>
      capacityBytes > 0 ? (usedBytes / capacityBytes) * 100 : 0;
}
