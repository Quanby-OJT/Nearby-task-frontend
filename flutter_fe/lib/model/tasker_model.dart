import 'package:flutter_fe/model/user_model.dart';

class TaskerModel{
  final String bio;
  final String specialization;
  final String skills;
  final bool? availability;
  final String? taskerDocuments;
  final String? socialMediaLinks;
  final String taskerAddress;
  UserModel? user;

  TaskerModel({
    required this.bio,
    required this.specialization,
    required this.skills,
    required this.taskerAddress,
    this.availability,
    this.taskerDocuments,
    this.socialMediaLinks,
    this.user
  });

  @override
  String toString() {
    return "user: $user)";
  }

  //Factory to manage tasker data.
  factory TaskerModel.fromJson(Map<String, dynamic> json) {
    return TaskerModel(
      bio: json['bio'] ?? '',
      skills: json['skills'] ?? '',
      availability: json['availability'] ?? false,
      socialMediaLinks: json['social_media_links'] ?? '',
      taskerAddress: json['address'] ?? '',
      specialization: json['tasker_specialization'] != null
          ? json['tasker_specialization']['specialization']
          : '',
      taskerDocuments: json['tasker_documents'] ?? '',
    );
  }


  Map<String, dynamic> toJson() {
    return {
      "bio": bio,
      "specialization": specialization,
      "skills": skills,
      "address": taskerAddress,
      "availability": availability,
      "tesda_documents_link": taskerDocuments,
      "social_media_links": socialMediaLinks
    };
  }
}