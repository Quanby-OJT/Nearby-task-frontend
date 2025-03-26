import 'package:flutter/cupertino.dart';
import 'package:flutter_fe/model/user_model.dart';

class TaskerModel {
  final int id;
  final String bio;
  final String specialization;
  final String skills;
  final bool availability;
  final String? taskerDocuments;
  final Map<String, String>? socialMediaLinks;
  final String taskerAddress;
  final double wage;
  final String payPeriod;
  final DateTime birthDate;
  final int phoneNumber;
  final bool? group;
  UserModel? user;

  TaskerModel({
    required this.id,
    required this.bio,
    this.group,
    required this.specialization,
    required this.skills,
    required this.taskerAddress,
    required this.availability,
    required this.wage,
    required this.payPeriod,
    required this.birthDate,
    required this.phoneNumber,
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
    debugPrint('JSON Data: $json');
    return TaskerModel(
      id: json['tasker']['tasker_id'] ?? 0,
      bio: json['tasker']['bio'] ?? '',
      skills: json['tasker']['skills'] ?? '',
      phoneNumber: json['tasker']['contact_number'] ?? '',
      availability: json['tasker']['availability'] ?? false,
      socialMediaLinks: (json['tasker']['social_media_links'] as Map<String, dynamic>)
          .map((key, value) => MapEntry(key, value as String)),
      taskerAddress: json['tasker']['address'] ?? '',
      specialization: json['tasker']['tasker_specialization']['specialization'] ?? '',
      taskerDocuments: json['tesda_document_link'] ?? '',
      wage: json['tasker']['wage_per_hour'].toDouble() ?? 0.0,
      payPeriod: json['tasker']['pay_period'] ?? "",
      birthDate: json['tasker']['birthdate'] != null
          ? DateTime.parse(json['tasker']['birthdate'])
          : DateTime.now(),
      group: json['tasker']['group'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "tasker_id": id,
      "bio": bio,
      "specialization": specialization,
      "skills": skills,

      //Must be in another table
      "address": taskerAddress,
      "availability": availability,
      "tesda_documents_link": taskerDocuments,
      "social_media_links": socialMediaLinks,

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
