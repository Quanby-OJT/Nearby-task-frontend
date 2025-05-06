import 'package:flutter/cupertino.dart';
import 'package:flutter_fe/model/user_preference.dart';

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
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    debugPrint("User Data: $json");
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "user_id": id,
      "first_name": firstName,
      "middle_name": middleName,
      "last_name": lastName,
      "email": email,
      "hashed_password": password,
      "user_role": role,
      "acc_status": accStatus,
      "contact": contact,
      "gender": gender,
      "birthdate": birthdate,
      "image_link": imageName,
      "verified": verified,
      "user_preference": userPreferences?.map((pref) => pref.toJson()).toList(),
    };
  }

  @override
  String toString() {
    return 'UserModel(firstName: $firstName, middleName: $middleName, lastName: $lastName, email: $email, password: ${password != null ? "****" : "null"}, role: $role, accStatus: $accStatus, contact: $contact, gender: $gender, birthdate: $birthdate, image: $image, imageName: $imageName, verified: $verified, userPreferences: $userPreferences)';
  }
}
