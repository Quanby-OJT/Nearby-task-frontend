import 'package:flutter/cupertino.dart';
import 'package:flutter_fe/model/user_model.dart';
import 'package:flutter_fe/model/task_model.dart';
import 'dart:convert';

class TaskerModel {
  final int? taskerId;
  final int userId;
  final String? bio;
  final int? specializationId;
  final String? specialization;
  final String? skills;
  final bool availability;
  final double? wagePerHour;
  final String? payPeriod;
  final Map<String, String>? socialMediaLinks;
  final double? rating;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final UserModel? user;
  final TaskerSpecialization? taskerSpecialization;
  final List<int>? taskerImagesId;
  final List<String>? taskerImages;
  final bool? group;
  final List<String>? taskerDocuments;

  // Computed getter for the id field (for backward compatibility)
  int get id => taskerId ?? 0;
  double get wage => wagePerHour ?? 0.0;
  DateTime get birthDate => createdAt ?? DateTime.now();
  // bool? get group => null;
  Map<String, String>? get address => null;

  TaskerModel(
      {required this.taskerId,
      required this.userId,
      required this.bio,
      this.specializationId,
      this.specialization,
      this.skills,
      required this.availability,
      this.wagePerHour,
      this.payPeriod,
      this.socialMediaLinks,
      this.rating,
      this.createdAt,
      this.updatedAt,
      this.user,
      this.taskerSpecialization,
      this.taskerImagesId,
      this.taskerImages,
      this.taskerDocuments,
      this.group});

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
      "specialization": specialization ?? '',
      "skills": skills ?? '',
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
      "profile_images_id": taskerImagesId,
      "tasker_documents": taskerDocuments,
      "group": group ?? false,
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

    debugPrint("Tasker Model: ${json}");

    return TaskerModel(
      taskerId: json['tasker_id'] as int? ?? json['id'] as int?,
      userId: json['user_id'] != null ? json['user_id'] as int : 0,
      bio: json['bio'] as String? ?? '',
      specializationId: json['specialization_id'] as int? ?? 0,
      specialization:
          json['tasker_specialization']?['specialization'] as String? ?? '',
      skills: json['skills'] as String? ?? '',
      availability: (json['availability'] is int
              ? json['availability'] == 1
              : json['availability'] as bool?) ??
          false,
      wagePerHour: (json['wage_per_hour'] is int
              ? (json['wage_per_hour'] as int).toDouble()
              : json['wage_per_hour'] as double?) ??
          0.0,
      payPeriod: json['pay_period'] as String? ?? '',
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
      taskerImagesId:
          json['profile_images'] != null && json['profile_images'] is List
              ? List<int>.from((json['profile_images'] as List<dynamic>)
                  .map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0))
              : [],
      group: json['group'] as bool? ?? false,
      taskerImages: json['images_url'] ?? []
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
      group: group ?? this.group,
    );
  }
}
