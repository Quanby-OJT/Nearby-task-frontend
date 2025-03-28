import 'package:image_picker/image_picker.dart';

class ReportModel {
  final String? reason;
  final List<XFile>? images;
  final int? reportedBy;
  final int? reportedWhom;
  final int? reportId; // Added for report_id
  final String? createdAt; // Added for created_at
  final bool? status; // Added for status

  ReportModel({
    this.reason,
    this.images,
    this.reportedBy,
    this.reportedWhom,
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
      reportId: json['report_id'] as int?,
      createdAt: json['created_at'] as String?,
      status: json['status'] as bool?,
    );
  }
}
