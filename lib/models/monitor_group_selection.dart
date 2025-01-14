class MonitorGroupSelection {
  final int id;
  final String name;
  bool isSelected;

  MonitorGroupSelection({
    required this.id,
    required this.name,
    this.isSelected = false,
  });

  factory MonitorGroupSelection.fromJson(Map<String, dynamic> json) {
    return MonitorGroupSelection(
      id: json['id'],
      name: json['name'],
    );
  }
}
