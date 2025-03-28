import 'package:image_picker/image_picker.dart';

class ReportModel {
  final String? reason;
  final List<XFile>? images;
  final int? reportedBy; // Add reported_by field
  final int? reportedWhom; // Add reported_whom field

  ReportModel({
    this.reason,
    this.images,
    this.reportedBy,
    this.reportedWhom,
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
      reason: json['reason'] as String?,
      images: (json['images'] as List<dynamic>?)
          ?.map((path) => XFile(path as String))
          .toList(),
      reportedBy: json['reported_by'] as int?,
      reportedWhom: json['reported_whom'] as int?,
    );
  }
}
