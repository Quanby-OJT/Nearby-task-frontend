import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_fe/controller/profile_controller.dart';
import 'package:flutter_fe/service/api_service.dart';
import 'package:flutter_fe/service/auth_service.dart';
import 'package:flutter_fe/view/business_acc/business_acc_main_page.dart';
import 'package:flutter_fe/view/service_acc/service_acc_main_page.dart';
import 'package:flutter_fe/view/sign_in/otp_screen.dart';
import 'package:flutter_fe/view/welcome_page/welcome_page_view_main.dart';
import 'package:get_storage/get_storage.dart';
import 'package:go_router/go_router.dart';

class AuthenticationController {
  static const String apiUrl = "http://localhost:5000/connect";
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController otpController = TextEditingController();

  ProfileController profileController = ProfileController();
  int userId;

  final storage = GetStorage();
  AuthenticationController({this.userId = 0});

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

    debugPrint("OTP Auth Response: ${response.toString()}");

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
          return ServiceAccMain();
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

// This is for direct redirection to logout/welcome page.
  void redirectRologout(BuildContext context) {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => WelcomePageViewMain()));
  }

  Future<void> logout(BuildContext context) async {
    try {
      final storedUserId = storage.read('user_id');
      if (storedUserId == null) {
        debugPrint("No user ID found in storage");
        // Even if no user ID, still navigate to welcome page
        await storage.erase();

        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return WelcomePageViewMain();
        }));

        return;
      }

      // Convert to String if needed
      final userIdString = storedUserId.toString();
      // debugPrint(userIdString);
      // debugPrint("Session: ${await AuthService.getSessionToken()}");
      // debugPrint("Stored user ID for logout: $userIdString");
      final sessionToken = await AuthService.getSessionToken();

      debugPrint("User ID for logout: $userIdString");
      debugPrint("Session token: $sessionToken");

      // Then attempt to logout on the server (don't wait for this to complete)
      try {
        final response =
            await ApiService.logout(int.parse(userIdString), sessionToken);
        debugPrint("Logout response: $response");

        if (response.containsKey("message")) {
          await storage.erase();
          Navigator.push(context, MaterialPageRoute(builder: (context) {
            return WelcomePageViewMain();
          }));
        }
      } catch (e) {
        debugPrint("Server logout error: $e");
        // Don't show this error to the user since they're already logged out locally
      }
    } catch (e, stackTrace) {
      debugPrint("Logout Error: $e");
      debugPrintStack(stackTrace: stackTrace);

      // Ensure user is still logged out locally even if there's an error
      if (e is Exception) {
        await storage.erase();
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return WelcomePageViewMain();
        }));
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                "An error occurred while logging out, but you have been logged out locally.")),
      );
    }
  }

  static Future<void> initialize() async {
    await GetStorage.init();
  }
}
