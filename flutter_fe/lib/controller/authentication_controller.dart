import 'package:flutter/material.dart';
import 'package:flutter_fe/controller/profile_controller.dart';
import 'package:flutter_fe/service/api_service.dart';
import 'package:flutter_fe/service/auth_service.dart';
import 'package:flutter_fe/view/business_acc/business_acc_main_page.dart';
import 'package:flutter_fe/view/service_acc/service_acc_main_page.dart';
import 'package:flutter_fe/view/sign_in/otp_screen.dart';
import 'package:flutter_fe/view/sign_in/sign_in.dart';
import 'package:get_storage/get_storage.dart';
import '../view/custom_loading/statusModal.dart';

class AuthenticationController {
  static const String apiUrl = "http://localhost:5000/connect";
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController otpController = TextEditingController();

  ProfileController profileController = ProfileController();
  int userId;

  final storage = GetStorage();
  AuthenticationController({this.userId = 0});

  void _showStatusModal({
    required BuildContext context,
    required bool isSuccess,
    required String message,
  }) {
    // Ensure the dialog is shown after the current frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => StatusModal(
          isSuccess: isSuccess,
          message: message,
          navigateToRoute: "otp",
        ),
      );
    });
  }

  Future<void> loginAuth(BuildContext context) async {
    var response = await ApiService.authUser(
        emailController.text, passwordController.text);

    if (response.containsKey('user_id')) {
      userId = response['user_id'];
      storage.write('temp_user_id', userId.toString());
      debugPrint("User ID stored at: ${storage.read('temp_user_id')}");

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpScreen(userId: userId),
        ),
      );
    } else if (response.containsKey('validation_error')) {
      String errorMessage =
          response['validation_error'] ?? "Unknown error occurred";
      _showStatusModal(
        context: context,
        isSuccess: false,
        message: errorMessage,
      );
    } else {
      String errorMessage = response['error'] ?? "Unknown error occurred";
      _showStatusModal(
        context: context,
        isSuccess: false,
        message: errorMessage,
      );
    }
  }

  Future<void> forgotPassword(BuildContext context) async {
    var response = await ApiService.forgotPassword(emailController.text);
    if (response.containsKey('message')) {
      String messageReset = response['message'];
      _showStatusModal(
        context: context,
        isSuccess: true,
        message: messageReset,
      );
    } else {
      String errorMessage = response['error'] ?? "Unknown error occurred";
      _showStatusModal(
        context: context,
        isSuccess: false,
        message: errorMessage,
      );
    }
  }

  Future<void> resetPassword(BuildContext context, String email) async {
    if (passwordController.text != confirmPasswordController.text) {
      _showStatusModal(
        context: context,
        isSuccess: false,
        message: "Passwords do not match",
      );
      return;
    }
    var response = await ApiService.resetPassword(
      email,
      passwordController.text,
    );
    if (response.containsKey('message')) {
      String messageReset = response['message'];
      _showStatusModal(
        context: context,
        isSuccess: true,
        message: messageReset,
      );
    } else {
      String errorMessage = response['error'] ?? "Unknown error occurred";
      _showStatusModal(
        context: context,
        isSuccess: false,
        message: errorMessage,
      );
    }
  }

  Future<int> verifyEmail(
      BuildContext context, String token, String email) async {
    try {
      final response = await ApiService.verifyEmail(token, email);

      if (response.containsKey("message")) {
        return response["user_id"] as int;
      } else {
        _showStatusModal(
            context: context,
            isSuccess: false,
            message:
                response["error"] ?? "Verification Failed. Please Try Again.");
        return 0;
      }
    } catch (e, st) {
      debugPrint("Error verifying email: $e");
      debugPrintStack(stackTrace: st);
      _showStatusModal(
          context: context,
          isSuccess: false,
          message: "Verification Failed. Please Try Again.");
      return 0;
    }
  }

  Future<void> resetOTP(BuildContext context) async {
    var response = await ApiService.regenerateOTP(userId);

    if (response.containsKey('message')) {
      String messageReset = response['message'];
      _showStatusModal(
        context: context,
        isSuccess: true,
        message: messageReset,
      );
    } else {
      String errorMessage = response['error'] ?? "Unknown error occurred";
      _showStatusModal(
        context: context,
        isSuccess: false,
        message: errorMessage,
      );
    }
  }

  Future<void> otpAuth(BuildContext context) async {
    var response = await ApiService.authOTP(userId, otpController.text);

    debugPrint("OTP Auth Response: ${response.toString()}");

    if (response.containsKey('user_id') &&
        response.containsKey('role') &&
        response.containsKey('session')) {
      await storage.remove('temp_user_id');
      await storage.write('user_id', response['user_id']);
      await storage.write('role', response['role']);
      await storage.write('session', response['session']);

      if (response['role'] == "Client") {
        userId = response['user_id'];
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => BusinessAccMain()),
          (route) => false,
        );
      } else if (response['role'] == "Tasker") {
        userId = response['user_id'];
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => ServiceAccMain()),
          (route) => false,
        );
      }
    } else if (response.containsKey('validation_error')) {
      String error =
          response['validation_error'] ?? "OTP Authentication Failed.";
      _showStatusModal(
        context: context,
        isSuccess: false,
        message: error,
      );
    } else {
      String error = response['error'] ?? "OTP Authentication Failed.";
      _showStatusModal(
        context: context,
        isSuccess: false,
        message: error,
      );
    }
  }

  void redirectRologout(BuildContext context) {
    Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (context) => SignIn()), (route) => false);
  }

  Future<void> logout(BuildContext context, bool Function() isMounted) async {
    try {
      final storedUserId = storage.read('user_id');
      if (storedUserId == null) {
        debugPrint("No user ID found in storage");
        await storage.erase();
        Navigator.pushAndRemoveUntil(context,
            MaterialPageRoute(builder: (context) {
          return SignIn();
        }), (route) => false);

        return;
      }

      final userIdString = storedUserId.toString();
      final sessionToken = await AuthService.getSessionToken();

      try {
        final response =
            await ApiService.logout(int.parse(userIdString), sessionToken);
        debugPrint("Logout response: $response");

        if (response.containsKey("message")) {
          await storage.erase();
          if (isMounted()) {
            Navigator.pushAndRemoveUntil(context,
                MaterialPageRoute(builder: (context) {
              return SignIn();
            }), (route) => false);
          }
        }
      } catch (e, stackTrace) {
        debugPrint("Server logout error: $e");
        debugPrintStack(stackTrace: stackTrace);
      }
    } catch (e, stackTrace) {
      debugPrint("Logout Error: $e");
      debugPrintStack(stackTrace: stackTrace);

      if (e is Exception) {
        await storage.erase();
        Navigator.pushAndRemoveUntil(context,
            MaterialPageRoute(builder: (context) {
          return SignIn();
        }), (route) => false);
      }

      _showStatusModal(
        context: context,
        isSuccess: false,
        message:
            "An error occurred while logging out, but you have been logged out locally.",
      );
    }
  }

  static Future<void> initialize() async {
    await GetStorage.init();
  }
}
