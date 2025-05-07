import 'package:flutter_fe/model/user_model.dart';

class ClientModel {
  final int? id;
  final String preferences;
  final String clientAddress;
  final double amount;
  final double rating;
  UserModel? user;

  ClientModel({
    required this.id,
    required this.preferences,
    required this.clientAddress,
    this.user,
    this.amount = 0,
    this.rating = 0
  });

  @override
  String toString() {
    return "user: $user)";
  }

  Map<String, dynamic> toJson() {
    return {
      "client_id": id,
      "preferences": preferences,
      "client_address": clientAddress,
      "amount": amount,
      "rating": rating
    };
  }

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    return ClientModel(
      id: json['client_id'] as int?,
      preferences: json['preferences'] as String,
      clientAddress: json['client_address'] as String,
      amount: (json['amount'] is int
              ? (json['amount'] as int).toDouble()
              : json['amount'] as double?) ??
          0.0,
      // Handle int or double for rating
      rating: (json['rating'] is int
              ? (json['rating'] as int).toDouble()
              : json['rating'] as double?) ??
          0.0,
    );
  }
}
