import 'package:flutter_fe/model/tasker_model.dart';
import '../model/user_model.dart';
import 'client_model.dart';

class AuthenticatedUser {
  final UserModel user;
  final TaskerModel? tasker;
  final ClientModel? client;
  final bool isClient;
  final bool isTasker;

  AuthenticatedUser({
    required this.user,
    this.isClient = false,
    this.isTasker = false,
    this.tasker,
    this.client,
  });

  @override
  String toString() {
    return "AuthenticatedUser(user: $user, isClient: $isClient, isTasker: $isTasker)";
  }
}
