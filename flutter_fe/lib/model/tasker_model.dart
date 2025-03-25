import 'package:flutter/cupertino.dart';
import 'package:flutter_fe/model/user_model.dart';

class TaskerModel {
  final int id;
  final String bio;
  final String specialization;
  final String skills;
  final bool availability;
  final String? taskerDocuments;
  final List<String>? socialMediaLinks;
  final String taskerAddress;
  final double wage;
  final String payPeriod;
  final DateTime birthDate;
  final String phoneNumber;
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
    return "user: $user)";
  }

  //Factory to manage tasker data.
  factory TaskerModel.fromJson(Map<String, dynamic> json) {
    debugPrint("Received JSON: $json");
    return TaskerModel(
      id: json['tasker']['tasker_id'] ?? 0,
      bio: json['tasker']['bio'] ?? '',
      skills: json['tasker']['skills'] ?? '',
      availability: json['tasker']['availability'] ?? false,
      socialMediaLinks: (json['tasker']['social_media_links'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      taskerAddress: json['tasker']['address'] ?? '',
      specialization: json['tasker']['tasker_specialization'] != null
          ? json['tasker']['tasker_specialization']['specialization']
          : '',
      taskerDocuments: json['tesda_document_link'] ?? '', // Fixed line
      wage: json['tasker']['wage_per_hour'] != null ? json['tasker']['wage_per_hour'].toDouble() : 0.0,
      payPeriod: json['tasker']['pay_period'] ?? "",
      birthDate: json['tasker']['birthdate'] != null
          ? DateTime.parse(json['tasker']['birthdate'])
          : DateTime.now(),
      phoneNumber: json['tasker']['phone_number'] ?? '',
      group: json['tasker']['group'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "tasker_id": id,
      "bio": bio,
      "specialization": specialization,
      "skills": skills,
      "address": taskerAddress,
      "availability": availability,
      "tesda_documents_link": taskerDocuments,
      "social_media_links": socialMediaLinks,
      "contact_number": phoneNumber,
      "group": group,
      "wage_per_hour": wage,
      "pay_period": payPeriod,
      "birth_date": birthDate.toIso8601String(),
    };
  }
}
