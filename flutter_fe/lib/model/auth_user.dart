import '../model/user_model.dart';
import '../model/client_model.dart';
import '../model/tasker_model.dart';

class AuthenticatedUser {
  final UserModel user;
  final ClientModel? client;
  final TaskerModel? tasker;

  AuthenticatedUser({
    required this.user,
    this.client,
    this.tasker,
  });

  @override
  String toString() {
    return "AuthenticatedUser(user: $user, client: $client, tasker: $tasker)";
  }
}
