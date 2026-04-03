class FinOpsAnalysisRun {
  final int id;
  final String subscriptionId;
  final String subscriptionName;
  final String description;
  final DateTime runDate;
  final double totalMonthlyCost;
  final int totalResourcesAnalyzed;
  final String aiModel;
  final String conversationId;
  final String reportFilePath;
  final DateTime createdAt;

  FinOpsAnalysisRun({
    required this.id,
    required this.subscriptionId,
    required this.subscriptionName,
    required this.description,
    required this.runDate,
    required this.totalMonthlyCost,
    required this.totalResourcesAnalyzed,
    required this.aiModel,
    required this.conversationId,
    required this.reportFilePath,
    required this.createdAt,
  });

  factory FinOpsAnalysisRun.fromJson(Map<String, dynamic> json) {
    return FinOpsAnalysisRun(
      id: json['id'] as int,
      subscriptionId: json['subscriptionId'] as String,
      subscriptionName: json['subscriptionName'] as String? ?? '',
      description: json['description'] as String? ?? '',
      runDate: DateTime.parse(json['runDate'] as String),
      totalMonthlyCost: (json['totalMonthlyCost'] as num).toDouble(),
      totalResourcesAnalyzed: json['totalResourcesAnalyzed'] as int,
      aiModel: json['aiModel'] as String? ?? '',
      conversationId: json['conversationId'] as String? ?? '',
      reportFilePath: json['reportFilePath'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
