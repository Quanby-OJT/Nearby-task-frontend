import '../model/user_model.dart';

class AuthenticatedUser {
  final UserModel user;
  final bool isClient;
  final bool isTasker;

  AuthenticatedUser({
    required this.user,
    this.isClient = false,
    this.isTasker = false,
  });

  @override
  String toString() {
    return "AuthenticatedUser(user: $user, isClient: $isClient, isTasker: $isTasker)";
  }
}
