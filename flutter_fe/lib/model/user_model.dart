import 'package:flutter/cupertino.dart';
import 'package:flutter_fe/model/user_preference.dart';
import 'dart:convert';

class UserModel {
  final int? id;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String email;
  final String? birthdate;
  final String? password;
  final dynamic image;
  final String? imageName;
  final String role;
  final String? accStatus;
  final String? contact;
  final String? gender;
  final bool? verified;
  final List<UserPreferenceModel>? userPreferences;
  final String? bio;
  final Map<String, String>? socialMediaLinks;
  final String? fcmToken;

  UserModel({
    this.id,
    required this.firstName,
    this.middleName,
    required this.lastName,
    required this.email,
    this.password,
    this.image,
    this.imageName,
    required this.role,
    this.birthdate,
    this.accStatus,
    this.contact,
    this.gender,
    this.verified,
    this.userPreferences,
    this.bio,
    this.socialMediaLinks,
    this.fcmToken,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    debugPrint("User Data: $json");

    // Parse social media links if available
    Map<String, String>? socialLinks;
    if (json['social_media_links'] != null) {
      if (json['social_media_links'] is Map) {
        socialLinks = Map<String, String>.from(json['social_media_links']);
      } else if (json['social_media_links'] is String) {
        try {
          final dynamic decoded =
              jsonDecode(json['social_media_links'] as String);
          if (decoded is Map) {
            socialLinks = Map<String, String>.from(decoded);
          }
        } catch (e) {
          debugPrint("Error parsing social media links: $e");
        }
      }
    }

    return UserModel(
      id: int.tryParse(json['user_id'].toString()) ?? 0,
      firstName: json['first_name'] ?? '',
      middleName: json['middle_name'] ?? '',
      lastName: json['last_name'] ?? '',
      birthdate: json['birthdate'] as String?,
      email: json['email'] ?? '',
      password: json['hashed_password'] as String?,
      image: json['image_link'] ?? '',
      imageName: json['image_link'] as String?,
      role: json['user_role'] ?? '',
      accStatus: json['acc_status'] ?? '',
      contact: json['contact'] ?? '',
      gender: json['gender'] ?? '',
      verified: json['verified'] as bool?,
      userPreferences: json['user_preference'] != null
          ? (json['user_preference'] as List<dynamic>)
              .map((pref) => UserPreferenceModel.fromJson(pref))
              .toList()
          : null,
      bio: json['bio'] as String?,
      socialMediaLinks: socialLinks,
      fcmToken: json['fcm_token'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "user_id": id,
      "first_name": firstName,
      "middle_name": middleName,
      "last_name": lastName,
      "email": email,
      "password": password,
      "user_role": role,
      "acc_status": accStatus,
      "contact": contact,
      "gender": gender,
      "birthdate": birthdate,
      "image_link": imageName,
      "verified": verified,
      "user_preference": userPreferences?.map((pref) => pref.toJson()).toList(),
      "bio": bio,
      "social_media_links": socialMediaLinks,
      "fcm_token": fcmToken,
    };
  }

  @override
  String toString() {
    return 'UserModel(firstName: $firstName, middleName: $middleName, lastName: $lastName, email: $email, password: ${password != null ? "****" : "null"}, role: $role, accStatus: $accStatus, contact: $contact, gender: $gender, birthdate: $birthdate, image: $image, imageName: $imageName, verified: $verified, userPreferences: $userPreferences, bio: $bio, socialMediaLinks: $socialMediaLinks)';
  }

  // Add a copyWith method to create a new instance with modified properties
  UserModel copyWith({
    int? id,
    String? firstName,
    String? middleName,
    String? lastName,
    String? email,
    String? birthdate,
    String? password,
    dynamic image,
    String? imageName,
    String? role,
    String? accStatus,
    String? contact,
    String? gender,
    bool? verified,
    List<UserPreferenceModel>? userPreferences,
    String? bio,
    Map<String, String>? socialMediaLinks,
  }) {
    return UserModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      birthdate: birthdate ?? this.birthdate,
      password: password ?? this.password,
      image: image ?? this.image,
      imageName: imageName ?? this.imageName,
      role: role ?? this.role,
      accStatus: accStatus ?? this.accStatus,
      contact: contact ?? this.contact,
      gender: gender ?? this.gender,
      verified: verified ?? this.verified,
      userPreferences: userPreferences ?? this.userPreferences,
      bio: bio ?? this.bio,
      socialMediaLinks: socialMediaLinks ?? this.socialMediaLinks,
      fcmToken: fcmToken ?? fcmToken,
    );
  }
}
