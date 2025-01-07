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
  final int monitorTypeId;
  final String name;
  final bool status;
  final bool paused;
  final String? urlToCheck;
  final String? monitorTcp;
  final int monitorRegion;
  final int monitorEnvironment;
  final MonitorStatusDashboard monitorStatusDashboard;

  Monitor({
    required this.id,
    required this.monitorTypeId,
    required this.name,
    required this.status,
    required this.paused,
    this.urlToCheck,
    this.monitorTcp,
    required this.monitorRegion,
    required this.monitorEnvironment,
    required this.monitorStatusDashboard,
  });

  String get checkTarget => urlToCheck ?? monitorTcp ?? 'N/A';

  factory Monitor.fromJson(Map<String, dynamic> json) {
    return Monitor(
      id: json['id'] ?? 0,
      monitorTypeId: json['monitorTypeId'] ?? 0,
      name: json['name'] ?? '',
      status: json['status'] ?? false,
      paused: json['paused'] ?? false,
      urlToCheck: json['urlToCheck'],
      monitorTcp: json['monitorTcp'],
      monitorRegion: json['monitorRegion'] ?? 1,
      monitorEnvironment: json['monitorEnvironment'] ?? 6,
      monitorStatusDashboard:
          MonitorStatusDashboard.fromJson(json['monitorStatusDashboard'] ?? {}),
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
  final double uptime30Days;
  final double uptime3Months;
  final double uptime6Months;
  final int certExpDays;
  final double responseTime;
  List<MonitorHistoryData> historyData;

  MonitorStatusDashboard({
    required this.uptime1Hr,
    required this.uptime24Hrs,
    required this.uptime7Days,
    required this.uptime30Days,
    required this.uptime3Months,
    required this.uptime6Months,
    required this.certExpDays,
    required this.responseTime,
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
      uptime30Days: parseUptime(json['uptime30Days']),
      uptime3Months: parseUptime(json['uptime3Months']),
      uptime6Months: parseUptime(json['uptime6Months']),
      certExpDays: json['certExpDays'] ?? 0,
      responseTime: parseUptime(json['responseTime']),
      historyData: (json['historyData'] as List? ?? [])
          .map((data) => MonitorHistoryData.fromJson(data))
          .toList(),
    );
  }
}
