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
  final String? clientDocumentUrl;
  final String? clientDocumentType;
  final bool? documentValid;
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
    this.specialization,
    this.specializationId,
    this.payPeriod = 'Hourly',
    this.wage,
    this.socialMediaJson = '{}',
    this.idType,
    this.idImageUrl,
    this.selfieImageUrl,
    this.documentUrl,
    this.clientDocumentUrl,
    this.clientDocumentType,
    this.documentValid,
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
      return jsonDecode(addressJson) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error parsing address JSON: $e');
      return {};
    }
  }

  // Parse social media JSON to Map
  Map<String, dynamic> get socialMediaLinks {
    try {
      return jsonDecode(socialMediaJson) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error parsing social media JSON: $e');
      return {};
    }
  }

  // Get formatted full address
  String get fullAddress {
    final addr = address;
    final List<String> parts = [];

    if (addr['street']?.toString().isNotEmpty ?? false) {
      parts.add(addr['street']);
    }
    if (addr['barangay']?.toString().isNotEmpty ?? false) {
      parts.add('Barangay ${addr['barangay']}');
    }
    if (addr['city']?.toString().isNotEmpty ?? false) {
      parts.add(addr['city']);
    }
    if (addr['province']?.toString().isNotEmpty ?? false) {
      parts.add(addr['province']);
    }
    if (addr['region']?.toString().isNotEmpty ?? false) {
      parts.add(addr['region']);
    }
    if (addr['postalCode']?.toString().isNotEmpty ?? false) {
      parts.add(addr['postalCode']);
    }

    parts.add('Philippines');

    return parts.join(', ');
  }

  // Factory constructor from JSON
  factory VerificationModel.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'] as Map<String, dynamic>? ?? {};
    final idImageJson = json['idImage'] as Map<String, dynamic>? ?? {};
    final faceImageJson = json['faceImage'] as Map<String, dynamic>? ?? {};
    final userDocumentsJson =
        json['userDocuments'] as Map<String, dynamic>? ?? {};

    return VerificationModel(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      userId: int.tryParse(userJson['id']?.toString() ??
              json['user_id']?.toString() ??
              '0') ??
          0,
      firstName: userJson['first_name']?.toString() ?? '',
      middleName: userJson['middle_name']?.toString(),
      lastName: userJson['last_name']?.toString() ?? '',
      email: userJson['email']?.toString() ?? '',
      phone: userJson['contact']?.toString(),
      gender: userJson['gender']?.toString(),
      birthdate: userJson['birthdate']?.toString(),
      addressJson: userJson['address_json']?.toString() ?? '{}',
      specialization: userJson['specialization']?.toString(),
      specializationId: userJson['specialization_id'] != null
          ? int.tryParse(userJson['specialization_id'].toString())
          : null,
      payPeriod: userJson['pay_period']?.toString() ?? 'Hourly',
      wage: userJson['wage'] != null
          ? double.tryParse(userJson['wage'].toString())
          : null,
      socialMediaJson: userJson['social_media_json']?.toString() ?? '{}',
      idType: idImageJson['id_type']?.toString(),
      idImageUrl: idImageJson['id_image']?.toString(),
      selfieImageUrl: faceImageJson['face_image']?.toString(),
      documentUrl: userDocumentsJson['user_document_link']?.toString(),
      clientDocumentUrl: userDocumentsJson['user_document_link']?.toString(),
      clientDocumentType: userDocumentsJson['document_type']?.toString(),
      documentValid: idImageJson['valid'] as bool?,
      status: userJson['acc_status']?.toString() ?? 'Pending',
      verificationDate: userJson['verification_date']?.toString(),
      verifiedBy: userJson['verified_by']?.toString(),
      verifiedDate: userJson['verified_date']?.toString(),
      rejectionReason: userJson['rejection_reason']?.toString(),
      bio: userJson['bio']?.toString(),
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'user': {
        'id': userId,
        'first_name': firstName,
        'middle_name': middleName,
        'last_name': lastName,
        'email': email,
        'contact': phone,
        'gender': gender,
        'birthdate': birthdate,
        'address_json': addressJson,
        'specialization': specialization,
        'specialization_id': specializationId,
        'pay_period': payPeriod,
        'wage': wage,
        'social_media_json': socialMediaJson,
        'acc_status': status,
        'verification_date': verificationDate,
        'verified_by': verifiedBy,
        'verified_date': verifiedDate,
        'rejection_reason': rejectionReason,
        'bio': bio,
      },
      'idImage': {
        'id_type': idType,
        'id_image': idImageUrl,
        'valid': documentValid,
      },
      'faceImage': {
        'face_image': selfieImageUrl,
      },
      'userDocuments': {
        'user_document_link': documentUrl,
        'document_type': clientDocumentType,
      },
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
    String? clientDocumentUrl,
    String? clientDocumentType,
    bool? documentValid,
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
      clientDocumentUrl: clientDocumentUrl ?? this.clientDocumentUrl,
      clientDocumentType: clientDocumentType ?? this.clientDocumentType,
      documentValid: documentValid ?? this.documentValid,
      status: status ?? this.status,
      verificationDate: verificationDate ?? this.verificationDate,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      verifiedDate: verifiedDate ?? this.verifiedDate,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      bio: bio ?? this.bio,
    );
  }
}
