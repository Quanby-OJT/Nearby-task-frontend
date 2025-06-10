import 'package:flutter_fe/model/user_model.dart';
import 'package:flutter_fe/model/task_model.dart';
import 'dart:convert';

class TaskerModel {
  final int? taskerId;
  final int? userId;
  final String? bio;
  final int? specializationId;
  final String? specialization;
  final String? skills;
  final bool? availability;
  final double? wagePerHour;
  final String? payPeriod;
  final Map<String, String>? socialMediaLinks;
  final double? rating;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final UserModel? user;
  final TaskerSpecialization? taskerSpecialization;
  final List<String>? taskerImages;
  final bool? group;
  final List<String>? taskerDocuments;

  // Computed getter for the id field (for backward compatibility)
  int get id => taskerId ?? 0;
  double get wage => wagePerHour ?? 0.0;
  DateTime get birthDate => createdAt ?? DateTime.now();
  // bool? get group => null;
  Map<String, String>? get address => null;

  TaskerModel({
    this.taskerId,
    this.userId,
    this.bio,
    this.specializationId,
    this.specialization,
    this.skills,
    this.availability,
    this.wagePerHour,
    this.payPeriod,
    this.socialMediaLinks,
    this.rating,
    this.createdAt,
    this.updatedAt,
    this.user,
    this.taskerSpecialization,
    this.taskerImages,
    this.taskerDocuments,
    this.group
  });

  @override
  String toString() {
    return "TaskerModel(taskerId: $taskerId, userId: $userId, bio: $bio, specialization: $specialization, skills: $skills, user: $user)";
  }

  Map<String, dynamic> toJson() {
    return {
      "tasker_id": taskerId,
      "user_id": userId,
      "bio": bio,
      "specialization_id": specializationId,
      "specialization": specialization,
      "skills": skills,
      "availability": availability,
      "wage_per_hour": wagePerHour,
      "pay_period": payPeriod,
      "social_media_links":
          socialMediaLinks != null ? jsonEncode(socialMediaLinks) : '{}',
      "rating": rating,
      "created_at": createdAt?.toIso8601String(),
      "updated_at": updatedAt?.toIso8601String(),
      "user": user?.toJson(),
      "tasker_specialization": taskerSpecialization?.toJson(),
      "profile_images": taskerImages,
      "tasker_documents": taskerDocuments,
      "group": group,
    };
  }

  factory TaskerModel.fromJson(Map<String, dynamic> json) {
    Map<String, String>? socialLinks;
    if (json['social_media_links'] != null) {
      try {
        if (json['social_media_links'] is String) {
          final decoded = jsonDecode(json['social_media_links']);
          socialLinks = Map<String, String>.from(decoded);
        } else if (json['social_media_links'] is Map) {
          socialLinks = Map<String, String>.from(json['social_media_links']);
        }
      } catch (e) {
        socialLinks = {};
      }
    }

    return TaskerModel(
      taskerId: json['tasker_id'] as int? ?? json['id'] as int?,
      userId: json['user_id'] as int?,
      bio: json['bio'] as String?,
      specializationId: json['specialization_id'] as int?,
      specialization: json['tasker_specialization']['specialization'] as String?,
      skills: json['skills'] as String?,
      availability: json['availability'] as bool?,
      wagePerHour: (json['wage_per_hour'] is int
              ? (json['wage_per_hour'] as int).toDouble()
              : json['wage_per_hour'] as double?) ??
          (json['wage'] is int
              ? (json['wage'] as int).toDouble()
              : json['wage'] as double?),
      payPeriod: json['pay_period'] as String?,
      socialMediaLinks: socialLinks,
      rating: (json['rating'] is int
              ? (json['rating'] as int).toDouble()
              : json['rating'] as double?) ??
          0.0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      user: json['user'] != null
          ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      taskerSpecialization: json['tasker_specialization'] != null
          ? TaskerSpecialization.fromJson(
              json['tasker_specialization'] as Map<String, dynamic>)
          : null,
      taskerImages: json['profile_images'] != null && json['profile_images'] is List
          ? (json['profile_images'] as List<dynamic>?)
              ?.map((image) {
                return image is String ? image : ''; // Or handle the error as appropriate
              })
              ?.toList() ?? []
          : [],
    );
  }

  // Create a copy with updated fields
  TaskerModel copyWith({
    int? taskerId,
    int? userId,
    String? bio,
    int? specializationId,
    String? specialization,
    String? skills,
    bool? availability,
    double? wagePerHour,
    String? payPeriod,
    Map<String, String>? socialMediaLinks,
    double? rating,
    DateTime? createdAt,
    DateTime? updatedAt,
    UserModel? user,
    TaskerSpecialization? taskerSpecialization,
  }) {
    return TaskerModel(
      taskerId: taskerId ?? this.taskerId,
      userId: userId ?? this.userId,
      bio: bio ?? this.bio,
      specializationId: specializationId ?? this.specializationId,
      specialization: specialization ?? this.specialization,
      skills: skills ?? this.skills,
      availability: availability ?? this.availability,
      wagePerHour: wagePerHour ?? this.wagePerHour,
      payPeriod: payPeriod ?? this.payPeriod,
      socialMediaLinks: socialMediaLinks ?? this.socialMediaLinks,
      rating: rating ?? this.rating,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      user: user ?? this.user,
      taskerSpecialization: taskerSpecialization ?? this.taskerSpecialization,
    );
  }
}
