class MonitorAgent {
  final int id;
  final String hostname;
  final DateTime timeStamp;
  final bool isMaster;
  final int listTasks;
  final String version;
  final int monitorRegion;

  MonitorAgent({
    required this.id,
    required this.hostname,
    required this.timeStamp,
    required this.isMaster,
    required this.listTasks,
    required this.version,
    required this.monitorRegion,
  });

  factory MonitorAgent.fromJson(Map<String, dynamic> json) {
    return MonitorAgent(
      id: json['id'],
      hostname: json['hostname'],
      timeStamp: DateTime.parse(json['timeStamp']),
      isMaster: json['isMaster'],
      listTasks: json['listTasks'],
      version: json['version'],
      monitorRegion: json['monitorRegion'],
    );
  }
}
