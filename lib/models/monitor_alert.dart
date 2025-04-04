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

  MonitorAlert({
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

  DateTime get localTimeStamp {
    final now = DateTime.now();
    final offset = now.timeZoneOffset;
    return timeStamp.add(offset);
  }

  factory MonitorAlert.fromJson(Map<String, dynamic> json) {
    return MonitorAlert(
      id: json['id'],
      monitorId: json['monitorId'],
      timeStamp: DateTime.parse(json['timeStamp']),
      status: json['status'],
      message: json['message'],
      monitorName: json['monitorName'],
      environment: json['environment'],
      urlToCheck: json['urlToCheck'],
      periodOffline: json['periodOffline'] ?? 0,
    );
  }
}
