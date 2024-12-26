class MonitorGroup {
  final int id;
  final String name;
  final List<Monitor> monitors;
  final double avgUptime1Hr;
  final double avgUptime24Hrs;
  final double avgUptime7Days;

  MonitorGroup({
    required this.id,
    required this.name,
    required this.monitors,
    required this.avgUptime1Hr,
    required this.avgUptime24Hrs,
    required this.avgUptime7Days,
  });

  factory MonitorGroup.fromJson(Map<String, dynamic> json) {
    return MonitorGroup(
      id: json['id'],
      name: json['name'],
      monitors: (json['monitors'] as List)
          .map((monitor) => Monitor.fromJson(monitor))
          .toList(),
      avgUptime1Hr: (json['avgUptime1Hr'] ?? 0).toDouble(),
      avgUptime24Hrs: (json['avgUptime24Hrs'] ?? 0).toDouble(),
      avgUptime7Days: (json['avgUptime7Days'] ?? 0).toDouble(),
    );
  }
}

class Monitor {
  final int id;
  final String name;
  final bool status;
  final MonitorStatusDashboard monitorStatusDashboard;

  Monitor({
    required this.id,
    required this.name,
    required this.status,
    required this.monitorStatusDashboard,
  });

  factory Monitor.fromJson(Map<String, dynamic> json) {
    return Monitor(
      id: json['id'],
      name: json['name'],
      status: json['status'],
      monitorStatusDashboard:
          MonitorStatusDashboard.fromJson(json['monitorStatusDashboard']),
    );
  }
}

class MonitorHistoryData {
  final DateTime timeStamp;
  final int responseTime;
  final bool status;

  MonitorHistoryData({
    required this.timeStamp,
    required this.responseTime,
    required this.status,
  });

  DateTime get localTimeStamp {
    final now = DateTime.now();
    final offset = now.timeZoneOffset;
    return timeStamp.add(offset);
  }

  factory MonitorHistoryData.fromJson(Map<String, dynamic> json) {
    return MonitorHistoryData(
      timeStamp: DateTime.parse(json['timeStamp']),
      responseTime: json['responseTime'],
      status: json['status'],
    );
  }
}

class MonitorStatusDashboard {
  final double uptime1Hr;
  final double uptime24Hrs;
  final double uptime7Days;
  final List<MonitorHistoryData> historyData;

  MonitorStatusDashboard({
    required this.uptime1Hr,
    required this.uptime24Hrs,
    required this.uptime7Days,
    required this.historyData,
  });

  factory MonitorStatusDashboard.fromJson(Map<String, dynamic> json) {
    double parseUptime(dynamic value) {
      if (value == null) return 0.0;
      if (value is int) return value.toDouble();
      if (value is double) return value;
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return MonitorStatusDashboard(
      uptime1Hr: parseUptime(json['uptime1Hr']),
      uptime24Hrs: parseUptime(json['uptime24Hrs']),
      uptime7Days: parseUptime(json['uptime7Days']),
      historyData: (json['historyData'] as List? ?? [])
          .map((data) => MonitorHistoryData.fromJson(data))
          .toList(),
    );
  }
}
