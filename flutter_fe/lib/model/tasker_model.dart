import 'package:flutter_fe/model/user_model.dart';

class TaskerModel {
  final int? id;
  final String bio;
  final String specialization;
  final String skills;
  final bool availability;
  final String? taskerDocuments;
  final String? socialMediaLinks;
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
    return "user: $user)";
  }

  //Factory to manage tasker data.
  factory TaskerModel.fromJson(Map<String, dynamic> json) {
    return TaskerModel(
      id: json["id"] ?? '',
      bio: json['bio'] ?? '',
      skills: json['skills'] ?? '',
      availability: json['availability'] ?? false,
      socialMediaLinks: json['social_media_links'] ?? '',
      taskerAddress: json['address'] ?? '',
      specialization: json['tasker_specialization'] != null
          ? json['tasker_specialization']['specialization']
          : '',
      taskerDocuments: json['tasker_documents'] ?? '',
      wage: json['wage'] != null ? json['wage_per_hour'].toDouble() : 0.0,
      payPeriod: json['pay_period'] ?? "",
      birthDate: json['birth_date'] != null
          ? DateTime.parse(json['birth_date'])
          : DateTime.now(),
      phoneNumber: json['phone_number'] ?? '',
      gender: json['gender'] ?? '',
      group: json['group'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "bio": bio,
      "specialization": specialization,
      "skills": skills,
      "address": taskerAddress,
      "availability": availability,
      "tesda_documents_link": taskerDocuments,
      "social_media_links": socialMediaLinks,
      "gender": gender,
      "contact_number": phoneNumber,
      "group": group,
      "wage_per_hour": wage,
      "pay_period": payPeriod,
      "birth_date": birthDate.toIso8601String(),
    };
  }
}
