import 'package:flutter_fe/model/user_model.dart';

class TaskerModel {
  final int? id;
  final String bio;
  final String specialization;
  final String skills;
  final bool availability;
  final int? taskerDocuments;
  final Map<String, String>? socialMediaLinks;
  final String taskerAddress;
  final double wage;
  final String payPeriod;
  final DateTime birthDate;
  final String phoneNumber;
  final bool group;
  final String gender;
  UserModel? user;

  TaskerModel({
    this.id,
    required this.bio,
    required this.group,
    required this.specialization,
    required this.skills,
    required this.taskerAddress,
    required this.availability,
    required this.wage,
    required this.payPeriod,
    required this.birthDate,
    required this.phoneNumber,
    required this.gender,
    this.taskerDocuments,
    this.socialMediaLinks,
    this.user,
  });

  @override
  String toString() {
    return "Tasker(id: $id, bio: $bio, specialization: $specialization, user: $user)";
  }

  // Factory method to map JSON to TaskerModel
  factory TaskerModel.fromJson(Map<String, dynamic> json) {
    return TaskerModel(
      id: json["tasker_id"] ?? 0, // Correct key for ID
      bio: json['bio'] ?? '',
      skills: json['skills'] ?? '',
      availability: json['availability'] ?? false,
      socialMediaLinks: json['social_media_links'] != null
          ? Map<String, String>.from(json['social_media_links'])
          : null,
      taskerAddress: json['address'] ?? '',
      specialization:
          json['specialization_id']?.toString() ?? '', // Use specialization_id
      taskerDocuments:
          json['tesda_documents_id'] ?? 0, // Adjusted for null safety
      wage: (json['wage_per_hour'] is int)
          ? json['wage_per_hour'].toDouble()
          : double.tryParse(json['wage_per_hour'].toString()) ?? 0.0,
      payPeriod: json['pay_period'] ?? "Hourly", // Added default value
      birthDate: json['birthdate'] != null
          ? DateTime.tryParse(json['birthdate']) ?? DateTime(2000, 1, 1)
          : DateTime(2000, 1, 1), // Default fallback
      phoneNumber: json['contact_number']?.toString() ?? '',
      gender: json['gender'] ?? '',
      group: json['group'] ?? false,
      user: json['user'] != null
          ? UserModel.fromJson(json['user'])
          : null, // Ensure user object is correctly parsed
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "tasker_id": id,
      "bio": bio,
      "specialization_id": specialization,

      // must/json in another table
      "skills": skills,

      //Must be in another table
      "address": taskerAddress,
      "availability": availability,

      // MUST in another table
      "tesda_documents_id": taskerDocuments,
      "social_media_links": socialMediaLinks ?? {},
      "gender": gender,

      // remove kasi nasa user na siya
      "contact_number": phoneNumber,
      "group": group,
      "wage_per_hour": wage,
      "pay_period": payPeriod,
      "birthdate": birthDate.toIso8601String(),
      "user": user?.toJson(),
    };
  }
}
