import 'package:image_picker/image_picker.dart';

class ReportModel {
  final String? reason;
  final List<XFile>? images;

  ReportModel({
    this.reason,
    this.images,
  });

  Map<String, dynamic> toJson() {
    return {
      'reason': reason,
      'images[]': images?.map((xfile) => xfile.path).toList() ?? [],
    };
  }

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      reason: json['reason'] as String?,
      images: (json['images'] as List<dynamic>?)
          ?.map((path) => XFile(path as String))
          .toList(),
    );
  }
}
