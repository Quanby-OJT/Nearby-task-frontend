import 'package:flutter_fe/model/address.dart';

class UserPreferenceModel {
  final int id;
  final bool limit;
  final AddressModel address;
  final int ageEnd;
  final int userId;
  final double distance;
  final double latitude;
  final int ageStart;
  final double longitude;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String userAddress;
  final List<String> specialization;

  UserPreferenceModel({
    required this.id,
    required this.limit,
    required this.address,
    required this.ageEnd,
    required this.userId,
    required this.distance,
    required this.latitude,
    required this.ageStart,
    required this.longitude,
    required this.createdAt,
    required this.updatedAt,
    required this.userAddress,
    required this.specialization,
  });

  factory UserPreferenceModel.fromJson(Map<String, dynamic> json) {
    // Handle specialization as either a list, string (e.g., "{0}"), or null
    List<String> parseSpecialization(dynamic spec) {
      if (spec == null) return [];
      if (spec is List) return List<String>.from(spec);
      if (spec is String) {
        // Handle specific case of "{0}" or similar string formats
        if (spec.startsWith('{') && spec.endsWith('}')) {
          // Remove curly braces and treat content as a single item
          final content = spec.substring(1, spec.length - 1);
          return content.isNotEmpty ? [content] : [];
        }
        // Fallback: treat string as a single item
        return [spec];
      }
      return [];
    }

    return UserPreferenceModel(
      id: json['id'] ?? 0,
      limit: json['limit'] ?? false,
      address: json['address'] != null
          ? AddressModel.fromJson(json['address'])
          : AddressModel(
              streetAddress: '',
              city: '',
              province: '',
              postalCode: '',
              country: '',
            ),
      ageEnd: json['age_end'] ?? 0,
      userId: json['user_id'] ?? 0,
      distance: (json['distance'] ?? 0).toDouble(),
      latitude: (json['latitude'] ?? 0).toDouble(),
      ageStart: json['age_start'] ?? 0,
      longitude: (json['longitude'] ?? 0).toDouble(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      userAddress: json['user_address'] ?? '',
      specialization: parseSpecialization(json['specialization']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'limit': limit,
      'address': address.toJson(),
      'age_end': ageEnd,
      'user_id': userId,
      'distance': distance,
      'latitude': latitude,
      'age_start': ageStart,
      'longitude': longitude,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'user_address': userAddress,
      'specialization': specialization,
      'age_range': {'start': ageStart, 'end': ageEnd},
    };
  }

  @override
  String toString() {
    return 'UserPreferenceModel(id: $id, limit: $limit, address: $address, ageEnd: $ageEnd, userId: $userId, distance: $distance, latitude: $latitude, ageStart: $ageStart, longitude: $longitude, userAddress: $userAddress, specialization: $specialization, ageRange: {"start": $ageStart, "end": $ageEnd})';
  }
}
