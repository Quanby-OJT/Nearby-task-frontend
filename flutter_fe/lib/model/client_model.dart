import 'package:flutter_fe/model/user_model.dart';
import 'dart:convert';

class ClientModel {
  final int? clientId;
  final int? userId;
  final String? preferences;
  final String? clientAddress;
  final String? bio;
  final Map<String, String>? socialMediaLinks;
  final double? amount;
  final double? rating;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final UserModel? user;

  // Getter for backward compatibility
  int? get id => clientId;

  ClientModel({
    this.clientId,
    this.userId,
    this.preferences,
    this.clientAddress,
    this.bio,
    this.socialMediaLinks,
    this.user,
    this.amount,
    this.rating,
    this.createdAt,
    this.updatedAt,
  });

  @override
  String toString() {
    return "ClientModel(clientId: $clientId, userId: $userId, preferences: $preferences, clientAddress: $clientAddress, bio: $bio, user: $user)";
  }

  Map<String, dynamic> toJson() {
    return {
      "client_id": clientId,
      "user_id": userId,
      "preferences": preferences,
      "client_address": clientAddress,
      "bio": bio,
      "social_media_links":
          socialMediaLinks != null ? jsonEncode(socialMediaLinks) : '{}',
      "amount": amount,
      "rating": rating,
      "created_at": createdAt?.toIso8601String(),
      "updated_at": updatedAt?.toIso8601String(),
      "user": user?.toJson(),
    };
  }

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    Map<String, String>? socialLinks;
    if (json['social_media_links'] != null) {
      try {
        if (json['social_media_links'] is String) {
          final decoded = jsonDecode(json['social_media_links']);
          socialLinks = Map<String, String>.from(decoded);
        } else if (json['social_media_links'] is Map) {
          socialLinks = Map<String, String>.from(json['social_media_links']);
        }
      } catch (e) {
        socialLinks = {};
      }
    }

    return ClientModel(
      clientId: json['client_id'] as int?,
      userId: json['user_id'] as int?,
      preferences: json['preferences'] as String?,
      clientAddress: json['client_address'] as String?,
      bio: json['bio'] as String?,
      socialMediaLinks: socialLinks,
      amount: (json['amount'] is int
              ? (json['amount'] as int).toDouble()
              : json['amount'] as double?) ??
          0.0,
      rating: (json['rating'] is int
              ? (json['rating'] as int).toDouble()
              : json['rating'] as double?) ??
          0.0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      user: json['user'] != null
          ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }

  // Create a copy with updated fields
  ClientModel copyWith({
    int? clientId,
    int? userId,
    String? preferences,
    String? clientAddress,
    String? bio,
    Map<String, String>? socialMediaLinks,
    double? amount,
    double? rating,
    DateTime? createdAt,
    DateTime? updatedAt,
    UserModel? user,
  }) {
    return ClientModel(
      clientId: clientId ?? this.clientId,
      userId: userId ?? this.userId,
      preferences: preferences ?? this.preferences,
      clientAddress: clientAddress ?? this.clientAddress,
      bio: bio ?? this.bio,
      socialMediaLinks: socialMediaLinks ?? this.socialMediaLinks,
      amount: amount ?? this.amount,
      rating: rating ?? this.rating,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      user: user ?? this.user,
    );
  }
}
