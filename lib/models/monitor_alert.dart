/// Represents an alert event for a monitor (e.g. down, recovered, message).
class MonitorAlert {
  final int id;
  final int monitorId;
  final DateTime timeStamp;
  final bool status;
  final String message;
  final String monitorName;
  final int environment;
  final String urlToCheck;
  final int periodOffline;

  const MonitorAlert({
    required this.id,
    required this.monitorId,
    required this.timeStamp,
    required this.status,
    required this.message,
    required this.monitorName,
    required this.environment,
    required this.urlToCheck,
    required this.periodOffline,
  });

  /// Timestamp adjusted to local time zone for display.
  DateTime get localTimeStamp {
    final now = DateTime.now();
    final offset = now.timeZoneOffset;
    return timeStamp.add(offset);
  }

  /// True when the monitor was up at this alert; false when down/issue.
  bool get wasUp => status;

  factory MonitorAlert.fromJson(Map<String, dynamic> json) {
    return MonitorAlert(
      id: json['id'] as int? ?? 0,
      monitorId: json['monitorId'] as int? ?? 0,
      timeStamp: DateTime.tryParse(json['timeStamp'] as String? ?? '') ?? DateTime.now(),
      status: json['status'] as bool? ?? false,
      message: (json['message'] as String?) ?? '',
      monitorName: (json['monitorName'] as String?) ?? '',
      environment: (json['environment'] as int?) ?? 0,
      urlToCheck: (json['urlToCheck'] as String?) ?? '',
      periodOffline: (json['periodOffline'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'monitorId': monitorId,
      'timeStamp': timeStamp.toIso8601String(),
      'status': status,
      'message': message,
      'monitorName': monitorName,
      'environment': environment,
      'urlToCheck': urlToCheck,
      'periodOffline': periodOffline,
    };
  }
}
