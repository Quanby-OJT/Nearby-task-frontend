import 'dart:convert';

class SettingModel {
  final int? id;
  final int? taskerId;
  final double? latitude;
  final double? longitude;
  final int? distance;
  final int? ageStart;
  final int? ageEnd;
  final bool? limit;
  final List<String>? specialization;
  final String? createdAt;
  final String? updatedAt;

  SettingModel({
    this.id,
    this.taskerId,
    this.latitude,
    this.longitude,
    this.distance,
    this.ageStart,
    this.ageEnd,
    this.limit,
    this.specialization,
    this.createdAt,
    this.updatedAt,
  });

  factory SettingModel.fromJson(Map<String, dynamic> json) {
    List<String>? specializationList;
    if (json['specialization'] != null && json['specialization'] is String) {
      String specString = json['specialization'].toString();
      try {
        specString = specString.replaceAll("'", '"');
        specializationList = List<String>.from(jsonDecode(specString));
      } catch (e) {
        specializationList = specString
            .replaceAll('[', '')
            .replaceAll(']', '')
            .split(',')
            .map((s) => s.trim())
            .toList();
      }
    } else if (json['specialization'] is List) {
      specializationList = List<String>.from(json['specialization']);
    }

    return SettingModel(
      id: json['id'] is int ? json['id'] : null,
      taskerId: json['tasker_id'] is int ? json['tasker_id'] : null,
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
      distance: json['distance'] is int ? json['distance'] : null,
      ageStart: json['age_start'] is int ? json['age_start'] : null,
      ageEnd: json['age_end'] is int ? json['age_end'] : null,
      limit: json['limit'] is bool ? json['limit'] : null,
      specialization: specializationList,
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tasker_id': taskerId,
      'latitude': latitude,
      'longitude': longitude,
      'distance': distance,
      'age_start': ageStart,
      'age_end': ageEnd,
      'limit': limit,
      'specialization': specialization?.toString(),
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
