import 'package:image_picker/image_picker.dart';

class ReportModel {
  final String? reason;
  final List<XFile>? images;
  final int? reportedBy;
  final int? reportedWhom;
  final String? reportedByName; // Added for name of reported_by
  final String? reportedWhomName; // Added for name of reported_whom
  final int? reportId;
  final String? createdAt;
  final bool? status;

  ReportModel({
    this.reason,
    this.images,
    this.reportedBy,
    this.reportedWhom,
    this.reportedByName,
    this.reportedWhomName,
    this.reportId,
    this.createdAt,
    this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      'reason': reason,
      'images[]': images?.map((xfile) => xfile.path).toList() ?? [],
      'reported_by': reportedBy,
      'reported_whom': reportedWhom,
      'report_id': reportId,
      'created_at': createdAt,
      'status': status,
    };
  }

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      reason: json['reason'] as String?,
      images: json['images'] != null
          ? (json['images'] as List<dynamic>)
              .map((path) => XFile(path as String))
              .toList()
          : null,
      reportedBy: json['reported_by'] as int?,
      reportedWhom: json['reported_whom'] as int?,
      reportedByName: json['reported_by_name'] as String?,
      reportedWhomName: json['reported_whom_name'] as String?,
      reportId: json['report_id'] as int?,
      createdAt: json['created_at'] as String?,
      status: json['status'] as bool?,
    );
  }
}
