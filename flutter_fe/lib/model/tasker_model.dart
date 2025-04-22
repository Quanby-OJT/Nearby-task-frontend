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
  final Map<String, String>? address;
  final double wage;
  final String payPeriod;
  final DateTime birthDate;
  final bool? group;
  final double rating;
  UserModel? user;

  TaskerModel({
    required this.id,
    required this.bio,
    this.group,
    required this.specialization,
    required this.skills,
    required this.availability,
    this.address,
    required this.wage,
    required this.payPeriod,
    required this.birthDate,
    this.taskerDocuments,
    this.socialMediaLinks,
    this.user,
    required this.rating,
  });

  @override
  String toString() {
    return "Tasker(id: $id, bio: $bio, specialization: $specialization, user: $user)";
  }

  // Factory method to map JSON to TaskerModel
  factory TaskerModel.fromJson(Map<String, dynamic> json) {
    debugPrint('JSON Data: $json');
    try {
      return TaskerModel(
          id: json['tasker_id'] ?? 0,
          bio: json['bio'] ?? '',
          skills: json['skills'] ?? '',
          availability: json['availability'] ?? false,
          socialMediaLinks: json['social_media_links'] != null
              ? Map<String, String>.from(json['social_media_links'])
              : null,
          address: json['address'] != null
              ? Map<String, String>.from(json['address'])
              : null,
          specialization: json['tasker_specialization'] != null &&
                  json['tasker_specialization'] is Map
              ? json['tasker_specialization']['specialization'] ?? ''
              : json['specialization'] ?? '',
          taskerDocuments: json['tesda_document_link'] ?? '',
          wage: (json['wage_per_hour'] ?? 0).toDouble(),
          payPeriod: json['pay_period'] ?? "",
          birthDate: json['birthdate'] != null
              ? DateTime.parse(json['birthdate'])
              : DateTime.now(),
          group: json['group'] ?? false,
          user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
          rating: (json['rating'] ?? 0).toDouble());
    } catch (e) {
      debugPrint("Error parsing tasker: $e");
      debugPrint("Problematic tasker data: $json");
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      "tasker_id": id,
      "bio": bio,
      "specialization": specialization,
      "skills": skills,

      //Must be in another table
      "availability": availability,
      "tesda_documents_link": taskerDocuments,
      "social_media_links": socialMediaLinks ?? {},
      "address": address ?? {},

      // remove kasi nasa user na siya
      "group": group,
      "wage_per_hour": wage,
      "pay_period": payPeriod,
      "user": user?.toJson(),
    };
  }
}
