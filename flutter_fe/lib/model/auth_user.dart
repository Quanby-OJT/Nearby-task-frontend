import 'package:flutter_fe/model/tasker_model.dart';
import '../model/user_model.dart';
import 'client_model.dart';

class AuthenticatedUser {
  final UserModel user;
  final TaskerModel? tasker;
  final ClientModel? client;
  final bool isClient;
  final bool isTasker;
  final String? token;

  AuthenticatedUser({
    required this.user,
    this.isClient = false,
    this.isTasker = false,
    this.tasker,
    this.client,
    this.token,
  });

  factory AuthenticatedUser.fromJson(Map<String, dynamic> json) {
    return AuthenticatedUser(
      user: UserModel.fromJson(json['user']),
      token: json['token'],
      isClient: json['is_client'],
      isTasker: json['is_tasker'],
      tasker: json['tasker'],
      client: json['client'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'token': token,
      'is_client': isClient,
      'is_tasker': isTasker,
      'tasker': tasker?.toJson(),
      'client': client?.toJson(),
    };
  }

  @override
  String toString() {
    return "AuthenticatedUser(user: $user, isClient: $isClient, isTasker: $isTasker)";
  }
}

class User {
  final String id;
  final String firstName;
  final String middleName;
  final String lastName;
  final String email;
  final String role;
  final String? image;
  final String? phoneNumber;
  final String? address;
  final String? latitude;
  final String? longitude;
  final String? createdAt;
  final String? updatedAt;

  User({
    required this.id,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.email,
    required this.role,
    this.image,
    this.phoneNumber,
    this.address,
    this.latitude,
    this.longitude,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      firstName: json['first_name'],
      middleName: json['middle_name'],
      lastName: json['last_name'],
      email: json['email'],
      role: json['role'],
      image: json['image'],
      phoneNumber: json['phone_number'],
      address: json['address'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'middle_name': middleName,
      'last_name': lastName,
      'email': email,
      'role': role,
      'image': image,
      'phone_number': phoneNumber,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
