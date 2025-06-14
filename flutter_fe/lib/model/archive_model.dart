class ArchiveDataModel {
  final int id;
  final String date;
  final String period;

  ArchiveDataModel({
    required this.id,
    required this.date,
    required this.period,
  });
}

class ArchiveConfig {
  final DateTime archiveDate;
  final String archivePeriod;
  final DateTime createdAt;
  final bool isEnabled;

  ArchiveConfig({
    required this.archiveDate,
    required this.archivePeriod,
    required this.createdAt,
    this.isEnabled = false,
  });

  factory ArchiveConfig.fromJson(Map<String, dynamic> json) {
    return ArchiveConfig(
      archiveDate: DateTime.parse(json['archiveDate']),
      archivePeriod: json['archivePeriod'],
      createdAt: DateTime.parse(json['createdAt']),
      isEnabled: json['isEnabled'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'archiveDate': archiveDate.toIso8601String(),
      'archivePeriod': archivePeriod,
      'createdAt': createdAt.toIso8601String(),
      'isEnabled': isEnabled,
    };
  }
}
