import 'package:image_picker/image_picker.dart';

class ReportModel {
  final String? reason;
  final List<XFile>? images;
  final int? reportedBy; // Add reported_by field
  final int? reportedWhom; // Add reported_whom field
  final int? reportId; // Add report_id field
  final String? createdAt; // Add created_at field
  final String? updatedAt; // Add updated_at field
  final bool? status; // Add status field
  final String? imageUrl; // Add images field (as a URL string from backend)
  final int? actionBy; // Add action_by field

  ReportModel({
    this.reason,
    this.images,
    this.reportedBy,
    this.reportedWhom,
    this.reportId,
    this.createdAt,
    this.updatedAt,
    this.status,
    this.imageUrl,
    this.actionBy,
  });

  Map<String, dynamic> toJson() {
    return {
      'reason': reason,
      'images[]': images?.map((xfile) => xfile.path).toList() ?? [],
      'reported_by': reportedBy, // Include in JSON
      'reported_whom': reportedWhom, // Include in JSON
    };
  }

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      reportId: json['report_id'] as int?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      reportedBy: json['reported_by'] as int?,
      reportedWhom: json['reported_whom'] as int?,
      reason: json['reason'] as String?,
      status: json['status'] as bool?,
      imageUrl: json['images'] as String?,
      actionBy: json['action_by'] as int?,
      images: (json['images'] as List<dynamic>?)
          ?.map((path) => XFile(path as String))
          .toList(),
    );
  }
}
