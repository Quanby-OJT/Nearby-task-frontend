import 'package:flutter/material.dart';
import 'package:flutter_fe/service/api_service.dart';
import 'package:flutter_fe/service/auth_service.dart';
import 'package:flutter_fe/view/business_acc/business_acc_main_page.dart';
import 'package:flutter_fe/view/service_acc/service_acc_main_page.dart';
import 'package:flutter_fe/view/sign_in/otp_screen.dart';
import 'package:flutter_fe/view/welcome_page/welcome_page_view_main.dart';
import 'package:get_storage/get_storage.dart';

class AuthenticationController {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  int userId;

  final storage = GetStorage();
  AuthenticationController({this.userId = 0});

  Future<void> loginAuth(BuildContext context) async {
    var response = await ApiService.authUser(
        emailController.text, passwordController.text);

    if (response.containsKey('user_id')) {
      userId = response['user_id'];
      // Store user ID temporarily until OTP verification
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } else {
      // Display the error message using SnackBar
      String errorMessage = response['error'] ?? "Unknown error occurred";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  Future<void> resetOTP(BuildContext context) async {
    var response = await ApiService.regenerateOTP(userId);

    if (response.containsKey('message')) {
      String messageReset = response['message'];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(messageReset)),
      );
    } else {
      String errorMessage = response['error'] ?? "Unknown error occurred";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  Future<void> otpAuth(BuildContext context) async {
    var response = await ApiService.authOTP(userId, otpController.text);
    debugPrint(response.toString());

    if (response.containsKey('user_id') &&
        response.containsKey('role') &&
        response.containsKey('session')) {
      await storage.write('user_id', response['user_id']);
      await storage.write(
          'role',
          response[
              'role']); //If the user is logged in to the app, this will be the determinant if where they will be assigned.
      await storage.write('session', response['session']);
      if (response['role'] == "Client") {
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return BusinessAccMain();
        }));
      } else if (response['role'] == "Tasker") {
        userId = response['user_id'];
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          // return FillUpTasker(); // Replace with your actual service account main page widget
          return ServiceAccMain(); // Replace with your actual service account main page widget
        }));
      }
    } else if (response.containsKey('validation_error')) {
      String error =
          response['validation_error'] ?? "OTP Authentication Failed.";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    } else {
      String error = response['error'] ?? "OTP Authentication Failed.";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  Future<void> logout(BuildContext context) async {
    try {
      final storedUserId = storage.read('user_id');
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => WelcomePageViewMain()),
        (route) => false,
      );
      // Ensure storedUserId is a valid String or int
      if (storedUserId == null) {
        debugPrint("No user ID found in storage");
        return;
      }

      // Convert to String if needed
      final userIdString = storedUserId.toString();
      debugPrint(userIdString);
      debugPrint("Session: ${await AuthService.getSessionToken()}");
      debugPrint("Stored user ID for logout: $userIdString");

      final response = await ApiService.logout(
          int.parse(userIdString), await AuthService.getSessionToken());
      debugPrint("Logout response: $response");

      if (response.containsKey('message')) {
        await storage.erase();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => WelcomePageViewMain()),
          (route) => false,
        );
      } else {
        String error = response['error'] ?? "Failed to Log Out the User.";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    } catch (e, stackTrace) {
      debugPrint("Logout Error: $e");
      debugPrintStack(stackTrace: stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An Error Occurred While Logging Out.")),
      );
    }
  }

  static Future<void> initialize() async {
    await GetStorage.init();
  }
}
