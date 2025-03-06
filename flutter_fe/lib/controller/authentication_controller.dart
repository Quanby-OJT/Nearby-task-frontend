import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_fe/service/api_service.dart';
import 'package:flutter_fe/view/business_acc/business_acc_main_page.dart';
import 'package:flutter_fe/view/fill_up/fill_up_tasker.dart';
import 'package:flutter_fe/view/sign_in/otp_screen.dart';
import 'package:flutter_fe/view/service_acc/service_acc_main_page.dart';
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

    if (response.containsKey('user_id')) {
      userId = response['user_id'];
      String? userRole = response['user_role'];

      // After successful OTP verification, store the permanent user ID
      await storage.write('user_id', userId.toString());
      // Remove temporary ID
      await storage.remove('temp_user_id');

      debugPrint(
          "User ID stored after OTP verification: ${storage.read('user_id')}");
      debugPrint("User Role: $userRole");

      // Navigate based on user role
      if (userRole == "Client") {
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return BusinessAccMain(); // Replace with your actual client page widget
        }));
      } else if (userRole == "Tasker") {
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return ServiceAccMain(); // Replace with your actual service account main page widget
        }));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Unknown user role: $userRole")),
        );
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
      await _handleLogoutNavigation(context);
      final storedUserId = storage.read('user_id');
      debugPrint("Stored user ID for logout: $storedUserId");

      if (storedUserId == null || storedUserId.isEmpty) {
        debugPrint("No user ID found in storage");
        await _handleLogoutNavigation(context);
        return;
      }

      try {
        final userIdInt = int.parse(storedUserId);
        if (userIdInt <= 0) {
          throw FormatException('Invalid user ID value');
        }

        final response = await ApiService.logout(userIdInt);
        debugPrint("Logout response: $response");

        if (response.containsKey('message')) {
          await _handleLogoutNavigation(context);
        } else {
          _showError(context, response['error'] ?? "Logout failed");
        }
      } catch (parseError) {
        debugPrint("Error parsing user ID: $parseError");
        await _handleLogoutNavigation(context);
      }
    } catch (e) {
      debugPrint("Logout error: $e");
      _showError(context, "An error occurred during logout");
    }
  }

  Future<void> _handleLogoutNavigation(BuildContext context) async {
    await storage.erase();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => WelcomePageViewMain()),
      (route) => false,
    );
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
