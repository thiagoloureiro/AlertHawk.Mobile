class FinOpsCostDetail {
  final int id;
  final int analysisRunId;
  final String costType;
  final String name;
  final String resourceGroup;
  final double cost;
  final DateTime recordedAt;

  FinOpsCostDetail({
    required this.id,
    required this.analysisRunId,
    required this.costType,
    required this.name,
    required this.resourceGroup,
    required this.cost,
    required this.recordedAt,
  });

  factory FinOpsCostDetail.fromJson(Map<String, dynamic> json) {
    return FinOpsCostDetail(
      id: json['id'] as int,
      analysisRunId: json['analysisRunId'] as int,
      costType: json['costType'] as String? ?? '',
      name: json['name'] as String? ?? '',
      resourceGroup: json['resourceGroup'] as String? ?? '',
      cost: (json['cost'] as num).toDouble(),
      recordedAt: DateTime.parse(json['recordedAt'] as String),
    );
  }
}
