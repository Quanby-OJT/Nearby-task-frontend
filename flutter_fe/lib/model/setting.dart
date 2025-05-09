import 'dart:convert';
import 'package:flutter/material.dart';

class SettingModel {
  final int? id;
  final int? taskerId;
  final double? distance;
  final RangeValues? ageRange;
  final bool? limit;
  final List<String>? specialization;
  final String? createdAt;
  final String? updatedAt;

  final String? city;
  final String? province;
  final String? postalCode;
  final String? country;
  final String? street;
  final bool? defaultAddress;
  final double? latitude;
  final double? longitude;

  SettingModel({
    this.id,
    this.taskerId,
    this.latitude,
    this.longitude,
    this.distance,
    this.ageRange,
    this.limit,
    this.specialization,
    this.createdAt,
    this.updatedAt,
    this.city,
    this.province,
    this.postalCode,
    this.country,
    this.street,
    this.defaultAddress,
  });

  factory SettingModel.fromJson(Map<String, dynamic> json) {
    List<String>? specializationList;
    if (json['specialization'] != null && json['specialization'] is String) {
      String specString = json['specialization'].toString();
      try {
        specString = specString.replaceAll("'", '"');
        specializationList = List<String>.from(jsonDecode(specString));
      } catch (e) {
        specializationList = specString
            .replaceAll('{', '')
            .replaceAll('}', '')
            .split(',')
            .map((s) => s.trim())
            .toList();
      }
    } else if (json['specialization'] is List) {
      specializationList = List<String>.from(json['specialization']);
    }

    double? distanceValue;
    if (json['distance'] != null) {
      if (json['distance'] is int) {
        distanceValue = (json['distance'] as int).toDouble();
      } else if (json['distance'] is double) {
        distanceValue = json['distance'];
      } else {
        distanceValue = double.tryParse(json['distance'].toString());
      }
    }

    RangeValues? ageRangeValues;
    if (json['age_start'] != null && json['age_end'] != null) {
      double? ageStart = json['age_start'] is int
          ? (json['age_start'] as int).toDouble()
          : (json['age_start'] is double
              ? json['age_start']
              : double.tryParse(json['age_start'].toString()));

      double? ageEnd = json['age_end'] is int
          ? (json['age_end'] as int).toDouble()
          : (json['age_end'] is double
              ? json['age_end']
              : double.tryParse(json['age_end'].toString()));

      if (ageStart != null && ageEnd != null) {
        ageRangeValues = RangeValues(ageStart, ageEnd);
      }
    }

    final address = json['address'] as Map<String, dynamic>?;

    return SettingModel(
      id: json['id'] is int ? json['id'] : null,
      taskerId: json['user_id'] is int ? json['user_id'] : null,
      distance: distanceValue,
      ageRange: ageRangeValues ?? RangeValues(18, 24),
      limit: json['limit'] is bool ? json['limit'] : null,
      specialization: specializationList,
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      city: address?['city']?.toString(),
      province: address?['province']?.toString(),
      postalCode: address?['postal_code']?.toString(),
      country: address?['country']?.toString(),
      street: address?['street']?.toString(),
      defaultAddress: address != null && address['default'] is bool
          ? address['default']
          : false,
      latitude: address != null && address['latitude'] != null
          ? double.tryParse(address['latitude'].toString())
          : null,
      longitude: address != null && address['longitude'] != null
          ? double.tryParse(address['longitude'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': taskerId,
      'distance': distance,
      'age_start': ageRange?.start,
      'age_end': ageRange?.end,
      'limit': limit,
      'specialization': specialization?.toString(),
      'created_at': createdAt,
      'updated_at': updatedAt,
      'address': {
        'latitude': latitude,
        'longitude': longitude,
        'city': city,
        'province': province,
        'postal_code': postalCode,
        'country': country,
        'street': street,
        'default': defaultAddress,
      },
    };
  }
}
