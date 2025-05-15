import 'dart:convert';
import 'package:image_picker/image_picker.dart';

class ReportModel {
  final String? reason;
  final List<XFile>? images;
  final List<String>? imageUrls;
  final int? reportedBy;
  final int? reportedWhom;
  final String? reportedByName;
  final String? reportedWhomName;
  final int? reportId;
  final String? createdAt;
  final bool? status;

  ReportModel({
    this.reason,
    this.images,
    this.imageUrls,
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
      'reported_by': reportedBy,
      'reported_whom': reportedWhom,
    };
  }

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      reason: json['reason'] as String?,
      imageUrls: json['images'] != null
          ? List<String>.from(jsonDecode(json['images'] as String))
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
