class ClusterEvent {
  final DateTime timestamp;
  final String clusterName;
  final String namespace;
  final String eventName;
  final String eventUid;
  final String involvedObjectKind;
  final String involvedObjectName;
  final String involvedObjectNamespace;
  final String eventType;
  final String reason;
  final String message;
  final String sourceComponent;
  final int count;
  final DateTime firstTimestamp;
  final DateTime lastTimestamp;

  ClusterEvent({
    required this.timestamp,
    required this.clusterName,
    required this.namespace,
    required this.eventName,
    required this.eventUid,
    required this.involvedObjectKind,
    required this.involvedObjectName,
    required this.involvedObjectNamespace,
    required this.eventType,
    required this.reason,
    required this.message,
    required this.sourceComponent,
    required this.count,
    required this.firstTimestamp,
    required this.lastTimestamp,
  });

  factory ClusterEvent.fromJson(Map<String, dynamic> json) {
    return ClusterEvent(
      timestamp: DateTime.parse(json['timestamp'] as String),
      clusterName: json['clusterName'] as String,
      namespace: json['namespace'] as String,
      eventName: json['eventName'] as String,
      eventUid: json['eventUid'] as String,
      involvedObjectKind: json['involvedObjectKind'] as String,
      involvedObjectName: json['involvedObjectName'] as String,
      involvedObjectNamespace: json['involvedObjectNamespace'] as String,
      eventType: json['eventType'] as String,
      reason: json['reason'] as String,
      message: json['message'] as String,
      sourceComponent: json['sourceComponent'] as String,
      count: (json['count'] as num).toInt(),
      firstTimestamp: DateTime.parse(json['firstTimestamp'] as String),
      lastTimestamp: DateTime.parse(json['lastTimestamp'] as String),
    );
  }
}
