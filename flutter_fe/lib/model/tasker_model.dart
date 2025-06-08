import 'package:flutter/cupertino.dart';
import 'package:flutter_fe/model/specialization.dart';
import 'package:flutter_fe/model/user_model.dart';
import 'dart:convert';

class TaskerModel {
  final int id;
  final String bio;
  final SpecializationModel specialization;
  final String skills;
  final bool availability;
  final String? taskerDocuments;
  final Map<String, String>? socialMediaLinks;
  final Map<String, String>? address;
  final double wage;
  final String payPeriod;
  final DateTime birthDate;
  final bool group;
  final double rating;
  final List<String>? taskerImages; //For Displaying of Images only/
  UserModel? user;

  TaskerModel({
    required this.id,
    required this.bio,
    required this.group,
    required this.specialization,
    required this.skills,
    required this.availability,
    this.address,
    required this.wage,
    required this.payPeriod,
    required this.birthDate,
    this.taskerDocuments,
    this.socialMediaLinks,
    this.taskerImages,
    this.user,
    required this.rating,
  });

  @override
  String toString() {
    return "Tasker(id: $id, bio: $bio, specialization: $specialization, user: $user)";
  }

  // Add a copyWith method to create a new instance with some properties changed
  TaskerModel copyWith({
    int? id,
    String? bio,
    bool? group,
    String? specialization,
    String? skills,
    bool? availability,
    Map<String, String>? address,
    double? wage,
    String? payPeriod,
    DateTime? birthDate,
    String? taskerDocuments,
    Map<String, String>? socialMediaLinks,
    UserModel? user,
    double? rating,
  }) {
    return TaskerModel(
      id: id ?? this.id,
      bio: bio ?? this.bio,
      group: group ?? this.group,
      specialization: SpecializationModel(specialization: this.specialization.toString()),
      skills: skills ?? this.skills,
      availability: availability ?? this.availability,
      address: address ?? this.address,
      wage: wage ?? this.wage,
      payPeriod: payPeriod ?? this.payPeriod,
      birthDate: birthDate ?? this.birthDate,
      taskerDocuments: taskerDocuments ?? this.taskerDocuments,
      socialMediaLinks: socialMediaLinks ?? this.socialMediaLinks,
      user: user ?? this.user,
      rating: rating ?? this.rating,
    );
  }

  // Factory method to map JSON to TaskerModel
  factory TaskerModel.fromJson(Map<String, dynamic> json) {
    debugPrint('JSON Data: $json');

    // Helper function to parse social media links
    Map<String, String>? parseSocialMediaLinks(dynamic socialMediaData) {
      if (socialMediaData == null) return null;

      try {
        if (socialMediaData is String) {
          // If it's a string, try to parse it as JSON
          if (socialMediaData.isEmpty || socialMediaData == '{}') {
            return <String, String>{};
          }
          final parsed = jsonDecode(socialMediaData);
          return Map<String, String>.from(parsed);
        } else if (socialMediaData is Map) {
          // If it's already a Map, convert it
          return Map<String, String>.from(socialMediaData);
        }
      } catch (e) {
        debugPrint('Error parsing social media links: $e');
      }

      return <String, String>{};
    }

    return TaskerModel(
      id: json['tasker_id'] ?? json['user']?['user_id'] ?? 0,
      bio: json['bio'] ?? '',
      skills: json['skills'] ?? 'N/A',
      availability: json['availability'] ?? false,
      socialMediaLinks: parseSocialMediaLinks(json['social_media_links']),
      address: json['address'] != null
          ? Map<String, String>.from(json['address'])
          : null,
      // Safely handle tasker_specialization
      specialization: SpecializationModel.fromJson(json['tasker_specialization']),
      taskerDocuments: json['tesda_document_link'] ?? '',
      wage: (json['wage_per_hour'] as num?)?.toDouble() ?? 0.0,
      payPeriod: json['pay_period'] ?? '',
      birthDate: json['birthdate'] != null
          ? DateTime.parse(json['birthdate'])
          : DateTime.now(),
      group: json['group'] ?? false,
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      taskerImages: json['tasker_images'] != null
          ? List<String>.from(json['profile_images'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "bio": bio,
      "specialization": specialization,
      "skills": skills,

      //Must be in another table
      "availability": availability,
      "social_media_links": socialMediaLinks ?? {},
      "address": address ?? {},

      /// remove kasi nasa user na siya
      ///
      /// Ces: Hindi. Ibabalik siya dito.
      "group": group,
      "wage": wage,
      "pay_period": payPeriod,
      "user": user?.toJson(),
    };
  }
}
