import 'dart:convert';
import 'package:flutter/material.dart';

class VerificationModel {
  final int? id;
  final int userId;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String email;
  final String? phone;
  final String? gender;
  final String? birthdate;
  final String addressJson;
  final String? specialization;
  final int? specializationId;
  final String payPeriod;
  final double? wage;
  final String socialMediaJson;
  final String? idType;
  final String? idImageUrl;
  final String? selfieImageUrl;
  final String? documentUrl;
  final String status;
  final String? verificationDate;
  final String? verifiedBy;
  final String? verifiedDate;
  final String? rejectionReason;
  final String? bio;

  VerificationModel({
    this.id,
    required this.userId,
    required this.firstName,
    this.middleName,
    required this.lastName,
    required this.email,
    this.phone,
    this.gender,
    this.birthdate,
    this.addressJson = '{}',
    this.specialization = '',
    this.specializationId,
    this.payPeriod = 'Hourly',
    this.wage = 0.0,
    required this.socialMediaJson,
    this.idType,
    this.idImageUrl,
    this.selfieImageUrl,
    this.documentUrl,
    required this.status,
    this.verificationDate,
    this.verifiedBy,
    this.verifiedDate,
    this.rejectionReason,
    this.bio,
  });

  // Parse address JSON to Map
  Map<String, dynamic> get address {
    try {
      return jsonDecode(addressJson);
    } catch (e) {
      debugPrint('Error parsing address JSON: $e');
      return {};
    }
  }

  // Parse social media JSON to Map
  Map<String, dynamic> get socialMediaLinks {
    try {
      return jsonDecode(socialMediaJson);
    } catch (e) {
      debugPrint('Error parsing social media JSON: $e');
      return {};
    }
  }

  // Get formatted full address
  String get fullAddress {
    final addr = address;
    final List<String> parts = [];

    if (addr['street'] != null && addr['street'].toString().isNotEmpty) {
      parts.add(addr['street']);
    }
    if (addr['barangay'] != null && addr['barangay'].toString().isNotEmpty) {
      parts.add('Barangay ${addr['barangay']}');
    }
    if (addr['city'] != null && addr['city'].toString().isNotEmpty) {
      parts.add(addr['city']);
    }
    if (addr['province'] != null && addr['province'].toString().isNotEmpty) {
      parts.add(addr['province']);
    }
    if (addr['region'] != null && addr['region'].toString().isNotEmpty) {
      parts.add(addr['region']);
    }
    if (addr['postalCode'] != null &&
        addr['postalCode'].toString().isNotEmpty) {
      parts.add(addr['postalCode']);
    }

    parts.add('Philippines');

    return parts.join(', ');
  }

  // Factory constructor from JSON
  factory VerificationModel.fromJson(Map<String, dynamic> json) {
    return VerificationModel(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      userId: int.tryParse(json['user_id'].toString()) ?? 0,
      firstName: json['first_name'] ?? '',
      middleName: json['middle_name'],
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      gender: json['gender'],
      birthdate: json['birthdate'],
      addressJson: json['address_json'] ?? '{}',
      specialization: json['specialization'],
      specializationId: json['specialization_id'] != null
          ? int.tryParse(json['specialization_id'].toString())
          : null,
      payPeriod: json['pay_period'] ?? 'Hourly',
      wage: json['wage'] != null
          ? double.tryParse(json['wage'].toString())
          : null,
      socialMediaJson: json['social_media_json'] ?? '{}',
      idType: json['id_type'],
      idImageUrl:
          json['idImageUrl'] ?? json['id_image_url'] ?? json['id_image'],
      selfieImageUrl: json['selfieImageUrl'] ??
          json['selfie_image_url'] ??
          json['face_image'],
      documentUrl: json['documentUrl'] ??
          json['document_url'] ??
          json['user_document_link'],
      status: json['status'] ?? 'pending',
      verificationDate: json['verification_date'],
      verifiedBy: json['verified_by'],
      verifiedDate: json['verified_date'],
      rejectionReason: json['rejection_reason'],
      bio: json['bio'],
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'first_name': firstName,
      'middle_name': middleName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'gender': gender,
      'birthdate': birthdate,
      'address_json': addressJson,
      'specialization': specialization,
      'specialization_id': specializationId,
      'pay_period': payPeriod,
      'wage': wage,
      'social_media_json': socialMediaJson,
      'id_type': idType,
      'id_image_url': idImageUrl,
      'selfie_image_url': selfieImageUrl,
      'document_url': documentUrl,
      'status': status,
      'verification_date': verificationDate,
      'verified_by': verifiedBy,
      'verified_date': verifiedDate,
      'rejection_reason': rejectionReason,
      'bio': bio,
    };
  }

  // Create a copy with updated fields
  VerificationModel copyWith({
    int? id,
    int? userId,
    String? firstName,
    String? middleName,
    String? lastName,
    String? email,
    String? phone,
    String? gender,
    String? birthdate,
    String? addressJson,
    String? specialization,
    int? specializationId,
    String? payPeriod,
    double? wage,
    String? socialMediaJson,
    String? idType,
    String? idImageUrl,
    String? selfieImageUrl,
    String? documentUrl,
    String? status,
    String? verificationDate,
    String? verifiedBy,
    String? verifiedDate,
    String? rejectionReason,
    String? bio,
  }) {
    return VerificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      gender: gender ?? this.gender,
      birthdate: birthdate ?? this.birthdate,
      addressJson: addressJson ?? this.addressJson,
      specialization: specialization ?? this.specialization,
      specializationId: specializationId ?? this.specializationId,
      payPeriod: payPeriod ?? this.payPeriod,
      wage: wage ?? this.wage,
      socialMediaJson: socialMediaJson ?? this.socialMediaJson,
      idType: idType ?? this.idType,
      idImageUrl: idImageUrl ?? this.idImageUrl,
      selfieImageUrl: selfieImageUrl ?? this.selfieImageUrl,
      documentUrl: documentUrl ?? this.documentUrl,
      status: status ?? this.status,
      verificationDate: verificationDate ?? this.verificationDate,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      verifiedDate: verifiedDate ?? this.verifiedDate,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      bio: bio ?? this.bio,
    );
  }
}
