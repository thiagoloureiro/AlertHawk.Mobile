class MonitorStatus {
  final int monitorUp;
  final int monitorDown;
  final int monitorPaused;

  MonitorStatus({
    required this.monitorUp,
    required this.monitorDown,
    required this.monitorPaused,
  });

  factory MonitorStatus.fromJson(Map<String, dynamic> json) {
    return MonitorStatus(
      monitorUp: json['monitorUp'] ?? 0,
      monitorDown: json['monitorDown'] ?? 0,
      monitorPaused: json['monitorPaused'] ?? 0,
    );
  }
} 