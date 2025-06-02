class ImagesModel {
  final int? id;
  final String image_url;
  final String? created_at;
  final String? updated_at;
  final int? user_id;

  ImagesModel({
    this.id,
    required this.image_url,
    this.created_at,
    this.updated_at,
    this.user_id,
  });

  factory ImagesModel.fromJson(Map<String, dynamic> json) {
    return ImagesModel(
      id: _parseInt(json['id']),
      image_url: json['image_link'] ?? '',
      created_at: json['created_at'],
      updated_at: json['updated_at'],
      user_id: _parseInt(json['user_id']),
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value) ?? null;
    }
    return null;
  }
}
