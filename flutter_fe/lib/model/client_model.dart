import 'package:flutter_fe/model/user_model.dart';

class ClientModel {
  final String preferences;
  final String clientAddress;
  final double amount;
  final double rating;
  UserModel? user;

  ClientModel(
      {required this.preferences,
      required this.clientAddress,
      this.user,
      this.amount = 0,
      this.rating = 0});

  @override
  String toString() {
    return "ClientModel(user: $user, preferences: $preferences, clientAddress: $clientAddress, amount: $amount, rating: $rating)";
  }

  Map<String, dynamic> toJson() {
    return {
      "preferences": preferences,
      "client_address": clientAddress,
      "amount": amount,
      "rating": rating,
      "user": user?.toJson(),
    };
  }

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    return ClientModel(
      preferences: json['preferences'] as String? ?? '',
      clientAddress: json['client_address'] as String? ?? '',
      amount: (json['amount'] is int
              ? (json['amount'] as int).toDouble()
              : json['amount'] as double?) ??
          0.0,
      rating: (json['rating'] is int
              ? (json['rating'] as int).toDouble()
              : json['rating'] as double?) ??
          0.0,
      user: json['user'] != null
          ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }
}
