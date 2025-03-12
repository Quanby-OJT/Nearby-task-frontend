import 'package:flutter_fe/model/user_model.dart';

class ClientModel{
  final String preferences;
  final String clientAddress;
  UserModel? user;

  ClientModel({
    required this.preferences,
    required this.clientAddress,
    this.user
  });

  @override
  String toString() {
    return "user: $user)";
  }

  Map<String, dynamic> toJson() {
    return{
      "preferences": preferences,
      "client_address": clientAddress
    };
  }

  factory ClientModel.fromJson(Map<String, dynamic> json){
    return ClientModel(
        preferences: json['preferences'] as String,
        clientAddress: json['client_address'] as String
    );
  }
}