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
      id: json['tasker_id'] ?? 0,
      bio: json['bio'] ?? '',
      skills: json['skills'] ?? '',
      phoneNumber: json['contact_number'] ?? '',
      availability: json['availability'] ?? false,
e
      socialMediaLinks: (json['social_media_links'] as Map<String, dynamic>)
          .map((key, value) => MapEntry(key, value as String)),

   //   socialMediaLinks: json['social_media_links'] != null
   //       ? Map<String, String>.from(json['social_media_links'])
   //       : null,

      taskerAddress: json['address'] ?? '',
      specialization: json['tasker_specialization']['specialization'] ?? '',
      taskerDocuments: json['tesda_document_link'] ?? '',
      wage: json['wage_per_hour'].toDouble() ?? 0.0,
      payPeriod: json['pay_period'] ?? "",
      birthDate: json['birthdate'] != null
          ? DateTime.parse(json['birthdate'])
          : DateTime.now(),
      group: json['group'] ?? false,
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
    //  "social_media_links": socialMediaLinks,


      // MUST in another table
     // "tesda_documents_id": taskerDocuments,
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
